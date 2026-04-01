class_name HUD
extends CanvasLayer

var active_player : BaseCharacter

@onready var label_action_count = $VertAlign/MenuPanel/LabelActionCount

func _ready() -> void:
	SignalBus.on_player_begin_turn.connect(_on_player_begin_turn)
	SignalBus.battle_started.emit()
	#_on_btn_walk_pressed() # default selected action
	
func _process(_delta: float) -> void:
	if active_player == null:
		return
	label_action_count.text = "Remaining Actions: %s" % active_player.action_count

func _on_player_begin_turn(player : BaseCharacter) -> void:
	active_player = player

func _on_btn_walk_pressed() -> void:
	active_player.select_action(CombatAction.ActionType.MOVE)


func _on_btn_attack_pressed() -> void:
	active_player.select_action(CombatAction.ActionType.PEW_PEW)
