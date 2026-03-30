extends Marker2D
class_name BaseCharacter

@export var current_cell : Vector2i = Vector2i(5,5)
@export var map_interface: MapInterface
@export var cursor_manager: CursorManager
@export var Direction : Directions.Points = Directions.Points.EAST
@export var combat_actions : Array[CombatAction] = []
@export var selected_action : CombatAction

@onready var sprite = $AnimatedSprite2D
## Use negative values for enemies
@export var PlayerIndex : int = 0

signal turn_ended(character : BaseCharacter)
signal action_on_character_requested(source: BaseCharacter, action: CombatAction, target : BaseCharacter)
signal action_on_cell_requested(source: BaseCharacter, action: CombatAction, target : Vector2i)

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
		cursor_manager.move_requested.connect(_on_move_requested)
		#SignalBus.on_hud_player_end_turn.connect()
				
	var current_pixel_pos = MapHelpers.cell_to_pixel(current_cell)
	self.position = current_pixel_pos
	map_interface.pathfind.add_character(current_cell)
	

func play() -> void: 
	var sequence_suffix: String = DIRECTION_SUFFIXES.get(Direction, "_E") 
	if is_moving:
		sprite.play("walk_no_weapon" +  sequence_suffix)
	else:
		sprite.play("idle_no_weapon" +  sequence_suffix)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		position = MapHelpers.cell_to_pixel(current_cell)
	play()
	
func get_preferred_path_to(target: Vector2i) -> Array[Vector2i]:
	map_interface.pathfind.remove_character(current_cell)
	
	var path = map_interface.pathfind.astar_grid.get_id_path(current_cell, target)

	map_interface.pathfind.add_character(current_cell)
	return path
	
func _on_move_requested(target: Vector2i):
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
	
	current_cell = target

func calc_direction(from : Vector2i, to: Vector2i):
	Direction = Directions.vector_to_direction(to - from)
	
func start_turn():
	print("Character (%d) turn started" % PlayerIndex)
	if is_player:
		SignalBus.on_player_begin_turn.emit(self)
		while true:
			# notify the hud
				
			# do stuff
	
			#selected_action = combat_actions[0] # Move
			var player = await SignalBus.on_hud_player_end_turn
			print("awaited")
			if player == self:
				end_turn()
	else:
		# do AI stuff
		var wait_time = randf_range(1.0, 3.5)
		await get_tree().create_timer(wait_time).timeout
		
		var idx : int = randi_range(0, combat_actions.size() - 1)
		selected_action = combat_actions[idx]
		
		if EnumHelpers.has_flag(CombatAction.ValidTargetFlags.SELF, selected_action.valid_target_flags):
			excecute_action_on_character(selected_action, self)
		elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.OPPONENTS, selected_action.valid_target_flags):
			excecute_action_on_character(selected_action, $"../Player")
		elif EnumHelpers.has_flag(CombatAction.ValidTargetFlags.CELL, selected_action.valid_target_flags):
			var player_cell = $"../Player".current_cell		
			excecute_action_on_cell(selected_action, current_cell + player_cell)
			
		wait_time = 0.5
		await get_tree().create_timer(wait_time).timeout
		
		end_turn()	

func end_turn():
	turn_ended.emit(self)

func excecute_action_on_character(action: CombatAction, target : BaseCharacter):
	action_on_character_requested.emit(self, action, target)
	
func excecute_action_on_cell(action: CombatAction, target : Vector2i):
	action_on_cell_requested.emit(self, action, target)
	
	
