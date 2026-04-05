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
signal player_action_executed(player_idx : int)
signal hud_camera_resetted
@warning_ignore_restore("unused_signal")
