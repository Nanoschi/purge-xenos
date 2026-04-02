class_name HUD
extends CanvasLayer

var active_player : BaseCharacter

@onready var label_action_count = $VertAlign/MenuPanel/LabelActionCount

func _ready() -> void:
	SignalBus.on_character_begin_turn.connect(on_character_begin_turn)
	SignalBus.on_hud_is_ready.emit()
	
func _process(_delta: float) -> void:
	if active_player == null:
		return
	label_action_count.text = "Remaining Actions: %s" % active_player.action_count

func on_character_begin_turn(player : BaseCharacter) -> void:
	active_player = player

func _on_btn_walk_pressed() -> void:
	if active_player == null:
		return
	active_player.select_action(CombatAction.ActionType.MOVE)

func _on_btn_attack_pressed() -> void:
	if active_player == null:
		return
	active_player.select_action(CombatAction.ActionType.PEW_PEW)
