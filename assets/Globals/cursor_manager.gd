extends Node

@export var base_map: BaseMap
@export var battle_driver: BattleDriver

@onready var path_dots = $PathDots
@onready var attack_dots = $AttackDots
@onready var attack_lines = $AttackLines
@onready var movement_range_tiles = $MovementRangeTiles
@onready var action_target_icons = $ActionTargetIcons

var _is_cell_targeted = false
var _current_targeted_cell: Vector2i 

const PATH_HIGHLIGHT_SCENE = preload("res://assets/Maps/PathHighlight.tscn")
const TILE_HIGHLIGHT_SCENE = preload("res://assets/Maps/TileHighlight.tscn")
const MOVEMENT_RANGE_HIGHLIGHT_SCENE = preload("res://assets/Maps/MovementRangeHighlight.tscn")
const ATTACK_HIGHLIGHT_SCENE = preload("res://assets/Maps/AttackHighlight.tscn")

const DOT_COLOR_REACHABLE = Vector3(1, 1, 0)
const DOT_COLOR_UNREACHABLE = Vector3(1, 0, 0)


var dot_material_reachable = ShaderMaterial.new()
var dot_material_unreachable = ShaderMaterial.new()
# Key: Character. Value: Array of Node2D
var path_dots_dict : Dictionary[BaseCharacter, Array] = {}
# Key: Character. Value: Array of Node2D
var attack_dots_dict : Dictionary[BaseCharacter, Array] = {}
# Key: Character. Value: Array of Line2D
var attack_lines_dict : Dictionary[BaseCharacter, Line2D] = {}
var tile_highlight : Node

var _hovering_enemy: BaseCharacter = null
var _move_threat_tiles: Array = []
var _attack_threat_tiles: Array = []

var _threat_cells: Array[Vector2i] = []

var _action_target_icon_nodes: Array = []
var _previewed_action: CombatAction = null
var _selected_action_prev: CombatAction = null

# ── Ghost preview state ──────────────────────────────────────────────────────
## True while waiting for a second click to confirm a movement.
var _preview_mode: bool = false
var _preview_cell: Vector2i = Vector2i(-1, -1)
var _preview_character: BaseCharacter = null
## Semi-transparent clone of the player sprite shown at the target cell.
var _ghost_sprite: AnimatedSprite2D = null
var _ghost_container: Node2D = null
## Orange LoS lines drawn from each enemy that can see the preview position.
var _enemy_los_preview_lines: Array[Line2D] = []
var _enemy_los_container: Node2D = null
## Dimmer cursor-following path shown alongside the locked ghost path.
var _cursor_path_dots: Array = []

