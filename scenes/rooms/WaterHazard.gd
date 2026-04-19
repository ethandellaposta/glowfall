extends Area2D

@export var damage: int = 999
@export var knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage, 0)
		return
	if body.has_method("take_hit"):
		body.call("take_hit", damage, knockback)
