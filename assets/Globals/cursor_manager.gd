extends Node

@export var base_map: BaseMap
@export var battle_driver: BattleDriver

@onready var path_dots = $PathDots
@onready var attack_dots = $AttackDots
@onready var attack_lines = $AttackLines
@onready var movement_range_tiles = $MovementRangeTiles

var _is_cell_targeted = false
var _current_targeted_cell: Vector2i

const PATH_HIGHLIGHT_SCENE = preload("res://assets/Maps/PathHighlight.tscn")
const PATH_HIGHLIGHT_SHADER = preload("res://assets/Materials/path_highlight.gdshader")
const TILE_HIGHLIGHT_SCENE = preload("res://assets/Maps/TileHighlight.tscn")
const MOVEMENT_RANGE_HIGHLIGHT_SCENE = preload("res://assets/Maps/MovementRangeHighlight.tscn")
const ATTACK_HIGHLIGHT_SCENE = preload("res://assets/Maps/AttackHighlight.tscn")

const DOT_COLOR_REACHABLE = Vector3(1, 1, 0)
const DOT_COLOR_UNREACHABLE = Vector3(1, 0, 0)

# Threat overlay colors: tier 1 movement (orange), tier 2+ movement (red), attack range (purple)
#const THREAT_COLOR_TIER1 = Color(1.0, 0.45, 0.0, 1.0)
#const THREAT_COLOR_TIER2 = Color(0.85, 0.1, 0.1, 1.0)
#const THREAT_COLOR_ATTACK = Color(0.65, 0.0, 0.85, 1.0)

var dot_material_reachable = ShaderMaterial.new()
var dot_material_unreachable = ShaderMaterial.new()
# Key: Character. Value: Array of Node2D
var path_dots_dict : Dictionary[BaseCharacter, Array] = {}
# Key: Character. Value: Array of Node2D
var attack_dots_dict : Dictionary[BaseCharacter, Array] = {}
# Key: Character. Value: Array of Line2D
var attack_lines_dict : Dictionary[BaseCharacter, Line2D] = {}
var tile_highlight : Node


# var _mat_threat_tier1: ShaderMaterial
# var _mat_threat_tier2: ShaderMaterial
# var _mat_threat_attack: ShaderMaterial
var _hovering_enemy: BaseCharacter = null
var _move_threat_tiles: Array = []
var _attack_threat_tiles: Array = []
#var _threat_container: Node2D

# Sequential threat animation state
var _threat_tier_cells: Array = []  # Array of Array[Vector2i], one per tier
var _threat_current_tier: int = 0
var _threat_timer: Timer = null

func _ready() -> void:
	tile_highlight = TILE_HIGHLIGHT_SCENE.instantiate();
	_threat_timer = Timer.new()
	_threat_timer.wait_time = 2.0
	_threat_timer.one_shot = false
	_threat_timer.timeout.connect(_on_threat_timer_timeout)
	add_child(_threat_timer)

	SignalBus.map_initialized.connect(func(map): base_map = map)
	SignalBus.battle_driver_initialized.connect(func(driver): battle_driver = driver)
	SignalBus.on_all_characters_spawned.connect(_on_all_characters_spawned)
	SignalBus.display_line_of_sight.connect(_on_display_line_of_sight)
	SignalBus.hide_line_of_sight.connect(_hide_line_of_sight)
	SignalBus.enemy_selected_action.connect(_on_enemy_selected_action)
	
func _process(_delta: float) -> void:
	if base_map == null:
		return
		
	var mouse_pos = base_map.map_floor.get_local_mouse_position()
	var cell_pos = MapHelpers.pixel_to_cell(mouse_pos)
	
	if base_map.is_tile_walk_selectable(cell_pos):
		tile_highlight.visible = true
		tile_highlight.position = MapHelpers.cell_to_pixel(cell_pos)
	else:
		tile_highlight.visible = false

	var hovered_enemy: BaseCharacter = null
	if battle_driver != null:
		for enemy in battle_driver.Enemies:
			if enemy == null or not is_instance_valid(enemy):
				continue
			if enemy.current_cell == cell_pos:
				hovered_enemy = enemy
				break

	if hovered_enemy != _hovering_enemy:
		_hovering_enemy = hovered_enemy
		if hovered_enemy != null:
			_refresh_enemy_threat(hovered_enemy)
		else:
			_clear_enemy_threat()

