class_name HUD
extends CanvasLayer

@onready var label_action_count = $VertAlign/MenuPanel/LabelActionCount
@onready var container_action_buttons = $"VertAlign/MenuPanel/PanelContainer/ActionButtons"

var active_player : BaseCharacter
var action_button_theme : Resource

func _ready() -> void:
	SignalBus.on_character_begin_turn.connect(on_character_begin_turn)
	SignalBus.on_hud_is_ready.emit()
	SignalBus.action_executed.connect(_on_action_executed)
	action_button_theme = load("res://assets/UI/Themes/ActionButtonTheme.tres")
	
func _process(_delta: float) -> void:
	if active_player == null:
		return
	label_action_count.text = "Remaining Actions: %s" % active_player.action_count

func on_character_begin_turn(player : BaseCharacter) -> void:
	# The buttons will currently be recreated every turn.
	# Pros: Buttons are untoggled again
	# Cons: Performance?
	
	active_player = player
	for button in container_action_buttons.get_children():
		button.queue_free()
	
	var btn_group = ButtonGroup.new()
	for action_type in active_player.combat_actions:
		var action = active_player.combat_actions[action_type]
		var button = Button.new()
		button.button_group = btn_group # Put in group for toggle mutually exclusive
		button.theme = action_button_theme
		container_action_buttons.add_child(button)
		button.toggle_mode = true
		button.expand_icon = true	
		button.tooltip_text = action.description
		button.size = Vector2(64.0,64.0)
		button.custom_minimum_size = Vector2(64.0,64.0)
		button.icon = action.icon
		button.toggled.connect(_on_action_button_toggled.bind(action_type))
		
		
func _on_action_button_toggled(toggled: bool, type: CombatAction.ActionType) -> void:
	if active_player == null:
		return
	if toggled:
		active_player.select_action(type)
	else:
		active_player.deselect_action()
		
func _on_action_executed(character : BaseCharacter):
	if character != active_player:
		return
		
	for child in container_action_buttons.get_children():
		var btn = child as Button
		if btn != null:
			btn.button_pressed = false

func _on_btn_end_turn_pressed() -> void:
	if active_player == null:
		return
	SignalBus.on_hud_player_end_turn.emit(active_player)


func _on_btn_reset_camera_pressed() -> void:
	SignalBus.hud_camera_resetted.emit()
