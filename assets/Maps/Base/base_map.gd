extends Node2D
class_name BaseMap

@export 
var pathfind: Pathfind

@onready var map_floor: MapFloor = $Floor
@onready var map_walls: Node2D = $Walls
@onready var map_interior: Node2D = $Interior

func _ready():
	# sets the current map (self) at the global cursor manager
	CursorManager.base_map = self
	SignalBus.on_player_spawned.connect(on_player_spawned)
	SignalBus.on_enemy_spawned.connect(on_enemy_spawned)
	
func is_tile_walk_selectable(pos: Vector2i) -> bool:
	return pathfind.astar_grid.region.has_point(pos) and not pathfind.astar_grid.is_point_solid(pos)

## Unblocks the from field temporarily
func get_astar_path(from : Vector2i, to : Vector2i, partial_path : bool = false) -> Array[Vector2i]:
	pathfind.astar_grid.set_point_solid(from, false)
	var path = pathfind.astar_grid.get_id_path(from, to, partial_path)
	pathfind.astar_grid.set_point_solid(from, true)
	return path

func on_player_spawned(player : Player):
	add_child(player)
	player.reparent(self, true)
	player.set_owner(self)
	#print(player.current_cell)
	
func on_enemy_spawned(enemy : BaseCharacter):
	add_child(enemy)
	enemy.reparent(self, true)
	#print(enemy.current_cell)
