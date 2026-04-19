extends Area2D

## A floor hole the player can drop through by pressing DOWN / crouch.
## Unlike a regular Door, requires intentional input so the player doesn't
## accidentally fall through while walking across.

@export var target_room_path: String = ""
@export var target_spawn: String = "SpawnDefault"
@export var required_ability: StringName = &""
@export var cooldown_seconds: float = 0.35

var _cooldown_active: bool = false
var _player_inside: bool = false
var _player_ref: CharacterBody2D = null
var _arrow: Polygon2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_visuals()
	# Brief grace period so holes don't trigger the instant a room loads
	set_deferred("monitoring", false)
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 0.8
	add_child(t)
	t.timeout.connect(func() -> void:
		if is_inside_tree():
			set_deferred("monitoring", true)
		t.queue_free()
	)
	t.start()

func _setup_visuals() -> void:
	if target_room_path.is_empty():
		return
	# Downward arrow indicator (hidden until player is nearby)
	_arrow = Polygon2D.new()
	_arrow.name = "DownArrow"
	_arrow.z_index = 5
	_arrow.color = Color(0.3, 1.0, 0.6, 0.0)
	_arrow.polygon = PackedVector2Array([
		Vector2(0, 50),
		Vector2(20, 25), Vector2(8, 25),
		Vector2(8, -10), Vector2(-8, -10),
		Vector2(-8, 25), Vector2(-20, 25)
	])
	add_child(_arrow)
	# Edge glow lines
	for side in [-1.0, 1.0]:
		var edge := Polygon2D.new()
		edge.z_index = 4
		edge.color = Color(0.2, 0.9, 0.5, 0.08)
		var ex: float = side * 100.0
		edge.polygon = PackedVector2Array([
			Vector2(ex - 2, -40), Vector2(ex + 2, -40),
			Vector2(ex + 2, 40), Vector2(ex - 2, 40)
		])
		add_child(edge)

func _process(_delta: float) -> void:
	if not _player_inside or not is_instance_valid(_player_ref):
		if _arrow != null:
			_arrow.color.a = 0.0
		return
	# Show arrow prompt when player stands over the hole
	if _arrow != null:
		_arrow.color.a = 0.3
	# Only trigger when player presses crouch / down
	if Input.is_action_pressed("crouch") and not _cooldown_active:
		_drop_player()

func _drop_player() -> void:
	if _cooldown_active or target_room_path.is_empty():
		return
	if not is_instance_valid(_player_ref):
		return
	if required_ability != &"" and not Global.has_ability(required_ability):
		var game := get_tree().get_first_node_in_group("game")
		if game != null and game.has_method("show_message"):
			game.call("show_message", "Locked: need %s" % String(required_ability))
		return
	_cooldown_active = true
	set_deferred("monitoring", false)
	_player_ref.velocity = Vector2.ZERO
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	_finish_cooldown()
	if game.has_method("request_room_change"):
		game.call("request_room_change", target_room_path, target_spawn)

func _finish_cooldown() -> void:
	if cooldown_seconds <= 0.0:
		set_deferred("monitoring", true)
		_cooldown_active = false
		return
	await get_tree().create_timer(cooldown_seconds).timeout
	if not is_inside_tree():
		return
	set_deferred("monitoring", true)
	_cooldown_active = false

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_inside = true
		_player_ref = body

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_player_inside = false
		_player_ref = null
		if _arrow != null:
			_arrow.color.a = 0.0
