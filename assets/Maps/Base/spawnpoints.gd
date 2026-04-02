extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.on_hud_is_ready.connect(on_hud_is_ready)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_hud_is_ready():
	
	var players : Array[Player] = []
	var enemies : Array[BaseCharacter] = []
	
	# spawn enemies first
	for child in get_children():
		var spawn_point = child as EnemySpawnPoint
		if spawn_point != null:
			enemies.append(spawn_point.spawn())
	
	# player last
	var player_idx = 0
	for child in get_children():
		var spawn_point = child as PlayerDoorSpawn
		if spawn_point != null:
			var player = await spawn_point.spawn(player_idx)
			players.append(player)

	SignalBus.on_all_characters_spawned.emit(players, enemies)
