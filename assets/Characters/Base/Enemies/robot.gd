extends EnemyBase
class_name Robot

const ROBOT_SCENE: PackedScene = preload("res://assets/Characters/Base/Enemies/Robot.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if action_count > 0 and not idling_bot:
		#idling_bot = true
		#await get_tree().create_timer(1.0).timeout
		#execute_action(Vector2i(0, 0))
		#idling_bot = false

func _ready() -> void:
	super._ready()
	SignalBus.before_action_executed.connect(_on_before_action_executed)
	SignalBus.after_action_executed.connect(_on_after_action_executed)
	SignalBus.battle_started.connect(_on_battle_started)
	
	
func _on_before_action_executed(character: BaseCharacter, action: CombatAction):
	if not has_battle_started:
		return
	if character != self:
		selected_action = combat_actions[CombatAction.ActionType.WAIT]
		SignalBus.enemy_selected_action.emit(self , selected_action)
	
func _on_after_action_executed(character: BaseCharacter, action: CombatAction):
	if not has_battle_started:
		return
	if character != self:
		selected_action = ai_select_action()
		SignalBus.enemy_selected_action.emit(self , selected_action)

## Creates an instance of a pre-configured Robot
static func create(base_map: BaseMap, max_action_count: int, current_cell: Vector2i) -> BaseCharacter:
	var robot = ROBOT_SCENE.instantiate() as Robot
	robot.base_map = base_map
	#robot.max_action_count = max_action_count
	robot.current_cell = current_cell
	
	var actions: Dictionary[CombatAction.ActionType, CombatAction] = {}
	var move = CombatAction.create_move_action(5)
	var pewpew = CombatAction.create_pewpew_action()
	var wait = CombatAction.create_wait_action()
	actions.merge(move)
	actions.merge(pewpew)
	actions.merge(wait)
	
	robot.combat_actions = actions
	return robot

func ai_select_action() -> CombatAction:
	var action: CombatAction
	var player: BaseCharacter = $"../Player"
	
	var pewpews = combat_actions.values().filter(func(a: CombatAction): return a.action_type == CombatAction.ActionType.PEW_PEW)
	var pew_range: int = pewpews[0].weapon_range if pewpews.size() > 0 else 0
	
	var lines_of_sights = base_map.get_los_to_enemies(current_cell, player.get_groups()[0], pew_range)
	if lines_of_sights.size() > 0:
		var nearest_los = lines_of_sights.reduce(func(a, b): return a if Vector2(a[0], a[1]).length_squared() < Vector2(b[0], b[1]).length_squared() else b)
		if pewpews.size() > 0:
			action = pewpews[0]
			action.targeted_cells = [MapHelpers.pixel_to_cell(nearest_los[1])]
			
	if action == null:
		action = combat_actions[combat_actions.keys()[0]]
		action.targeted_cells = [player.current_cell] as Array[Vector2i]
	
	var path = base_map.get_astar_path(current_cell, player.current_cell, true)
	if path.size() > action.movement + 1:
		path = path.slice(0, action.movement + 1)
		
	action.path = path
	return action

func _on_pre_begin_turn():
	selected_action = ai_select_action()
	SignalBus.enemy_selected_action.emit(self , selected_action)
	
func start_turn():
	Log.debug("Turn started for '%s'" % [ self ])
	action_point_bar.set_max_points(max_action_count)
	action_count = max_action_count
	
	while action_count > 0:
		await get_tree().create_timer(1.0).timeout
		await execute_action(Vector2i(0, 0))

func execute_deal_damage(targeted_cells: Array[Vector2i], damage: int):
	super.execute_deal_damage(targeted_cells, damage)
	if damage > 0:
		Log.debug("Dealt damage to %s, amount: %d" % [str(targeted_cells), damage])
	
func execute_action(target: Vector2i):
	selected_action = ai_select_action()
	SignalBus.before_action_executed.emit(self, selected_action)
	SignalBus.enemy_selected_action.emit(self, selected_action)
	var executor = ActionExecutor.new([selected_action])
	await executor.execute(self)
