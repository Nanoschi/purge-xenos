extends Label
class_name CellDebugLabel

var current_cell : Vector2i = Vector2i(0,0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "%s" % [current_cell]
