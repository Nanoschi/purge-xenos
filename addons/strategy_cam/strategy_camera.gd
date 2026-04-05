extends Camera2D

# See WARNING's below for detail on custom control binding. Apart from scroll zooming, every key and mouse
# press must be bound manually by the developer.

@export var allow_mouse_controls: bool = true
@export var allow_keyboard_controls: bool = true

@export_group("Keyboard Controls")
## Camera zoom speed when controlled with keys
@export var key_zoom_speed: float = 2.0
## Translation speed when controlled by keys
@export var translation_speed: float = 500.0

@export_group("Camera Zoom Variables")
## Relative zoom in every scroll wheel tick.
@export var zoom_step: float = 0.2
## Speed at which the camera reaches the next target zoom. Really funky things can happen
## if x and y are set to different values...
@export var zoom_speed: Vector2 = Vector2(10, 10)

@export_group("Directional Limits")
## Top-left limit of the camera position/movement (applied to the top-left of the camera).
## If this and limit_BR set to Vector2.ZERO, no limits will be applied
@export var limit_TL: Vector2 = Vector2.ZERO
## Bottom-right limit of the camera position/movement (applied to the bottom-right of the camera).
## If this and limit_TL set to Vector2.ZERO, no limits will be applied
@export var limit_BR: Vector2 = Vector2.ZERO


@export_group("Margins")
## Add some extra space to the left. When camera jumps, it's probably because the position is out of limits
@export var margin_left : float = 400.0
## Add some extra space to the top. When camera jumps, it's probably because the position is out of limits
@export var margin_top : float = 200.0
## Add some extra space to the right. When camera jumps, it's probably because the position is out of limits
@export var margin_right : float = 400.0
## Add some extra space to the bottom. When camera jumps, it's probably because the position is out of limits
@export var margin_bottom : float = 200.0

var camera_TL: Vector2 = Vector2(-576, -324)
var camera_BR: Vector2 = Vector2(576, 324)
var target_zoom: Vector2 = Vector2.ONE
var original_zoom : Vector2
var is_resetting : bool

func _ready() -> void:
	# Custom code to reset cam
	
	original_zoom = zoom
	target_zoom = zoom
	## Custom added code to get a reasonable limits for the camera dependend on map size
	var base_map : BaseMap = NodeHelpers.find_parent_by_name(self, "BaseMap")
	var base_map_rect : Rect2 = base_map.get_used_rect()
	limit_TL = base_map.position - Vector2(margin_left, margin_top,)
	limit_BR = base_map.position + Vector2(base_map_rect.size) + Vector2(margin_right, margin_bottom)
	
	# HUD reset
	SignalBus.hud_camera_resetted.connect(_on_hud_camera_resetted)
	
	_on_resolution_change()
	get_viewport().size_changed.connect(_on_resolution_change)

func _on_hud_camera_resetted():
	is_resetting = true
	
	var tween = create_tween()
	tween.tween_property(self, "zoom", original_zoom, 0.2)
	tween.tween_property(self, "target_zoom", original_zoom, 0.2)
	tween.tween_property(self, "position", Vector2.ZERO, 0.2)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.2)
	
	tween.tween_callback(func(): is_resetting = false)
	
func _on_resolution_change() -> void:
	camera_TL = -get_viewport_rect().size / 2
	camera_BR = get_viewport_rect().size / 2

func _unhandled_input(event: InputEvent) -> void:
	if not allow_mouse_controls:
		return
	
	# Zooming by scrolling with the middle mouse button
	if event is InputEventMouse:
		if event.is_pressed() and not event.is_echo():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_camera(zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_camera(-zoom_step)
			# Original code:
			#target_zoom = target_zoom.clamp(Vector2.ONE*0.5, Vector2.INF)
			target_zoom = target_zoom.clamp(Vector2.ONE*1.5, Vector2.ONE*4.0)
			
	
	# Camera translation by clicking and dragging
	if event is InputEventMouseMotion:
		# WARNING: The dragging control must be defined WITHIN THIS PROJECT
		if Input.is_action_pressed("cam_drag"):
			position -= event.relative / zoom

func _process(delta: float) -> void:
	
	if is_resetting:
		return
		
	if target_zoom.length()-0.001 <= zoom.length() and zoom.length() <= target_zoom.length()+0.001:
		zoom = target_zoom
	else:
		increment_zoom((target_zoom-zoom) * zoom_speed * delta)
	
	var screen_centre: Vector2 = get_screen_center_position()
	var actual_TL: Vector2 = screen_centre + camera_TL / target_zoom
	var actual_BR: Vector2 = screen_centre + camera_BR / target_zoom
	
	# WARNING: The keyboard controls must be defined WITHIN THIS PROJECT
	if allow_keyboard_controls:
		position.x += Input.get_axis("cam_left", "cam_right") * translation_speed * delta
		position.y += Input.get_axis("cam_up", "cam_down") * translation_speed * delta
		var camera_zoom_direction: float = Input.get_axis("cam_zoom_out", "cam_zoom_in")
		
		if camera_zoom_direction:
			zoom_camera(camera_zoom_direction * key_zoom_speed * delta)
			zoom = target_zoom
	
	if limit_BR == Vector2.ZERO and limit_TL == Vector2.ZERO:
		return
	
	# Camera limit application
	if actual_TL.x < limit_TL.x:
		position.x += limit_TL.x - actual_TL.x
	if actual_TL.y < limit_TL.y:
		position.y += limit_TL.y - actual_TL.y
	
	if actual_BR.x > limit_BR.x:
		position.x -= actual_BR.x - limit_BR.x
	if actual_BR.y > limit_BR.y:
		position.y -= actual_BR.y - limit_BR.y

func zoom_camera(zoom_amount: float) -> void:
	target_zoom *= pow(10.0, zoom_amount)

func increment_zoom(zoom_direction: Vector2) -> void:
	
	var previous_mouse_position: Vector2 = get_local_mouse_position()
	zoom += zoom_direction

	var diff: Vector2 = previous_mouse_position - get_local_mouse_position()
	offset += diff
		
