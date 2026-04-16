extends Node

@warning_ignore_start("unused_signal")

signal on_hud_is_ready
signal battle_started
signal on_hud_player_end_turn(player : Player)
signal on_character_begin_turn(character : BaseCharacter)
signal on_all_characters_spawned(players : Array[Player], enemies : Array[BaseCharacter])
signal map_initialized(map: BaseMap)
signal battle_driver_initialized(battle_driver: BattleDriver)
signal main_init_finished
signal enemy_selected_action(enemy : BaseCharacter, action: CombatAction)
signal pre_begin_turn
signal before_action_executed(character : BaseCharacter, action : CombatAction)
signal after_action_executed(character : BaseCharacter, action : CombatAction)
signal hud_camera_resetted

signal display_line_of_sight(character : BaseCharacter, area2d : Area2D)
signal hide_line_of_sight(character : BaseCharacter)
signal display_range(character : BaseCharacter, range : int)

@warning_ignore_restore("unused_signal")
