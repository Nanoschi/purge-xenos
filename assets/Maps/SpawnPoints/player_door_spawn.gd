extends Marker2D
class_name PlayerDoorSpawn

## The delta the player moves when spawned (in cells).
@export var delta_move_on_entry : Vector2i = Vector2i(2,0)
@export var base_map : BaseMap
var player : BaseCharacter

@onready var door_sprite : AnimatedSprite2DDoor = $AnimatedSprite2DDoor
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var remote_transform : Node2D = $DummyNode

func spawn():
	# What if there are more than one player?
	player = Player.create(base_map, 0, 3, MapHelpers.pixel_to_cell(position))
	print(MapHelpers.pixel_to_cell(position))
	$DummyNode.add_child(player)	
	animation_player.play("OpenDoor")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "OpenDoor":
		player.current_cell = MapHelpers.pixel_to_cell(self.position + $DummyNode.position)
		SignalBus.on_player_spawned.emit(player)
		door_sprite.play_close_door()
