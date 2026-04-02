extends Marker2D
class_name EnemySpawnPoint

@export var base_map : BaseMap

var robot : Robot

func spawn():
	robot = Robot.create(base_map,3, MapHelpers.pixel_to_cell(position))
	add_child(robot)
	SignalBus.on_enemy_spawned.emit(robot)
