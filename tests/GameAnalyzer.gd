extends RefCounted
class_name GameAnalyzer

# Game analysis system for automated testing

var game_events: Array[String] = []
var player_actions: Array[String] = []
var enemy_behaviors: Array[String] = []

func record_event(event: String) -> void:
	game_events.append(event)
	print("📝 Event recorded: ", event)

func record_player_action(action: String) -> void:
	player_actions.append(action)

func record_enemy_behavior(behavior: String) -> void:
	enemy_behaviors.append(behavior)