func _ready() -> void:
	tile_highlight = TILE_HIGHLIGHT_SCENE.instantiate();

	SignalBus.map_initialized.connect(func(map): base_map = map)
	SignalBus.battle_driver_initialized.connect(func(driver): battle_driver = driver)
	SignalBus.on_all_characters_spawned.connect(_on_all_characters_spawned)
	SignalBus.display_line_of_sight.connect(_on_display_line_of_sight)
	SignalBus.hide_line_of_sight.connect(_hide_line_of_sight)
	SignalBus.enemy_selected_action.connect(_on_enemy_selected_action)
	SignalBus.action_button_hovered.connect(_on_action_button_hovered)
	SignalBus.action_button_hover_ended.connect(_on_action_button_hover_ended)

	_ghost_container = Node2D.new()
	_ghost_container.z_index = 5
	add_child(_ghost_container)

	_enemy_los_container = Node2D.new()
	_enemy_los_container.z_index = 4
	add_child(_enemy_los_container)
	
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

	if battle_driver != null and battle_driver.current_character != null:
		var sel: CombatAction = battle_driver.current_character.selected_action
		if sel != _selected_action_prev:
			_selected_action_prev = sel
			if _preview_mode:
				_exit_preview_mode()
			if _previewed_action == null:
				if sel != null:
					_refresh_action_target_icons(battle_driver.current_character, sel)
				else:
					_clear_action_target_icons()
	else:
		if _selected_action_prev != null:
			_selected_action_prev = null
			_clear_action_target_icons()

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

				# In preview mode show a dimmer cursor-following path alongside
				# the locked ghost path; otherwise follow cursor normally.
				if not _preview_mode:
					display_path_dots(character, target_cell)
					display_attack_highlight(character, target_cell)
				else:
					if character.selected_action != null and character.selected_action.movement > 0 \
							and base_map.is_tile_walk_selectable(target_cell):
						_update_cursor_path_dots(character.get_preferred_path_to(target_cell), character.selected_action.movement)
					else:
						for dot in _cursor_path_dots:
							(dot as Node2D).visible = false

				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_RIGHT:
						if _preview_mode:
							_exit_preview_mode()
						return

				if event is InputEventMouseButton and event.pressed \
						and event.button_index == MOUSE_BUTTON_LEFT:
					var sel_action = character.selected_action
					# Two-click movement: first click → preview, second click on
					# the same cell → execute. Different cell → update preview.
					if sel_action != null and sel_action.movement > 0 \
							and base_map.is_tile_walk_selectable(target_cell):
						var path_to_target = character.get_preferred_path_to(target_cell)
						var in_range = path_to_target.size() > 0 \
								and path_to_target.size() - 1 <= sel_action.movement
						if in_range:
							if not _preview_mode:
								_enter_preview_mode(character, target_cell)
							elif target_cell == _preview_cell:
								_exit_preview_mode()
								character.execute_action(target_cell)
								if character.is_moving:
									_update_path_dots(character, [])
							else:
								_exit_preview_mode()
								_enter_preview_mode(character, target_cell)
					else:
						# Non-movement action: execute immediately as before.
						character.execute_action(target_cell)
						if character.is_moving:
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
			var dot = path_dots_dict[character][i - 1] as PathHighlight
			if i < path.size() - 1:
				dot.visible = true
				dot.position = MapHelpers.cell_to_pixel(path[i + 1])
				var diff = path[i + 1] - path[i]
				var dir: int
				if diff.x > 0: dir = 0
				elif diff.x < 0: dir = 1
				elif diff.y > 0: dir = 2
				else: dir = 3
				dot.set_direction(dir)
				if i < movement_points:
					dot.set_valid(true)
				else:
					dot.set_valid(false)	
			else:
				dot.visible = false

func _on_after_action_executed(character : BaseCharacter, _action : CombatAction):
		if character == battle_driver.current_character:
			_exit_preview_mode()
			for child in attack_dots_dict[character]:
				(child as Node2D).visible = false
			_selected_action_prev = null
			_clear_action_target_icons()

func _refresh_enemy_threat(enemy: BaseCharacter) -> void:
	_clear_enemy_threat()

	var move_action: CombatAction = null
	for action in enemy.combat_actions.values():
		if action.action_type == CombatAction.ActionType.MOVE:
			move_action = action
			break

	if move_action == null or move_action.cost <= 0:
		return

	_threat_cells = base_map.pathfind.get_reachable_cells(enemy.current_cell, move_action.movement)

	var cell_set: Dictionary = {}
	for cell in _threat_cells:
		cell_set[cell] = true

	for cell in _threat_cells:
		var tile = _get_or_create_move_threat_tile()
		tile.position = MapHelpers.cell_to_pixel(cell)
		tile.set_instance_shader_parameter("needs_top_border",    not cell_set.has(cell + Vector2i( 0, -1)))
		tile.set_instance_shader_parameter("needs_right_border",  not cell_set.has(cell + Vector2i( 1,  0)))
		tile.set_instance_shader_parameter("needs_bottom_border", not cell_set.has(cell + Vector2i( 0,  1)))
		tile.set_instance_shader_parameter("needs_left_border",   not cell_set.has(cell + Vector2i(-1,  0)))
		tile.visible = true

