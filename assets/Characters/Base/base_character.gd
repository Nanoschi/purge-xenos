extends Marker2D
class_name BaseCharacter

@onready var action_point_bar = $ActionPointsBar as ActionPointsBar
@onready var health_point_bar = $HealthPointsBar as HealthPointsBar
@onready var sprite = $AnimatedSprite2D

@export var current_cell : Vector2i:
	set(value):
		if current_cell == value:
			return
		if base_map != null:
			base_map.pathfind.remove_character(current_cell)
			base_map.pathfind.add_character(value)
		current_cell = value
	get:
		return current_cell

@export var show_action_bar : bool = true
@export var show_health_bar : bool = true

var max_health: int = 10
var max_action_count: int = 3
var health: int = max_health
var base_map: BaseMap
var Direction : Directions.Points = Directions.Points.EAST
var combat_actions : Dictionary[CombatAction.ActionType, CombatAction]
var is_dead : bool = false

var selected_action : CombatAction:
	set(value):		
		if selected_action == value:
			return
		selected_action = value
	get:
		return selected_action


var action_count: int:
	set(value):
		if value < 0:
			Log.err("action count < 0 for '%s'" % [self])
		value = max(0, value)
		if value == action_count:
			return
		action_count = value
		if action_point_bar != null:
			action_point_bar.set_points(action_count)
		Log.debug("Action count of '%s' is: %d" % [self, action_count])
	get:
		return action_count

var is_moving : bool= false
var has_battle_started : bool = false

signal move_finished

const DIRECTION_SUFFIXES: = {
	Directions.Points.NORTH: "_N",
	Directions.Points.EAST: "_E",
	Directions.Points.SOUTH: "_S",
	Directions.Points.WEST: "_W",
}

func _ready() -> void:
	health = max_health
	if not show_action_bar:
		action_point_bar.visible = false
	if not show_health_bar:
		health_point_bar.visible = false
	health_point_bar.set_max_points(max_health)
	health_point_bar.set_points(health)
	action_point_bar.set_max_points(max_action_count)
	action_point_bar.set_points(action_count)

func _on_battle_started():
		Log.debug("Battle started, character %s can start acting" % str(self))
		has_battle_started = true
		
func _process(_delta: float) -> void:
	pass
				
func get_preferred_path_to(target: Vector2i) -> Array[Vector2i]:
	base_map.pathfind.remove_character(current_cell)
	var path = base_map.pathfind.astar_grid.get_id_path(current_cell, target)
	base_map.pathfind.add_character(current_cell)
	return path

func start_turn():
	pass

func execute_action(target: Vector2i):
	pass
	
func move_delta(delta_cells : Vector2i):
	var target = Vector2i(current_cell + delta_cells)
	var path = base_map.get_astar_path(current_cell, target)
	move(path)	

func take_damage(amount: int) -> void:
	health -= amount
	health = max(0, health)
	health_point_bar.set_points(health)
	Log.debug("'%s' took %d damage, health is now %d/%d" % [self, amount, health, max_health])
	if health <= 0:
		is_dead = true
		Log.debug("'%s' has been defeated!" % [self])
		SignalBus.hide_line_of_sight.emit(self)
		SignalBus.character_died.emit(self)
		queue_free()

func execute_deal_damage(targeted_cells : Array[Vector2i], damage : int):
	if damage == 0:
		return
	action_count -= selected_action.cost
	for cell in targeted_cells:
		for child in base_map.get_children():
			var character := child as BaseCharacter
			if character != null and character != self and character.current_cell == cell:
				character.take_damage(damage)

func execute_move(target: Vector2i):
	if is_moving:
		return
		
	var old_pos = current_cell
	base_map.pathfind.remove_character(old_pos)
	var path = base_map.pathfind.astar_grid.get_id_path(old_pos, target)

	if selected_action == null:
		move_finished.emit()
		return
	
	if path.size() - 1 > selected_action.movement:
		path = path.slice(0, selected_action.movement + 1)
		target = path[-1]
		
	base_map.pathfind.add_character(target)
	
	is_moving = true
	
	if path.size() <= 1:
		is_moving = false
		move_finished.emit()
		return
	
	action_count -= selected_action.cost
	
	tween_movement(path)

func tween_movement(path : Array[Vector2i]):

	calc_direction(path[0], path[1])
	var move_tween: Tween = create_tween()
	
	move_tween.step_finished.connect(func(idx : int):
		if idx >= path.size():
			return
		if idx < path.size() - 2:
			calc_direction(path[idx + 1], path[idx + 2])	
		else:
			calc_direction(path[idx - 1], path[idx])	
		)
			
	for step_index in range(1, path.size()):
		var step = Vector2i(path[step_index])
		var pixel_step = MapHelpers.cell_to_pixel(step)	
		move_tween.tween_property(self, "position", pixel_step, 0.2)
	
	move_tween.tween_callback(func(): is_moving = false)
	move_tween.tween_callback(func(): current_cell = path[-1])
	move_tween.tween_callback(func(): move_finished.emit())

func update_current_cell():
	current_cell = MapHelpers.cell_to_pixel(position)
	
func move(path : Array[Vector2i]):
	Log.debug("Move was called")
	if is_moving:
		return

	is_moving = true
	if path.size() <= 1:
		is_moving = false
		return
			
	tween_movement(path)
	
func execute_attack(target: Vector2i):
	pass

func calc_direction(from : Vector2i, to: Vector2i):
	Direction = Directions.vector_to_direction(to - from)
	

func select_action(type: CombatAction.ActionType):
	selected_action = combat_actions.get(type)

func deselect_action():
	selected_action = null
