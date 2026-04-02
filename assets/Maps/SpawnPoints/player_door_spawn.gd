extends Marker2D

## The delta the player moves when spawned (in cells).
@export var delta_move_on_entry : Vector2i = Vector2i(2,0)
@export var base_map : BaseMap
var player : BaseCharacter
var battle_started : bool = false

@onready var door_sprite : AnimatedSprite2DDoor = $AnimatedSprite2DDoor
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var remote_transform : RemoteTransform2D = $RemoteTransform2D

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
	
	player = Player.create(base_map, 0, 3, MapHelpers.pixel_to_cell(position))
	print(MapHelpers.pixel_to_cell(position))
	$RemoteTransform2D.add_child(player)	
	animation_player.play("OpenDoor")
	
	
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group(Constants.PLAYER_GROUP):
		pass # Todo: Add Player area into PLAYER_GROUP for this to work.
	print("Area has been exited")	
	door_sprite.play_close_door()	
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "OpenDoor":
		print("$RemoteTransform2D: %s" % str($RemoteTransform2D.position))
		print("$player: %s" % str(player.position))
		player.current_cell = MapHelpers.pixel_to_cell(self.position + $RemoteTransform2D.position)
		SignalBus.on_player_spawned.emit(player, player.current_cell)
		
