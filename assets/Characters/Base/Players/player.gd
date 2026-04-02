extends BaseCharacter
class_name Player

const PLAYER_SCENE : PackedScene = preload("res://assets/Characters/Base/Players/Player.tscn")

var player_index : int
var max_action_count

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var sequence_suffix: String = DIRECTION_SUFFIXES.get(Direction, "_E") 
	if is_moving:
		current_cell = MapHelpers.pixel_to_cell(position)
		sprite.play("walk_no_weapon" + sequence_suffix)
	else:
		sprite.play("idle_no_weapon" + sequence_suffix)

## Creates an instance of a pre-configured Player
static func create(base_map : BaseMap, player_index : int, max_action_count : int, current_cell : Vector2i ) -> BaseCharacter:
	var player =  PLAYER_SCENE.instantiate() as Player
	player.base_map = base_map
	player.player_index = player_index
	player.max_action_count = max_action_count
	player.current_cell = current_cell
	return player

func start_turn():
	action_count = max_action_count
	print("Character (%d) turn started" % player_index)

func execute_action(target: Vector2i):
	action_count -= 1

	if selected_action.movement > 0:
		execute_move(target)
	if selected_action.damage > 0:
		execute_attack(target)