func _on_all_characters_spawned(players : Array[Player], enemies : Array[BaseCharacter]):
	for x in players + enemies:
		path_dots_dict[x] = []
		attack_dots_dict[x] = []
		
	SignalBus.after_action_executed.connect(_on_after_action_executed)
	
	
func _unhandled_input(event: InputEvent) -> void:
	#assert(battle_driver != null)
	
	if battle_driver == null:
		return

	if battle_driver.current_character == null:
		return
	if battle_driver.current_character.selected_action == null:
		return
	
	_display_selected_action(event)
		
func _display_selected_action(event: InputEvent):
	if battle_driver.current_character.action_count > 0:
		if battle_driver.current_character is Player:
			var character = battle_driver.current_character
			if event is InputEventMouse:
				var mouse_pos = base_map.map_floor.get_local_mouse_position()
				var target_cell = MapHelpers.pixel_to_cell(mouse_pos)
				
				display_path_dots(character, target_cell)
				display_attack_highlight(character, target_cell)
				
				if event.button_mask & MouseButton.MOUSE_BUTTON_LEFT:
					battle_driver.current_character.execute_action(target_cell)
					if battle_driver.current_character.is_moving:
						_update_path_dots(character, [])

func _on_enemy_selected_action(enemy : BaseCharacter, action : CombatAction):
	Log.debug("Show action of enemy: %s" % str(action.display_name))
	_update_path_dots(enemy, action.path, action.movement)
	_hide_line_of_sight(enemy)
	if action.needs_line_of_sight:
		_on_display_line_of_sight(enemy, enemy.current_cell, action.targeted_cells[0])
	
func _hide_line_of_sight(enemy : BaseCharacter):
	if attack_lines_dict.has(enemy):
		attack_lines_dict[enemy].visible = false
	
func _on_display_line_of_sight(enemy : BaseCharacter, from : Vector2i, to: Vector2i):
	if attack_lines_dict.has(enemy):
		var line = attack_lines_dict[enemy] as Line2D
		line.clear_points()
		line.add_point(MapHelpers.cell_to_pixel(from))
		line.add_point(MapHelpers.cell_to_pixel(to))
	else:
		var line = Line2D.new()
		line.z_index = 1
		line.width = 1.0
		line.default_color = Color.RED
		line.add_point(MapHelpers.cell_to_pixel(from))
		line.add_point(MapHelpers.cell_to_pixel(to))
		attack_lines.add_child(line)
		attack_lines_dict[enemy] = line

	attack_lines_dict[enemy].visible = true
	
func display_path_dots(character : BaseCharacter, cell : Vector2i):
	if character.is_moving:
		return
		
	if character.selected_action.movement == 0:
		_update_path_dots(character, [])
		return	
	
	var movement_points = character.selected_action.movement
	if base_map.is_tile_walk_selectable(cell):
		if not character.is_moving:
			if not _is_cell_targeted:
				_is_cell_targeted = true
				_current_targeted_cell = cell		
				_update_path_dots(character, character.get_preferred_path_to(cell),movement_points)
			elif cell != _current_targeted_cell:
				_current_targeted_cell = cell
				_update_path_dots(character, character.get_preferred_path_to(cell),movement_points)
	else:
		_is_cell_targeted = false
		_update_path_dots(character, [])
	
func _update_path_dots(character : BaseCharacter, path: Array[Vector2i], movement_points : int = 0) -> void:
	if path.size() == 0:
		for child in path_dots_dict[character]:
			(child as Node2D).visible = false
	else:
		if path_dots_dict[character].size() < path.size() - 1:
			for i in path.size() - 1 -  path_dots_dict[character].size():
				var dot = PATH_HIGHLIGHT_SCENE.instantiate()
				path_dots_dict[character].append(dot)
				path_dots.add_child(dot)
				
		for i in path_dots_dict[character].size():
			var dot = path_dots_dict[character][i - 1] as Node2D
			if i < path.size() - 1:
				dot.visible = true
				dot.position = MapHelpers.cell_to_pixel(path[i + 1])
				var material = dot.material as ShaderMaterial
				if i < movement_points:
					dot.material = dot_material_reachable
				else:
					dot.material = dot_material_unreachable
			else:
				dot.visible = false

