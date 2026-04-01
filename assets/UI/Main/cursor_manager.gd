extends Node
class_name CursorManager

@export var map_interface: MapInterface
@export var battle_driver: BattleDriver

@onready var tile_highlight = $TileHighlight
@onready var path_dots = $PathDots
@onready var attack_highlight = $AttackHighlight

var _is_cell_targeted = false
var _current_targeted_cell: Vector2i

const PATH_HIGHLIGHT_SCENE = preload("res://assets/Maps/PathHighlight.tscn")
const PATH_HIGHLIGHT_SHADER = preload("res://assets/Materials/path_highlight.gdshader")

const DOT_COLOR_REACHABLE = Vector3(1, 1, 0)
const DOT_COLOR_UNREACHABLE = Vector3(1, 0, 0)

var dot_material_reachable = ShaderMaterial.new()
var dot_material_unreachable = ShaderMaterial.new()

func _ready() -> void:
	dot_material_reachable.shader = PATH_HIGHLIGHT_SHADER
	dot_material_reachable.set_shader_parameter("color", DOT_COLOR_REACHABLE)
	dot_material_unreachable.shader = PATH_HIGHLIGHT_SHADER
	dot_material_unreachable.set_shader_parameter("color", DOT_COLOR_UNREACHABLE)
	

func _process(_delta: float) -> void:
	var mouse_pos = map_interface.map_floor.get_local_mouse_position()
	var cell_pos = MapHelpers.pixel_to_cell(mouse_pos)
	
	if map_interface.is_tile_walk_selectable(cell_pos):
		tile_highlight.visible = true
		tile_highlight.position = MapHelpers.cell_to_pixel(cell_pos)
	else:
		tile_highlight.visible = false
		
func _unhandled_input(event: InputEvent) -> void:
	if battle_driver.current_character == null:
		return
	if battle_driver.current_character.selected_action == null:
		return
	
	_display_selected_action(event)
			
func _display_selected_action(event: InputEvent):
	if battle_driver.current_character.action_count > 0:
		display_path_dots(event)
		display_attack_highlight(event)

func display_path_dots(event: InputEvent):
	if battle_driver.current_character.is_moving:
		return
		
	if battle_driver.current_character.selected_action.movement == 0:
		_update_path_dots([])	
	elif event is InputEventMouse:
		var mouse_pos = map_interface.map_floor.get_local_mouse_position()
		var cell = MapHelpers.pixel_to_cell(mouse_pos)
		if map_interface.is_tile_walk_selectable(cell):
			if not battle_driver.current_character.is_moving:
				if not _is_cell_targeted:
					_is_cell_targeted = true
					_current_targeted_cell = cell
					_update_path_dots(battle_driver.current_character.get_preferred_path_to(cell))
				elif cell != _current_targeted_cell:
					_current_targeted_cell = cell
					_update_path_dots(battle_driver.current_character.get_preferred_path_to(cell))
				
			if event.button_mask & MouseButton.MOUSE_BUTTON_LEFT:
				battle_driver.current_character.execute_action(cell)
				
				if battle_driver.current_character.is_moving:
					_update_path_dots([])
		else:
			_is_cell_targeted = false
			_update_path_dots([])
	
func _update_path_dots(path: Array[Vector2i]) -> void:
	if path.size() == 0:
		for child in path_dots.get_children():
			(child as Node2D).visible = false
	else:
		if path_dots.get_child_count() < path.size() - 1:
			for i in path.size() - 1 -  path_dots.get_child_count():
				var dot = PATH_HIGHLIGHT_SCENE.instantiate()
				path_dots.add_child(dot)
				
		for i in path_dots.get_child_count():
			var dot = path_dots.get_child(i - 1) as Node2D
			if i < path.size() - 1:
				dot.visible = true
				dot.position = MapHelpers.cell_to_pixel(path[i + 1])
				var material = dot.material as ShaderMaterial
				if i < battle_driver.current_character.selected_action.movement:
					dot.material = dot_material_reachable
				else:
					dot.material = dot_material_unreachable
			else:
				dot.visible = false
				
func display_attack_highlight(event: InputEvent):
	if battle_driver.current_character.selected_action.damage == 0:
		return
		
	var mouse_pos = map_interface.map_floor.get_local_mouse_position()
	var target_cell = MapHelpers.pixel_to_cell(mouse_pos)
	
	var on_valid_targ = false
	if EnumHelpers.has_flag(
		battle_driver.current_character.selected_action.valid_target_flags, 
		CombatAction.ValidTargetFlags.OPPONENTS):
			if battle_driver.current_character.is_player:
				for enemy in battle_driver.Enemies:
					if enemy.current_cell == target_cell:
						on_valid_targ = true
						
	if event.button_mask & MouseButton.MOUSE_BUTTON_LEFT and on_valid_targ:
		battle_driver.current_character.execute_action(target_cell)
						
	attack_highlight.position = MapHelpers.cell_to_pixel(target_cell)
	attack_highlight.visible = on_valid_targ
