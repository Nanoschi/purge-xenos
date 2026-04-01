extends Control
class_name StartMenu

const GAME_SCENE = preload("res://assets/UI/HUD/HUD.tscn")

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
	get_tree().change_scene_to_packed(GAME_SCENE)
	new_game.emit()

func _on_btn_settings_pressed() -> void:
	show_settings.emit()

func _on_btn_quit_pressed() -> void:
	# allows handling of quit event
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
	quit_game.emit()
