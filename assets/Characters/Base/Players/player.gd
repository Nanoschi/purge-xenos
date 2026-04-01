extends BaseCharacter
class_name Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func execute_action(target: Vector2i):
	action_count -= 1

	if selected_action.movement > 0:
		execute_move(target)
	if selected_action.damage > 0:
		execute_attack(target)
