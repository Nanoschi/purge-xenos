extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure rand() functions return the same results everytime we start the game.
	seed(123)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
