extends Area2D

@export var target_room_path: String = ""
@export var target_spawn: String = "SpawnDefault"
@export var required_ability: StringName = &""

@export var cooldown_seconds: float = 0.35

var _cooldown_active: bool = false
var _spawn_grace: bool = true

var _glow: Polygon2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_visuals()
	# Brief grace period so doors don't trigger the instant a room loads
	set_deferred("monitoring", false)
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	_spawn_grace = false
	set_deferred("monitoring", true)

func _setup_visuals() -> void:
	if target_room_path.is_empty():
		return
	# Subtle glowing doorway indicator
	_glow = Polygon2D.new()
	_glow.z_index = 3
	_glow.color = Color(0.2, 0.85, 0.5, 0.06)
	_glow.polygon = PackedVector2Array([
		Vector2(-20, -48), Vector2(20, -48),
		Vector2(16, 48), Vector2(-16, 48)
	])
	add_child(_glow)
	# Edge lines
	for side in [-1.0, 1.0]:
		var edge := Polygon2D.new()
		edge.z_index = 4
		edge.color = Color(0.2, 0.9, 0.5, 0.12)
		var ex: float = side * 18.0
		edge.polygon = PackedVector2Array([
			Vector2(ex - 1, -48), Vector2(ex + 1, -48),
			Vector2(ex * 0.9 + 1, 48), Vector2(ex * 0.9 - 1, 48)
		])
		add_child(edge)

func _start_cooldown() -> void:
	if cooldown_seconds <= 0.0:
		return
	_cooldown_active = true
	set_deferred("monitoring", false)
	await get_tree().create_timer(cooldown_seconds).timeout
	if not is_inside_tree():
		return
	set_deferred("monitoring", true)
	_cooldown_active = false

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	if _cooldown_active:
		return
	if target_room_path.is_empty():
		return
	if required_ability != &"" and not Global.has_ability(required_ability):
		var game := get_tree().get_first_node_in_group("game")
		if game != null and game.has_method("show_message"):
			game.call("show_message", "Locked: need %s" % String(required_ability))
		return
	var game2 := get_tree().get_first_node_in_group("game")
	if game2 == null:
		return
	_start_cooldown()
	if game2.has_method("request_room_change"):
		game2.call("request_room_change", target_room_path, target_spawn)
