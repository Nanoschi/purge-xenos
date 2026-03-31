class_name ActionExecutor
extends Node

var _actions : Array[CombatAction]

func _init(actions : Array[CombatAction]):
	_actions = actions
	
func excecute(owner : BaseCharacter):
	for action in _actions:
		owner.execute_move(action.path.slice(1, action.movement)[-1])
		#owner.heal(action.heal, action.healTarget)
		#owner.deal_damage(action.damage, action.DamageTarget)
		#etc...
	
	
