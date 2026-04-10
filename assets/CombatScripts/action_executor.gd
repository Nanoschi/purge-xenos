class_name ActionExecutor
extends Node

var _actions : Array[CombatAction]

func _init(actions : Array[CombatAction]):
	_actions = actions
	
func excecute(owner : BaseCharacter):
	for action in _actions:
		var sliced_path = action.path.slice(1, action.movement + 1)
		if sliced_path.size() > 0 :
			owner.execute_move(sliced_path[-1])
		owner.execute_deal_damage(action.targeted_cells, action.damage)
		#owner.heal(action.heal, action.healTarget)
		#owner.deal_damage(action.damage, action.DamageTarget)
		#etc...
	
	
