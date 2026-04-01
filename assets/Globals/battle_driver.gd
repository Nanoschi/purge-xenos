extends Node
class_name BattleDriver

@export var Players : Array[BaseCharacter] = []
@export var Enemies : Array[BaseCharacter] = []

enum GroupTypes {
	PLAYERS,
	ENEMIES
}

signal battle_won(who : GroupTypes)

var current_group_type : GroupTypes = GroupTypes.PLAYERS
var current_group : Array[BaseCharacter]
var current_character : BaseCharacter
var current_character_idx = 0
var is_battle_running = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match current_group_type:
		GroupTypes.PLAYERS: 
			current_group = Players
		GroupTypes.ENEMIES: 
			current_group = Enemies
		_: push_error("Unkown type")
	
	SignalBus.battle_started.connect(start_battle)
	
func start_battle() -> void:
	current_character = Players[current_character_idx]
	current_group = Players
	SignalBus.on_player_begin_turn.emit(current_character)
	run_turn()
			
func next_turn():
	current_character_idx += 1
	
	var switch_group = current_character_idx == current_group.size()
	
	if switch_group:
		if current_group_type == GroupTypes.PLAYERS:
			current_group_type = GroupTypes.ENEMIES
			current_group = Enemies
		elif current_group_type == GroupTypes.ENEMIES:
			current_group_type = GroupTypes.PLAYERS
			current_group = Players
		current_character_idx = 0
	
	current_character.action_finished.disconnect(_on_action_finished)
	current_character = current_group[current_character_idx]
	if current_group_type == GroupTypes.PLAYERS:
		SignalBus.on_player_begin_turn.emit(current_character)

	run_turn()
	
func run_turn():
	if current_character == null:
		print("No current character")
		return
	current_character.action_finished.connect(_on_action_finished)	
	current_character.start_turn()
		
func on_character_died(character : BaseCharacter) -> void :
	Enemies.erase(character)
	if Enemies.size() == 0:
		is_battle_running = false
		battle_won.emit(GroupTypes.PLAYERS)
	
	Players.erase(character)
	if Players.size() == 0:
		is_battle_running = false
		battle_won.emit(GroupTypes.ENEMIES)
		
func _on_action_finished():
	if current_character.action_count == 0:
		next_turn()
