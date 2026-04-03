extends Marker2D
class_name PlayerDoorSpawn

## The delta the player moves when spawned (in cells).
@export var delta_move_on_entry : Vector2i = Vector2i(2,0)
@export var base_map : BaseMap

@onready var door_sprite : AnimatedSprite2DDoor = $AnimatedSprite2DDoor
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var player : BaseCharacter

func spawn(player_idx : int) -> Player:
	var move_action = CombatAction.create_move_action(5)
	#Todo .merge() Dictionaries if needed here
	
	player = Player.create(base_map, player_idx, 3, MapHelpers.pixel_to_cell(position), move_action)
	self.add_child(player)	
	player.current_cell = MapHelpers.pixel_to_cell(self.position)
	animation_player.play("OpenDoor")
	var anim_name = await animation_player.animation_finished
	
	door_sprite.play_close_door()
	return player
	
func move_player():
	player.move_delta(delta_move_on_entry)
