extends Node

@export var base_map: BaseMap
@export var battle_driver: BattleDriver

@onready var tile_highlight = $TileHighlight
@onready var path_dots = $PathDots
@onready var attack_dots = $AttackDots

var _is_cell_targeted = false
var _current_targeted_cell: Vector2i

const PATH_HIGHLIGHT_SCENE = preload("res://assets/Maps/PathHighlight.tscn")
const PATH_HIGHLIGHT_SHADER = preload("res://assets/Materials/path_highlight.gdshader")

const ATTACK_HIGHLIGHT_SCENE = preload("res://assets/Maps/AttackHighlight.tscn")

const DOT_COLOR_REACHABLE = Vector3(1, 1, 0)
const DOT_COLOR_UNREACHABLE = Vector3(1, 0, 0)

var dot_material_reachable = ShaderMaterial.new()
var dot_material_unreachable = ShaderMaterial.new()
# Key: Character. Value: Array of Node2D
var path_dots_dict : Dictionary[BaseCharacter, Array] = {}
# Key: Character. Value: Array of Node2D
var attack_dots_dict : Dictionary[BaseCharacter, Array] = {}

func _ready() -> void:
	dot_material_reachable.shader = PATH_HIGHLIGHT_SHADER
	dot_material_reachable.set_shader_parameter("color", DOT_COLOR_REACHABLE)
	dot_material_unreachable.shader = PATH_HIGHLIGHT_SHADER
	dot_material_unreachable.set_shader_parameter("color", DOT_COLOR_UNREACHABLE)
	
	SignalBus.map_initialized.connect(func(map): base_map = map)
	SignalBus.battle_driver_initialized.connect(func(driver): battle_driver = driver)
	SignalBus.enemy_selected_action.connect(_on_enemy_selected_action)
	SignalBus.on_all_characters_spawned.connect(_on_all_characters_spawned)
	SignalBus.action_executed.connect(_on_action_executed)

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

func _on_all_characters_spawned(players : Array[Player], enemies : Array[BaseCharacter]):
	for x in players + enemies:
		path_dots_dict[x] = []
		attack_dots_dict[x] = []
	
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
	print("Show action of enemy: %s" % str(action.display_name))
	#display_enemy_path_dots(action.path)
	_update_path_dots(enemy, action.path, action.movement)
	display_attack_highlight(enemy, action.targeted_cells[0])
	

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

func _on_action_executed(character : BaseCharacter):
		if character == battle_driver.current_character:
			for child in attack_dots_dict[character]:
				(child as Node2D).visible = false
			
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
