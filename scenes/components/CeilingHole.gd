extends Area2D

## A ceiling hole that auto-boosts the player upward into the next room.
## When the player walks under it and presses UP (W), they get launched up.
## Player is dumped to the right side by default, or left if holding left arrow.

@export var target_room_path: String = ""
@export var target_spawn: String = "SpawnDefault"
@export var required_ability: StringName = &""
@export var cooldown_seconds: float = 0.35
@export var spawn_velocity: Vector2 = Vector2(180.0, 0.0)

var _cooldown_active: bool = false
var _player_inside: bool = false
var _player_ref: CharacterBody2D = null
var _particles: GPUParticles2D
var _glow_pulse_time: float = 0.0
var _glow_polygon: Polygon2D
var _arrow_polygon: Polygon2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_visuals()
	# Brief grace period so ceiling holes don't trigger the instant a room loads
	# (non-blocking; do not suspend _ready)
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
	# Upward flowing particles
	_particles = GPUParticles2D.new()
	_particles.name = "UpwardParticles"
	_particles.z_index = 5
	_particles.amount = 8
	_particles.lifetime = 1.5
	_particles.speed_scale = 1.0
	_particles.randomness = 0.4
	_particles.position = Vector2(0, 40)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3(0, -30, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(80, 10, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.2

	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 0.9, 0.5, 0.0))
	grad.add_point(0.2, Color(0.3, 1.0, 0.6, 0.6))
	grad.add_point(0.6, Color(0.2, 0.8, 0.5, 0.4))
	grad.set_color(1, Color(0.1, 0.6, 0.3, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex

	_particles.process_material = mat
	add_child(_particles)

	# Pulsing glow area
	_glow_polygon = Polygon2D.new()
	_glow_polygon.name = "GlowArea"
	_glow_polygon.z_index = 3
	_glow_polygon.color = Color(0.15, 0.8, 0.4, 0.06)
	_glow_polygon.polygon = PackedVector2Array([
		Vector2(-100, -60), Vector2(100, -60),
		Vector2(80, 60), Vector2(-80, 60)
	])
	add_child(_glow_polygon)

	# Upward arrow indicator
	_arrow_polygon = Polygon2D.new()
	_arrow_polygon.name = "UpArrow"
	_arrow_polygon.z_index = 5
	_arrow_polygon.color = Color(0.3, 1.0, 0.6, 0.3)
	_arrow_polygon.polygon = PackedVector2Array([
		Vector2(0, -50),
		Vector2(20, -25), Vector2(8, -25),
		Vector2(8, 10), Vector2(-8, 10),
		Vector2(-8, -25), Vector2(-20, -25)
	])
	add_child(_arrow_polygon)

	# Edge glow lines (left and right)
	for side in [-1.0, 1.0]:
		var edge := Polygon2D.new()
		edge.z_index = 4
		edge.color = Color(0.2, 0.9, 0.5, 0.15)
		var ex: float = side * 100.0
		edge.polygon = PackedVector2Array([
			Vector2(ex - 2, -60), Vector2(ex + 2, -60),
			Vector2(ex * 0.8 + 2, 60), Vector2(ex * 0.8 - 2, 60)
		])
		add_child(edge)

func _process(delta: float) -> void:
	if not _player_inside:
		return
	# Auto-boost when player enters the hole while moving upward (jumping into it)
	if is_instance_valid(_player_ref) and not _cooldown_active:
		if _player_ref.velocity.y < 0.0:
			_boost_player()

func _boost_player() -> void:
	if _cooldown_active or target_room_path.is_empty():
		return
	if not is_instance_valid(_player_ref):
		return
	# Capture player ref before disabling monitoring (which fires body_exited and nulls _player_ref)
	var player := _player_ref
	# Lock out immediately so _process cannot re-trigger while the room loads
	_cooldown_active = true
	set_deferred("monitoring", false)
	if required_ability != &"" and not Global.has_ability(required_ability):
		var game := get_tree().get_first_node_in_group("game")
		if game != null and game.has_method("show_message"):
			game.call("show_message", "Locked: need %s" % String(required_ability))
		_cooldown_active = false
		set_deferred("monitoring", true)
		return

	# Stop the player immediately — no physics carries over
	player.velocity = Vector2.ZERO

	# Trigger room change with a preset spawn velocity
	var game2 := get_tree().get_first_node_in_group("game")
	if game2 == null:
		return
	_finish_cooldown()
	if "_preserve_velocity" in game2:
		game2._preserve_velocity = spawn_velocity
	if game2.has_method("request_room_change"):
		game2.call("request_room_change", target_room_path, target_spawn)

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
