class_name HUD
extends CanvasLayer

var active_player : BaseCharacter

@onready var label_action_count = $VertAlign/MenuPanel/LabelActionCount
@onready var container_action_buttons = $"VertAlign/MenuPanel/ActionButtons"

func _ready() -> void:
	SignalBus.on_character_begin_turn.connect(on_character_begin_turn)
	SignalBus.on_hud_is_ready.emit()
	
func _process(_delta: float) -> void:
	if active_player == null:
		return
	label_action_count.text = "Remaining Actions: %s" % active_player.action_count

func on_character_begin_turn(player : BaseCharacter) -> void:
	active_player = player
	for button in container_action_buttons.get_children():
		button.queue_free()
		
	for action_type in active_player.combat_actions:
		var action = active_player.combat_actions[action_type]
		var button = Button.new()
		container_action_buttons.add_child(button)
		button.text = action.display_name
		button.pressed.connect(_on_action_button_walk_pressed.bind(action_type))
		
		
func _on_action_button_walk_pressed(type: CombatAction.ActionType) -> void:
	if active_player == null:
		return
	active_player.select_action(type)


func _on_btn_end_turn_pressed() -> void:
	if active_player == null:
		return
	SignalBus.on_hud_player_end_turn.emit(active_player)
	
#func _input(event: InputEvent) -> void:
	#print("YAYAYAYAAY")
