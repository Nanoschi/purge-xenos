extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_hud_is_ready.connect(on_hud_is_ready)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_hud_is_ready():
	for child in get_children():
		# spawn enemies first
		var spawn_point = child as EnemySpawnPoint
		if spawn_point != null:
			spawn_point.spawn()
			
	for child in get_children():
		var spawn_point = child as PlayerDoorSpawn
		if spawn_point != null:
			spawn_point.spawn()
