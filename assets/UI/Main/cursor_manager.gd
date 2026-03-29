extends Node
class_name CursorManager

@export var map_interface: MapInterface
@export var player: BaseCharacter

@onready var tile_highlight = $TileHighlight
@onready var path_dots = $PathDots

var _is_cell_targeted = false
var _current_targeted_cell: Vector2i

const PATH_HIGHLIGHT_SCENE = preload("res://assets/Maps/PathHighlight.tscn")
const PATH_HIGHLIGHT_SHADER = preload("res://assets/Materials/path_highlight.gdshader")

const DOT_COLOR_REACHABLE = Vector3(1, 1, 0)
const DOT_COLOR_UNREACHABLE = Vector3(1, 0, 0)

var dot_material_reachable = ShaderMaterial.new()
var dot_material_unreachable = ShaderMaterial.new()

signal move_requested(target: Vector2i)

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
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var mouse_pos = map_interface.map_floor.get_local_mouse_position()
		var cell = MapHelpers.pixel_to_cell(mouse_pos)
		
		if map_interface.is_tile_walk_selectable(cell):
			if not player.is_moving:
				if not _is_cell_targeted:
					_is_cell_targeted = true
					_current_targeted_cell = cell
					_update_path_dots(player.get_preferred_path_to(cell))
				elif cell != _current_targeted_cell:
					_current_targeted_cell = cell
					_update_path_dots(player.get_preferred_path_to(cell))
				
			if event.button_mask & MouseButton.MOUSE_BUTTON_LEFT:
				move_requested.emit(cell)
				
				if player.is_moving:
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
				if i < player.actions:
					dot.material = dot_material_reachable
				else:
					dot.material = dot_material_unreachable
			else:
				dot.visible = false
