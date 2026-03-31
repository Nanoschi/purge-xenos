extends Marker2D
class_name BaseCharacter

signal action_finished

@export var map_interface: MapInterface
@export var current_cell : Vector2i = Vector2i(5,5):
	set(value):
		if current_cell == value:
			return
		if map_interface != null:
			map_interface.pathfind.remove_character(current_cell)
			map_interface.pathfind.add_character(value)
		current_cell = value
	get:
		return current_cell
		
@export var cursor_manager: CursorManager
@export var Direction : Directions.Points = Directions.Points.EAST
@export var combat_actions : Dictionary[CombatAction.ActionType, CombatAction]
@export var selected_action : CombatAction

var max_action_count = 3
var action_count: int = 0

@onready var sprite = $AnimatedSprite2D
## Use negative values for enemies
@export var PlayerIndex : int = 0

var idling_bot = false

var is_player : bool:
	get:
		return PlayerIndex > -1
	 
const DIRECTION_SUFFIXES: = {
	Directions.Points.NORTH: "_N",
	Directions.Points.EAST: "_E",
	Directions.Points.SOUTH: "_S",
	Directions.Points.WEST: "_W",
}
var is_moving = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if is_player:
		assert(is_instance_valid(cursor_manager), "CursorManager not set for Player: %d" % PlayerIndex)
				
	var current_pixel_pos = MapHelpers.cell_to_pixel(current_cell)
	self.position = current_pixel_pos
	map_interface.pathfind.add_character(current_cell)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		position = MapHelpers.cell_to_pixel(current_cell)
	play()
	
	if !is_player and action_count > 0 and not idling_bot:
		idling_bot = true
		await get_tree().create_timer(1.0).timeout
		execute_action(Vector2i(0, 0))
		idling_bot = false
				
func play() -> void: 
	var sequence_suffix: String = DIRECTION_SUFFIXES.get(Direction, "_E") 
	if is_moving:
		current_cell = MapHelpers.pixel_to_cell(position)
		sprite.play("walk_no_weapon" + sequence_suffix)
	else:
		sprite.play("idle_no_weapon" + sequence_suffix)
		
				
func get_preferred_path_to(target: Vector2i) -> Array[Vector2i]:
	map_interface.pathfind.remove_character(current_cell)
	var path = map_interface.pathfind.astar_grid.get_id_path(current_cell, target)
	map_interface.pathfind.add_character(current_cell)
	return path
	
func execute_action(target: Vector2i):
	action_count -= 1
	
	if not is_player:
		var idx : int = randi_range(0, combat_actions.size() - 1)
		
		# Magic AI which provide fully fleshed out actions
		selected_action = combat_actions[combat_actions.keys()[idx]]
		var player : BaseCharacter = $"../Player"
		selected_action.path = map_interface.get_astar_path(current_cell, player.current_cell, true)
		
		var executor = ActionExecutor.new([selected_action])
		executor.excecute(self)
		
		if EnumHelpers.has_flag(CombatAction.ValidTargetFlags.SELF, selected_action.valid_target_flags):
			print("Enemy has done: %s" % selected_action.display_name)
			action_finished.emit()
		elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.OPPONENTS, selected_action.valid_target_flags):
			print("Enemy has done: %s" % selected_action.display_name)
			action_finished.emit()
		elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.CELL, selected_action.valid_target_flags):
			action_finished.emit()
			print("Enemy has done: %s" % selected_action.display_name)
	else:	
		if selected_action.movement > 0:
			execute_move(target)
		if selected_action.damage > 0:
			execute_attack(target)

func execute_move(target: Vector2i):
	if is_moving:
		return
		
	var old_pos = current_cell
	map_interface.pathfind.remove_character(old_pos)
	var path = map_interface.pathfind.astar_grid.get_id_path(old_pos, target)

	if selected_action == null:
		return
	
	if path.size() - 1 > selected_action.movement:
		path = path.slice(0, selected_action.movement + 1)
		target = path[-1]
		
	map_interface.pathfind.add_character(target)
	
	is_moving = true
	
	if path.size() <= 1:
		is_moving = false
		return
	
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
	move_tween.tween_callback(func(): action_finished.emit())
	
	current_cell = target
	

func move(path : Array[Vector2i]):
	print("Move was called")
	if is_moving:
		return
	
	is_moving = true
	if path.size() <= 1:
		is_moving = false
		return
		
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
	move_tween.tween_callback(func(): action_finished.emit())
		
func execute_attack(target: Vector2i):
	print("Attacked %s" % target)
	action_finished.emit()

func calc_direction(from : Vector2i, to: Vector2i):
	Direction = Directions.vector_to_direction(to - from)
	
func start_turn():
	action_count = max_action_count
	print("Character (%d) turn started" % PlayerIndex)

	
func select_action(type: CombatAction.ActionType):
	selected_action = combat_actions.get(type)
