extends Node
class_name Pathfind

@export var floor: MapFloor
@export var walls: TileMapLayer
@export var interior: TileMapLayer

var astar_grid = AStarGrid2D.new()


func _ready() -> void:
	astar_grid.region.position = floor.get_used_rect().position
	astar_grid.region.size = floor.get_used_rect().size / 2
	astar_grid.cell_size = floor.tile_set.tile_size * 2
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	load_wall()


func _process(delta: float) -> void:
	pass

func remove_character(cell_pos: Vector2i):
	astar_grid.set_point_solid(cell_pos, false)


func add_character(cell_pos: Vector2i):
	astar_grid.set_point_solid(cell_pos, true)
	
func load_wall():
	var cell_positions = walls.get_used_cells()
	
	for cell_pos in cell_positions:
		var cell = walls.get_cell_tile_data(cell_pos)
		if bool(cell.get_custom_data("IsBlocked")):
			astar_grid.set_point_solid(cell_pos, true)