func _on_after_action_executed(character : BaseCharacter, action : CombatAction):
		if character == battle_driver.current_character:
			for child in attack_dots_dict[character]:
				(child as Node2D).visible = false

## Calculates movement tiers for [param enemy] and starts sequential display.
func _refresh_enemy_threat(enemy: BaseCharacter) -> void:
	_clear_enemy_threat()
	_threat_tier_cells.clear()

	var move_action: CombatAction = null
	for action in enemy.combat_actions.values():
		if action.action_type == CombatAction.ActionType.MOVE:
			move_action = action
			break

	if move_action == null or move_action.cost <= 0:
		return

	var max_uses = int(enemy.max_action_count / move_action.cost)
	var prev_tier_set: Dictionary = {}

	for tier in range(1, max_uses + 1):
		var tier_cells = base_map.pathfind.get_reachable_cells(enemy.current_cell, move_action.movement * tier)
		var exclusive: Array[Vector2i] = []
		for cell in tier_cells:
			if not prev_tier_set.has(cell):
				exclusive.append(cell)
		_threat_tier_cells.append(exclusive)
		prev_tier_set.clear()
		for cell in tier_cells:
			prev_tier_set[cell] = true

	if _threat_tier_cells.is_empty():
		return

	_threat_current_tier = 0
	_show_threat_tier(_threat_current_tier)
	_threat_timer.start()

func _on_threat_timer_timeout() -> void:
	_threat_current_tier = (_threat_current_tier + 1) % _threat_tier_cells.size()
	_clear_move_threat_tiles()
	_show_threat_tier(_threat_current_tier)

func _show_threat_tier(tier_index: int) -> void:
	for cell in _threat_tier_cells[tier_index]:
		var tile = _get_or_create_move_threat_tile()
		tile.position = MapHelpers.cell_to_pixel(cell)
		tile.visible = true

func _clear_move_threat_tiles() -> void:
	for tile in _move_threat_tiles:
		(tile as Node2D).visible = false

func _clear_enemy_threat() -> void:
	_threat_timer.stop()
	_threat_tier_cells.clear()
	for tile in _move_threat_tiles:
		(tile as Node2D).visible = false
	for tile in _attack_threat_tiles:
		(tile as Node2D).visible = false

func _get_or_create_move_threat_tile() -> Node2D:
	for tile in _move_threat_tiles:
		var n = tile as Node2D
		if not n.visible:
			return n
	var tile = MOVEMENT_RANGE_HIGHLIGHT_SCENE.instantiate() as Node2D
	tile.visible = false
	movement_range_tiles.add_child(tile)
	_move_threat_tiles.append(tile)
	return tile

# func _get_or_create_attack_threat_tile() -> Node2D:
# 	for tile in _attack_threat_tiles:
# 		var n = tile as Node2D
# 		if not n.visible:
# 			return n
# 	var tile = ATTACK_RANGE_HIGHLIGHT_SCENE.instantiate() as Node2D
# 	tile.material = _mat_threat_attack
# 	tile.visible = false
# 	movement_range_tiles.add_child(tile)
# 	_attack_threat_tiles.append(tile)
# 	return tile

func display_attack_highlight(character : BaseCharacter, target_cell : Vector2i):
	#if character.selected_action.damage == 0:
		#return
		
	var on_valid_target = false
	if EnumHelpers.has_flag(
		character.selected_action.valid_target_flags, 
		CombatAction.ValidTargetFlags.OPPONENTS):
			var opponents = battle_driver.get_opponents(character)
			for enemy in opponents:
				if enemy.current_cell == target_cell:
					on_valid_target = true

	if on_valid_target:
		var dot : Node2D
		if attack_dots_dict[character].size() == 0:
			dot = ATTACK_HIGHLIGHT_SCENE.instantiate()
			attack_dots_dict[character].append(dot)
			attack_dots.add_child(dot)
		if attack_dots_dict[character].size() > 0: #Todo: Check amount of needed dots for AOE attacks
			dot = attack_dots_dict[character][0] as Node2D	

		dot.position = MapHelpers.cell_to_pixel(target_cell)
		dot.visible = on_valid_target

	elif attack_dots_dict[character].size() > 0:
		for child in attack_dots_dict[character]:
			(child as Node2D).visible = false
