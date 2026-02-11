extends Area2D

@export var target_room_path: String = ""
@export var target_spawn: String = "SpawnDefault"
@export var required_ability: StringName = &""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	if target_room_path.is_empty():
		return
	if required_ability != &"" and not Global.has_ability(required_ability):
		var game := get_tree().get_first_node_in_group("game")
		if game != null and game.has_method("show_message"):
			game.call("show_message", "Locked: need %s" % String(required_ability))
		return
	var game2 := get_tree().get_first_node_in_group("game")
	if game2 != null and game2.has_method("request_room_change"):
		game2.call("request_room_change", target_room_path, target_spawn)
