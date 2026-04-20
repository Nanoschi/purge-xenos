extends Sprite2D

#@export var needs_top_border : bool
#@export var needs_right_border : bool
#@export var needs_bottom_border : bool
#@export var needs_left_border : bool
#@export var color : Color = Color(0.812, 0.812, 0.812, 1.0)
#@export var border_color : Color = Color(1,1,1,1)
#@export var pulse_speed : float = 2.0
#@export var is_pulsing : bool
#@export var opacity : float = 0.4
#@export var border_texture : Texture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#var m = material.duplicate() as Material
	#m.set_shader_parameter("overlay_texture", texture)
	#m.set_shader_parameter("border_texture", border_texture)
	#m.set_shader_parameter("color", color)
	#m.set_shader_parameter("border_color", border_color)
	#m.set_shader_parameter("pulse_speed", pulse_speed)
	#m.set_shader_parameter("opacity", opacity)
	#m.set_shader_parameter("needs_top_border", needs_top_border)
	#m.set_shader_parameter("needs_right_border", needs_right_border)
	#m.set_shader_parameter("needs_bottom_border", needs_bottom_border)
	#m.set_shader_parameter("needs_left_border", needs_left_border)
	#material = m
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
