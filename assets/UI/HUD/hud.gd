class_name HUD
extends CanvasLayer

var active_player : BaseCharacter

func _ready() -> void:
	SignalBus.on_player_begin_turn.connect(_on_player_begin_turn)

func	 _on_player_begin_turn(player : BaseCharacter) -> void:
	active_player = player

func _on_btn_end_turn_pressed() -> void:
	SignalBus.on_hud_player_end_turn.emit(active_player)