func _clear_move_threat_tiles() -> void:
	for tile in _move_threat_tiles:
		(tile as Node2D).visible = false

func _clear_enemy_threat() -> void:
	_threat_cells.clear()
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

func _on_action_button_hovered(action: CombatAction) -> void:
	_previewed_action = action
	if battle_driver == null or battle_driver.current_character == null:
		return
	_refresh_action_target_icons(battle_driver.current_character, action)

func _on_action_button_hover_ended() -> void:
	_previewed_action = null
	if battle_driver == null or battle_driver.current_character == null:
		_clear_action_target_icons()
		return
	var sel: CombatAction = battle_driver.current_character.selected_action
	if sel != null:
		_refresh_action_target_icons(battle_driver.current_character, sel)
	else:
		_clear_action_target_icons()

func _refresh_action_target_icons(character: BaseCharacter, action: CombatAction) -> void:
	_clear_action_target_icons()
	if action.icon == null:
		return

	# When previewing a move, evaluate reachability and LoS from the ghost cell.
	var from_cell: Vector2i = _preview_cell \
		if (_preview_mode and character == _preview_character) \
		else character.current_cell

	var target_cells: Array[Vector2i] = []

	if EnumHelpers.has_flag(action.valid_target_flags, CombatAction.ValidTargetFlags.OPPONENTS):
		var opponents = battle_driver.get_opponents(character)
		for opp in opponents:
			if not is_instance_valid(opp):
				continue
			if action.weapon_range > 0:
				var dist := maxi(abs(opp.current_cell.x - from_cell.x), abs(opp.current_cell.y - from_cell.y))
				if dist > action.weapon_range:
					continue
			if action.needs_line_of_sight:
				if base_map.get_line_of_sight(from_cell, opp.current_cell, true, true).size() == 0:
					continue
			target_cells.append(opp.current_cell)

	if EnumHelpers.has_flag(action.valid_target_flags, CombatAction.ValidTargetFlags.GROUP_MEMBERS):
		var own_group: Array
		if battle_driver.Enemies.has(character):
			own_group = battle_driver.Enemies
		else:
			own_group = battle_driver.Players
		for member in own_group:
			if not is_instance_valid(member) or member == character:
				continue
			if action.weapon_range > 0:
				var dist := maxi(abs(member.current_cell.x - from_cell.x), abs(member.current_cell.y - from_cell.y))
				if dist > action.weapon_range:
					continue
			if action.needs_line_of_sight:
				if base_map.get_line_of_sight(from_cell, member.current_cell, true, true).size() == 0:
					continue
			target_cells.append(member.current_cell)

	if EnumHelpers.has_flag(action.valid_target_flags, CombatAction.ValidTargetFlags.SELF):
		target_cells.append(from_cell)

	var icon_size := action.icon.get_size()
	var cell_size := Vector2(MapHelpers.cell_size)
	var icon_scale := cell_size / icon_size if icon_size.x > 0 and icon_size.y > 0 else Vector2.ONE

	for cell in target_cells:
		var sprite := _get_or_create_action_icon()
		sprite.texture = action.icon
		sprite.scale = icon_scale
		sprite.position = MapHelpers.cell_to_pixel(cell)
		sprite.visible = true

func _clear_action_target_icons() -> void:
	for node in _action_target_icon_nodes:
		(node as Node2D).visible = false

func _get_or_create_action_icon() -> Sprite2D:
	for node in _action_target_icon_nodes:
		var s := node as Sprite2D
		if not s.visible:
			return s
	var sprite := Sprite2D.new()
	sprite.z_index = 2
	sprite.visible = false
	action_target_icons.add_child(sprite)
	_action_target_icon_nodes.append(sprite)
	return sprite

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

# ── Ghost / movement-preview helpers ─────────────────────────────────────────

