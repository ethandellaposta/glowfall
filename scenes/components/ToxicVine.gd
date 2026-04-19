extends StaticBody2D

## A toxic thorned vine that damages the player on contact.
## Can be destroyed with attack-1 (blade attack).
## Generates its own visuals procedurally.

@export var vine_hp: int = 1
@export var damage: int = 1
@export var damage_cooldown: float = 0.8
@export var vine_height: float = 200.0
@export var vine_width: float = 6.0

var _damage_cooldown_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _vine_container: Node2D
var _thorn_particles: GPUParticles2D

func _ready() -> void:
	_rng.randomize()
	collision_layer = 2
	collision_mask = 0

	_build_visuals()
	_setup_damage_area()
	_setup_collision_shape()

func _process(delta: float) -> void:
	if _damage_cooldown_timer > 0.0:
		_damage_cooldown_timer -= delta

func _build_visuals() -> void:
	_vine_container = Node2D.new()
	_vine_container.name = "Visuals"
	add_child(_vine_container)

	# Main stem — thick, thorny, dark red-green
	var stem_pts_l := PackedVector2Array()
	var stem_pts_r := PackedVector2Array()
	var segs: int = _rng.randi_range(8, 14)
	var seg_h: float = vine_height / float(segs)
	var cx: float = 0.0
	for s in range(segs + 1):
		var sy: float = -vine_height + float(s) * seg_h
		var w: float = vine_width * (0.6 + 0.4 * sin(float(s) * 0.8))
		stem_pts_l.append(Vector2(cx - w * 0.5, sy))
		stem_pts_r.insert(0, Vector2(cx + w * 0.5, sy))
		cx += _rng.randf_range(-6, 6)
	var all_pts := PackedVector2Array()
	all_pts.append_array(stem_pts_l)
	all_pts.append_array(stem_pts_r)

	var stem := Polygon2D.new()
	stem.z_index = 2
	stem.color = Color(0.2, 0.08, 0.12, 0.9)
	stem.polygon = all_pts
	_vine_container.add_child(stem)

	# Thorns — sharp triangles along the stem
	for s in range(1, segs):
		if _rng.randf() < 0.7:
			var ty: float = -vine_height + float(s) * seg_h
			var side: float = 1.0 if _rng.randf() < 0.5 else -1.0
			var thorn := Polygon2D.new()
			thorn.z_index = 3
			thorn.color = Color(0.35, 0.1, 0.15, 0.95)
			var thorn_len: float = _rng.randf_range(8, 16)
			var thorn_w: float = _rng.randf_range(2, 4)
			thorn.polygon = PackedVector2Array([
				Vector2(0, ty - thorn_w),
				Vector2(side * thorn_len, ty + _rng.randf_range(-2, 2)),
				Vector2(0, ty + thorn_w)
			])
			_vine_container.add_child(thorn)

	# Toxic glow — faint red-purple aura
	var glow := Polygon2D.new()
	glow.z_index = 1
	glow.color = Color(0.4, 0.1, 0.2, 0.06)
	glow.polygon = PackedVector2Array([
		Vector2(-20, -vine_height - 10), Vector2(20, -vine_height - 10),
		Vector2(25, 10), Vector2(-25, 10)
	])
	_vine_container.add_child(glow)

	# Drip particles — toxic drips
	_thorn_particles = GPUParticles2D.new()
	_thorn_particles.name = "ToxicDrips"
	_thorn_particles.z_index = 4
	_thorn_particles.amount = 4
	_thorn_particles.lifetime = 1.2
	_thorn_particles.speed_scale = 0.8
	_thorn_particles.randomness = 0.6
	_thorn_particles.position = Vector2(0, -vine_height * 0.5)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 30.0
	mat.gravity = Vector3(0, 40, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(4, vine_height * 0.4, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	var grad := Gradient.new()
	grad.set_color(0, Color(0.5, 0.15, 0.25, 0.8))
	grad.add_point(0.5, Color(0.4, 0.1, 0.2, 0.5))
	grad.set_color(1, Color(0.3, 0.08, 0.15, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex

	_thorn_particles.process_material = mat
	add_child(_thorn_particles)

func _setup_damage_area() -> void:
	var area := Area2D.new()
	area.name = "DamageArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(vine_width + 12, vine_height)
	shape.shape = rect
	shape.position = Vector2(0, -vine_height * 0.5)
	area.add_child(shape)
	add_child(area)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

var _player_inside: bool = false
var _player_ref: CharacterBody2D = null

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player_inside = true
		_player_ref = body
		_try_damage_player()

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_player_inside = false
		_player_ref = null

func _try_damage_player() -> void:
	if _damage_cooldown_timer > 0.0 or not is_instance_valid(_player_ref):
		return
	if _player_ref.has_method("take_damage"):
		var dir: int = 1 if _player_ref.global_position.x > global_position.x else -1
		_player_ref.call("take_damage", damage, dir)
		_damage_cooldown_timer = damage_cooldown

func _setup_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(vine_width + 4, vine_height)
	shape.shape = rect
	shape.position = Vector2(0, -vine_height * 0.5)
	add_child(shape)

func take_hit(dmg: int, _knockback: Vector2) -> void:
	vine_hp -= dmg
	if vine_hp <= 0:
		_destroy()
	else:
		# Flash red on hit
		if is_instance_valid(_vine_container):
			_vine_container.modulate = Color(2.0, 0.5, 0.5, 1)
			var tween := create_tween()
			tween.tween_property(_vine_container, "modulate", Color.WHITE, 0.15)

func _destroy() -> void:
	# Burst of particles on death
	if is_instance_valid(_thorn_particles):
		_thorn_particles.amount = 12
		_thorn_particles.lifetime = 0.5
		_thorn_particles.speed_scale = 3.0
		_thorn_particles.one_shot = true
		_thorn_particles.emitting = true
	# Fade out and remove
	if is_instance_valid(_vine_container):
		var tween := create_tween()
		tween.tween_property(_vine_container, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
	else:
		queue_free()
