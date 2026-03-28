extends Node
class_name CursorManager

@export var map_interface: MapInterface

@onready var tile_highlight = $TileHighlight

signal move_requested(target: Vector2i)

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
		if event.button_mask & MouseButton.MOUSE_BUTTON_LEFT:
			var mouse_pos = map_interface.map_floor.get_local_mouse_position()
			var cell = MapHelpers.pixel_to_cell(mouse_pos)
			
			if map_interface.is_tile_walk_selectable(cell):
				move_requested.emit(cell)
