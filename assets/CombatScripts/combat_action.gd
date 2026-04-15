class_name CombatAction
extends Resource



@export var projectile_scene: PackedScene  # assign Bullet.tscn here in the .tres inspector
@export var display_name : String
@export var description : String

@export var damage : int = 0
@export var heal : int = 0
@export var movement : int = 0
@export var path : Array[Vector2i] = []
@export var targeted_cells : Array[Vector2i] = []
@export var cost : int = 0
@export var icon : Texture2D
## if true, the action can be discarded in turn stage. AoE effects should be locked.
@export var action_is_locked : bool
@export var needs_line_of_sight : bool
@export var weapon_range : int
@export var cool_down : int

@export_flags("SELF:1", "GROUP_MEMBERS:2", "OPPONENTS:4", "CELL:8") var valid_target_flags: int = 0

var action_type : ActionType
const MOVE_ACTION_STR : String = "res://assets/CombatScripts/move.tres"
const PEWPEW_ACTION_STR : String = "res://assets/CombatScripts/pew_pew.tres"
const WAIT_ACTION_STR : String = "res://assets/CombatScripts/wait_action.tres"

enum ActionType{
	NONE,
	HEAL,
	MEGA_PEW_PEW,
	MOVE,
	PEW_PEW,
	WAIT
}

enum ValidTargetFlags {
	NONE = 0,
	SELF = 1 << 0,
	GROUP_MEMBERS = 1 << 1,
	OPPONENTS = 1 << 2,
	CELL = 1 << 3,
}

static func create_move_action(movement : int) -> Dictionary[ActionType, CombatAction]:
	var move = load(MOVE_ACTION_STR).duplicate() as CombatAction
	move.action_type = ActionType.MOVE
	move.movement = movement
	return  {ActionType.MOVE : move}
	
static func create_pewpew_action() -> Dictionary[ActionType, CombatAction]:
	var pewpew = load(PEWPEW_ACTION_STR).duplicate() as CombatAction
	pewpew.action_type = ActionType.PEW_PEW
	return  {ActionType.PEW_PEW : pewpew}
	
static func create_wait_action() -> Dictionary[ActionType, CombatAction]:
	var wait = load(WAIT_ACTION_STR).duplicate() as CombatAction
	wait.action_type = ActionType.WAIT
	return  {ActionType.WAIT : wait}
