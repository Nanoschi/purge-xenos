extends Node
class_name Pathfind

@export var map_floor: MapFloor
@export var map_walls: TileMapLayer
@export var map_interior: TileMapLayer

var astar_grid = AStarGrid2D.new()


func _ready() -> void:
	astar_grid.region.position = map_floor.get_used_rect().position
	astar_grid.region.size = map_floor.get_used_rect().size
	astar_grid.cell_size = map_floor.tile_set.tile_size * 2
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	load_wall()


func _process(_delta: float) -> void:
	pass

func remove_character(cell_pos: Vector2i):
	astar_grid.set_point_solid(cell_pos, false)


func add_character(cell_pos: Vector2i):
	astar_grid.set_point_solid(cell_pos, true)
	
func load_wall():
	var cell_positions = map_walls.get_used_cells()
	
	for cell_pos in cell_positions:
		var cell = map_walls.get_cell_tile_data(cell_pos)
		
		if bool(cell.get_custom_data("IsBlocked")):
			astar_grid.set_point_solid(cell_pos, true)