func _enter_preview_mode(character: BaseCharacter, cell: Vector2i) -> void:
	_preview_mode = true
	_preview_cell = cell
	_preview_character = character
	# Hide stale enemy-turn LoS lines so only the orange preview lines are shown.
	for line in attack_lines_dict.values():
		(line as Line2D).visible = false
	# Clear cursor dots and lock main path to the ghost destination.
	for dot in _cursor_path_dots:
		(dot as Node2D).visible = false
	if character.selected_action != null:
		_update_path_dots(character, character.get_preferred_path_to(cell), character.selected_action.movement)
	_show_ghost_at(cell, character)
	_update_enemy_los_preview(cell)
	if character.selected_action != null:
		_refresh_action_target_icons(character, character.selected_action)

func _exit_preview_mode() -> void:
	_preview_mode = false
	_preview_cell = Vector2i(-1, -1)
	_preview_character = null
	if _ghost_sprite != null:
		_ghost_sprite.visible = false
	_clear_enemy_los_preview()
	for dot in _cursor_path_dots:
		(dot as Node2D).visible = false

func _show_ghost_at(cell: Vector2i, character: BaseCharacter) -> void:
	if _ghost_sprite == null:
		_ghost_sprite = AnimatedSprite2D.new()
		_ghost_sprite.z_index = 5
		_ghost_container.add_child(_ghost_sprite)
	_ghost_sprite.sprite_frames = character.sprite.sprite_frames
	var suffix: String = BaseCharacter.DIRECTION_SUFFIXES.get(character.Direction, "_E")
	_ghost_sprite.play("idle_no_weapon" + suffix)
	_ghost_sprite.position = MapHelpers.cell_to_pixel(cell)
	_ghost_sprite.modulate = Color(0.6, 0.8, 1.0, 0.5)
	_ghost_sprite.visible = true

func _update_enemy_los_preview(ghost_cell: Vector2i) -> void:
	_clear_enemy_los_preview()
	if battle_driver == null:
		return
	for enemy in battle_driver.Enemies:
		if not is_instance_valid(enemy):
			continue
		var los = base_map.get_line_of_sight(enemy.current_cell, ghost_cell, true, false)
		if los.size() > 0:
			var line = _get_or_create_enemy_los_preview_line()
			line.clear_points()
			line.add_point(MapHelpers.cell_to_pixel(enemy.current_cell))
			line.add_point(MapHelpers.cell_to_pixel(ghost_cell))
			line.visible = true

func _clear_enemy_los_preview() -> void:
	for line in _enemy_los_preview_lines:
		(line as Line2D).visible = false

func _get_or_create_enemy_los_preview_line() -> Line2D:
	for line in _enemy_los_preview_lines:
		var l = line as Line2D
		if not l.visible:
			return l
	var line = Line2D.new()
	line.z_index = 4
	line.width = 1.0
	line.default_color = Color.RED
	line.visible = false
	_enemy_los_container.add_child(line)
	_enemy_los_preview_lines.append(line)
	return line

func _update_cursor_path_dots(path: Array[Vector2i], movement_points: int) -> void:
	if path.size() == 0:
		for dot in _cursor_path_dots:
			(dot as Node2D).visible = false
		return

	while _cursor_path_dots.size() < path.size() - 1:
		var dot = PATH_HIGHLIGHT_SCENE.instantiate() as Node2D
		dot.modulate.a = 0.4
		path_dots.add_child(dot)
		_cursor_path_dots.append(dot)

	for i in _cursor_path_dots.size():
		var dot = _cursor_path_dots[i - 1] as PathHighlight
		if i < path.size() - 1:
			dot.visible = true
			dot.position = MapHelpers.cell_to_pixel(path[i + 1])
			var diff = path[i + 1] - path[i]
			var dir: int
			if diff.x > 0: dir = 0
			elif diff.x < 0: dir = 1
			elif diff.y > 0: dir = 2
			else: dir = 3
			dot.set_direction(dir)
			if i < movement_points:
				dot.set_valid(true)
			else:
				dot.set_valid(false)
		else:
			dot.visible = false
