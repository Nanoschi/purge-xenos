extends Marker2D

## The delta the player moves when spawned.
@export var delta_move_on_entry : Vector2i = Vector2i(64,0)

var player_scene : PackedScene = preload("res://assets/Characters/Base/BaseCharacter.tscn")
var player : BaseCharacter
var battle_started : bool = false

@onready var door_sprite : AnimatedSprite2DDoor = $AnimatedSprite2DDoor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.battle_started.connect(on_battle_started)	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_battle_started():
	if battle_started:
		return
	battle_started = true
	
	door_sprite.play_open_door()
	
	player = player_scene.instantiate()
	add_child(player)	
	
	player.move_delta_pixels(delta_move_on_entry)
	
	
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group(Constants.PLAYER_GROUP):
		pass # Todo: Add Player area into PLAYER_GROUP for this to work.
	print("Area has been exited")	
	door_sprite.play_close_door()	
	
	
