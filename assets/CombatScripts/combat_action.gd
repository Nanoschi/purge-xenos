class_name CombatAction
extends Resource

@export var display_name : String
@export var description : String

@export var damage : int = 0
@export var heal : int = 0
@export var movement : int = 0
@export var path : Array[Vector2i] = []
@export var cost : int = 0

enum ActionType{
	NONE,
	HEAL,
	MEGA_PEW_PEW,
	MOVE,
	PEW_PEW
}

enum ValidTargetFlags {
	NONE = 0,
	SELF = 1 << 0,
	GROUP_MEMBERS = 1 << 1,
	OPPONENTS = 1 << 2,
	CELL = 1 << 3,
}

@export_flags("SELF:1", "GROUP_MEMBERS:2", "OPPONENTS:4", "CELL:8") var valid_target_flags: int = 0
