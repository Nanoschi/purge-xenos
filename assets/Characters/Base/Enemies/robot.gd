extends BaseCharacter
class_name Robot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func execute_action(target: Vector2i):
	action_count -= 1
	
	var idx : int = randi_range(0, combat_actions.size() - 1)
	
	# Magic AI which provide fully fleshed out actions
	selected_action = combat_actions[combat_actions.keys()[idx]]
	var player : BaseCharacter = $"../Player"
	selected_action.path = map_interface.get_astar_path(current_cell, player.current_cell, true)
	
	var executor = ActionExecutor.new([selected_action])
	executor.excecute(self)
	
	if EnumHelpers.has_flag(CombatAction.ValidTargetFlags.SELF, selected_action.valid_target_flags):
		print("Enemy has done: %s" % selected_action.display_name)
		action_finished.emit()
	elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.OPPONENTS, selected_action.valid_target_flags):
		print("Enemy has done: %s" % selected_action.display_name)
		action_finished.emit()
	elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.CELL, selected_action.valid_target_flags):
		action_finished.emit()
		print("Enemy has done: %s" % selected_action.display_name)
