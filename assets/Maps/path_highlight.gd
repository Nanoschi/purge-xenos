extends Sprite2D
class_name PathHighlight

@export var target_width = 24
@export var target_height = 24

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var texture_size = texture.get_size()
	var scale_x = target_width / texture_size.x
	var scale_y = target_height / texture_size.y
	self.scale = Vector2.ONE * min(scale_x, scale_y)

func set_valid(is_valid : bool):
	set_instance_shader_parameter("is_valid", is_valid)
	
## 0 = east, 1 = west, 2 = south, 3 = north 
func set_direction( dir : int):
	set_instance_shader_parameter("direction", dir)
