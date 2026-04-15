class_name ActionExecutor
extends RefCounted

var _actions: Array[CombatAction]

func _init(actions: Array[CombatAction]):
	_actions = actions

func execute(owner: BaseCharacter) -> void:
	for action in _actions:
		var sliced_path = action.path.slice(1, action.movement + 1)
		if sliced_path.size() > 0:
			owner.execute_move(sliced_path[-1])
			await owner.move_finished
		if action.projectile_scene and action.targeted_cells.size() > 0:
			for cell in action.targeted_cells:
				var bullet = action.projectile_scene.instantiate()
				owner.get_parent().add_child(bullet)
				bullet.fire(owner.position, MapHelpers.cell_to_pixel(cell))
				await bullet.finished
		owner.execute_deal_damage(action.targeted_cells, action.damage)
	SignalBus.after_action_executed.emit(owner, owner.selected_action)


	
