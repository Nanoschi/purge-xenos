extends Node
class_name BattleDriver

@export var Players : Array[Player] = []
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
	# sets the current battle_driver (self) at the cursor manager
	SignalBus.main_init_finished.connect(func(): 
		SignalBus.battle_driver_initialized.emit(self))
	
	SignalBus.action_executed.connect(_on_action_executed)
	SignalBus.on_hud_player_end_turn.connect(on_hud_player_end_turn)
	
	match current_group_type:
		GroupTypes.PLAYERS: 
			current_group.assign(Players)
		GroupTypes.ENEMIES: 
			current_group.assign(Enemies)
		_: push_error("Unkown type")
	
	SignalBus.on_hud_is_ready.connect(on_hud_is_ready)
	SignalBus.on_all_characters_spawned.connect(on_all_characters_spawned)

func on_all_characters_spawned(players : Array[Player], enemies : Array[BaseCharacter]):
	Players.assign(players)
	Enemies.assign(enemies)
	
	current_character = Players[current_character_idx]
	current_group.assign(Players)
		
	SignalBus.battle_started.emit()
	SignalBus.on_character_begin_turn.emit(current_character)
	SignalBus.pre_begin_turn.emit()
	
	run_turn()


func on_hud_is_ready() -> void:
	pass
			
func next_turn():
	current_character_idx += 1
	
	var switch_group = current_character_idx == current_group.size()
	
	if switch_group:
		if current_group_type == GroupTypes.PLAYERS:
			current_group_type = GroupTypes.ENEMIES
			current_group.assign(Enemies)
		elif current_group_type == GroupTypes.ENEMIES:
			current_group_type = GroupTypes.PLAYERS
			current_group.assign(Players)
			SignalBus.pre_begin_turn.emit()
			
		current_character_idx = 0
	
	current_character = current_group[current_character_idx]
	if current_group_type == GroupTypes.PLAYERS:
		SignalBus.on_character_begin_turn.emit(current_character)

	run_turn()
	
func run_turn():
	if current_character == null:
		print("No current character")
		return
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

func _on_action_executed(character : BaseCharacter):
	if current_character == null:
		# In case that there is a "cut scene" like the movement after player spawn
		# there will be no current_character, because the action wasn't driven by the battle_driver
		return
		
	if character == current_character && current_character.action_count == 0:
		current_character = null
		next_turn()
		
		
func on_hud_player_end_turn(player : Player):
	if player == current_character:
		current_character = null
		next_turn()
