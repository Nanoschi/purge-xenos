extends Marker2D
class_name PlayerDoorSpawn

## The delta the player moves when spawned (in cells).
@export var delta_move_on_entry : Vector2i = Vector2i(2,0)
@export var base_map : BaseMap

@onready var door_sprite : AnimatedSprite2DDoor = $AnimatedSprite2DDoor
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var remote_transform : Node2D = $DummySpawnMarker

var player : BaseCharacter

func spawn(player_idx : int) -> Player:
	player = Player.create(base_map, player_idx, 3, MapHelpers.pixel_to_cell(position))
	#print(MapHelpers.pixel_to_cell(position))
	$DummySpawnMarker.add_child(player)	
	animation_player.play("OpenDoor")
	var anim_name = await animation_player.animation_finished
	
	player.current_cell = MapHelpers.pixel_to_cell(self.position + $DummySpawnMarker.position)
	door_sprite.play_close_door()
	return player
	
#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "OpenDoor":
		#player.current_cell = MapHelpers.pixel_to_cell(self.position + $DummySpawnMarker.position)
		#door_sprite.play_close_door()
		#on_spawn_finished.emit(player)
