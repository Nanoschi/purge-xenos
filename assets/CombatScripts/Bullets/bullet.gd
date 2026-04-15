extends Sprite2D

signal finished

@export var target_width = 32
@export var target_height = 32
@export var speed: float = 500.0

func _ready() -> void:
	var texture_size = texture.get_size()
	var scale_x = target_width / texture_size.x
	var scale_y = target_height / texture_size.y
	self.scale = Vector2.ONE * min(scale_x, scale_y)

func fire(from: Vector2, to: Vector2) -> void:
	position = from
	rotation = (to - from).angle()
	var duration = from.distance_to(to) / speed
	var tween = create_tween()
	tween.tween_property(self, "position", to, duration)
	tween.tween_callback(func():
		finished.emit()
		queue_free()
	)
