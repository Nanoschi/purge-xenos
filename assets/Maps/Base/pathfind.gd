extends Node
class_name Pathfind

@export var map_floor: MapFloor
@export var map_walls: TileMapLayer
@export var map_interior: TileMapLayer

var astar_grid = AStarGrid2D.new()


func _ready() -> void:
	astar_grid.region.position = map_floor.get_used_rect().position
	astar_grid.region.size = map_floor.get_used_rect().size
	astar_grid.cell_size = map_floor.tile_set.tile_size
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	load_tilemap_props(map_floor, true)
	load_tilemap_props(map_walls, false)
	load_tilemap_props(map_interior, false )


func _process(_delta: float) -> void:
	pass

func set_point_solid(pos: Vector2i, solid: bool) -> void:
	# if pos == Vector2i(7,7):
	# 	var x = 5
	# Log.debug("set_point_solid: %s -> solid=%s" % [pos, solid])
	astar_grid.set_point_solid(pos, solid)

func remove_character(cell_pos: Vector2i):
	set_point_solid(cell_pos, false)

func add_character(cell_pos: Vector2i):
	set_point_solid(cell_pos, true)
	
func load_tilemap_props(tilemapLayer : TileMapLayer, check_empty_cells : bool):
	var grid_size = tilemapLayer.get_used_rect().size
	var grid_pos = tilemapLayer.get_used_rect().position
	
	for i in grid_size.x + grid_pos.x:
		for j in grid_size.y + grid_pos.y:
			var astar_grid_pos = Vector2i(i,j)
			var cell = tilemapLayer.get_cell_tile_data(astar_grid_pos)
						
			if check_empty_cells && cell == null:
				set_point_solid(astar_grid_pos, true)
			
			if cell == null:
				continue
			
			if  bool(cell.get_custom_data("IsBlocked")):
				set_point_solid(astar_grid_pos, true)
