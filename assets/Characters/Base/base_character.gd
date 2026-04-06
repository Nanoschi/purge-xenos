extends Marker2D
class_name BaseCharacter

#signal action_finished


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

var base_map: BaseMap		
var Direction : Directions.Points = Directions.Points.EAST
var combat_actions : Dictionary[CombatAction.ActionType, CombatAction]
var selected_action : CombatAction
var action_count: int = 0
var idling_bot = false
var is_moving = false

@onready var sprite = $AnimatedSprite2D

const DIRECTION_SUFFIXES: = {
	Directions.Points.NORTH: "_N",
	Directions.Points.EAST: "_E",
	Directions.Points.SOUTH: "_S",
	Directions.Points.WEST: "_W",
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
					
	var current_pixel_pos = MapHelpers.cell_to_pixel(current_cell)
	self.position = current_pixel_pos
	base_map.pathfind.add_character(current_cell)

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

func execute_deal_damage(targeted_cells : Array[Vector2i], damage : int):
	if damage == 0:
		return
	print("Dealt damage to %s, amount: %d" % [str(targeted_cells), damage ])

func execute_move(target: Vector2i):
	if is_moving:
		return
		
	var old_pos = current_cell
	base_map.pathfind.remove_character(old_pos)
	var path = base_map.pathfind.astar_grid.get_id_path(old_pos, target)

	if selected_action == null:
		return
	
	if path.size() - 1 > selected_action.movement:
		path = path.slice(0, selected_action.movement + 1)
		target = path[-1]
		
	base_map.pathfind.add_character(target)
	
	is_moving = true
	
	if path.size() <= 1:
		is_moving = false
		return
	
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
	move_tween.tween_callback(func(): SignalBus.action_executed.emit(self))
	move_tween.tween_callback(func(): current_cell = path[-1])

func update_current_cell():
	current_cell = MapHelpers.cell_to_pixel(position)
	
func move(path : Array[Vector2i]):
	print("Move was called")
	if is_moving:
		return

	is_moving = true
	if path.size() <= 1:
		is_moving = false
		return
			
	tween_movement(path)
	
func execute_attack(target: Vector2i):
	print("Attacked %s" % target)
	#action_finished.emit()
	SignalBus.action_executed.emit(self)


func calc_direction(from : Vector2i, to: Vector2i):
	Direction = Directions.vector_to_direction(to - from)
	

func select_action(type: CombatAction.ActionType):
	selected_action = combat_actions.get(type)

func deselect_action():
	selected_action = null
