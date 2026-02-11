extends Area2D

@export var ability: StringName = &"double_jump"

func _ready() -> void:
	if Global.has_ability(ability):
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	Global.grant_ability(ability)
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("show_message"):
		game.call("show_message", "Picked up: %s" % String(ability))
	queue_free()
