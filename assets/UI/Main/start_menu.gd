extends Control
class_name StartMenu

signal new_game
signal show_settings
signal quit_game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_new_game_pressed() -> void:
	new_game.emit()

func _on_btn_settings_pressed() -> void:
	show_settings.emit()

func _on_btn_quit_pressed() -> void:
	quit_game.emit()
