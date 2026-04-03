extends BaseCharacter
class_name Robot

const ROBOT_SCENE : PackedScene = preload("res://assets/Characters/Base/Enemies/Robot.tscn")

var max_action_count : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if action_count > 0 and not idling_bot:
		idling_bot = true
		await get_tree().create_timer(1.0).timeout
		execute_action(Vector2i(0, 0))
		idling_bot = false

## Creates an instance of a pre-configured Robot
static func create(base_map : BaseMap, max_action_count : int, current_cell : Vector2i) -> BaseCharacter:
	var robot =  ROBOT_SCENE.instantiate() as Robot
	robot.base_map = base_map
	robot.max_action_count = max_action_count
	robot.current_cell = current_cell
	var move_dict = CombatAction.create_move_action(5)
	#Use dict.merge() when multiple actions are required
	robot.combat_actions = move_dict
	return robot

func start_turn():
	action_count = max_action_count

func execute_action(target: Vector2i):
	action_count -= 1
	
	var idx : int = randi_range(0, combat_actions.size() - 1)
	
	# Magic AI which provide fully fleshed out actions
	selected_action = combat_actions[combat_actions.keys()[idx]]
	var player : BaseCharacter = $"../Player"
	selected_action.path = base_map.get_astar_path(current_cell, player.current_cell, true)
	
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
