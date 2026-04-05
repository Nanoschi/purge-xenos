extends Node2D
class_name BaseMap

@export 
var pathfind: Pathfind

@onready var map_floor: MapFloor = $Floor
@onready var map_walls: Node2D = $Walls
@onready var map_interior: Node2D = $Interior

func _ready():
	# sets the current map (self) at the cursor manager
	SignalBus.main_init_finished.connect(func(): 
		SignalBus.map_initialized.emit(self))

func is_tile_walk_selectable(pos: Vector2i) -> bool:
	return pathfind.astar_grid.region.has_point(pos) and not pathfind.astar_grid.is_point_solid(pos)

## Unblocks the from field temporarily
func get_astar_path(from : Vector2i, to : Vector2i, partial_path : bool = false) -> Array[Vector2i]:
	pathfind.astar_grid.set_point_solid(from, false)
	var path = pathfind.astar_grid.get_id_path(from, to, partial_path)
	pathfind.astar_grid.set_point_solid(from, true)
	return path

## Returns the rect of the floor in pixel world coordinates.
func get_used_rect() -> Rect2:
	var used_rect : Rect2i = map_floor.get_used_rect()
	# Get the top-left position in world coordinates
	var world_position = map_floor.map_to_local(used_rect.position)
	# Get the size in world coordinates (pixels)
	var world_size = map_floor.map_to_local(used_rect.size)
	
	return Rect2(world_position, world_size)
	
	
	
	
