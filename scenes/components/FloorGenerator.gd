extends Node2D

## Procedurally generates 10 stacked interior floor levels.
## Floors 1-5: navigated via decay holes in the floor.
## Floors 6-10: navigated via a vine-filled elevator shaft on the right side.
## Attach to the Geometry node of an interior room scene.

@export var floor_count: int = 10
@export var floor_height: float = 330.0
@export var room_half_width: float = 1000.0
@export var floor_thickness: float = 60.0
@export var hole_width: float = 240.0
@export var elevator_shaft_width: float = 200.0
@export var seed_value: int = 0

const WALL_COLOR := Color(0.12, 0.12, 0.15, 1)
const WALL_DARK := Color(0.11, 0.11, 0.14, 1)
const WALL_FRAME := Color(0.08, 0.08, 0.1, 1)
const FLOOR_COLOR := Color(0.12, 0.12, 0.15, 1)
const FLOOR_HIGHLIGHT := Color(0.18, 0.18, 0.22, 1)
const WINDOW_COLOR := Color(0.05, 0.06, 0.1, 0.45)
const DECAY_EDGE := Color(0.1, 0.09, 0.07, 0.6)
const DECAY_HOLE := Color(0.02, 0.02, 0.03, 0.9)
const REBAR_COLOR := Color(0.3, 0.22, 0.15, 0.6)
const VINE_STEM := Color(0.05, 0.15, 0.07, 0.85)
const VINE_LEAF := Color(0.08, 0.24, 0.12, 0.7)
const VINE_LEAF_LIGHT := Color(0.12, 0.34, 0.18, 0.55)
const VINE_GLOW := Color(0.2, 0.9, 0.5, 0.06)
const SHAFT_BG := Color(0.04, 0.04, 0.06, 1)
const SHAFT_FRAME := Color(0.06, 0.06, 0.08, 1)

var _rng := RandomNumberGenerator.new()

# Cached shared light textures (generated once)
static var _shared_light_tex_64: GradientTexture2D
static var _shared_light_tex_32: GradientTexture2D

# y position of the top of each floor (where player stands)
# floor_top_y[i] = base_y + i * floor_height
var base_y: float = 420.0

static func _get_light_tex_64() -> GradientTexture2D:
	if _shared_light_tex_64 == null:
		_shared_light_tex_64 = GradientTexture2D.new()
		_shared_light_tex_64.width = 64
		_shared_light_tex_64.height = 64
		_shared_light_tex_64.fill = GradientTexture2D.FILL_RADIAL
		_shared_light_tex_64.fill_from = Vector2(0.5, 0.5)
		_shared_light_tex_64.fill_to = Vector2(0.5, 0.0)
		var grad := Gradient.new()
		grad.set_color(0, Color.WHITE)
		grad.add_point(0.4, Color(1, 1, 1, 0.4))
		grad.set_color(1, Color(1, 1, 1, 0))
		_shared_light_tex_64.gradient = grad
	return _shared_light_tex_64

static func _get_light_tex_32() -> GradientTexture2D:
	if _shared_light_tex_32 == null:
		_shared_light_tex_32 = GradientTexture2D.new()
		_shared_light_tex_32.width = 32
		_shared_light_tex_32.height = 32
		_shared_light_tex_32.fill = GradientTexture2D.FILL_RADIAL
		_shared_light_tex_32.fill_from = Vector2(0.5, 0.5)
		_shared_light_tex_32.fill_to = Vector2(0.5, 0.0)
		var grad := Gradient.new()
		grad.set_color(0, Color.WHITE)
		grad.add_point(0.4, Color(1, 1, 1, 0.3))
		grad.set_color(1, Color(1, 1, 1, 0))
		_shared_light_tex_32.gradient = grad
	return _shared_light_tex_32

func _ready() -> void:
	_rng.seed = seed_value if seed_value != 0 else hash(get_path())
	_generate_all_floors()

func _generate_all_floors() -> void:
	var floors_root := Node2D.new()
	floors_root.name = "GeneratedFloors"
	add_child(floors_root)

	# Hole positions alternate left/right/center for variety
	var hole_positions: Array[float] = []
	var pos_options: Array[float] = [-500.0, -250.0, 0.0, 250.0, 500.0]
	for i in range(floor_count):
		hole_positions.append(pos_options[i % pos_options.size()])

	# Elevator shaft x position (right side)
	var shaft_x: float = room_half_width - elevator_shaft_width - 30.0

	for i in range(floor_count):
		var floor_y: float = base_y + float(i) * floor_height
		var is_shaft_floor: bool = i >= 5
		_build_floor_level(floors_root, i, floor_y, hole_positions[i], is_shaft_floor, shaft_x)

	# Build elevator shaft structure for floors 6-10
	_build_elevator_shaft(floors_root, shaft_x)

	# Extend walls to cover all floors
	_build_side_walls(floors_root)

	# Floating dust/fume particles throughout the building
	_add_dust_particles(floors_root)

func _add_dust_particles(parent: Node2D) -> void:
	var total_h: float = float(floor_count) * floor_height
	var top_y: float = base_y - floor_height
	var bot_y: float = base_y + total_h

	# Create particle emitters spread across the building
	for i in range(2):
		var emitter_x: float = -room_half_width * 0.5 + float(i) * room_half_width
		var emitter_y: float = (top_y + bot_y) * 0.5

		var particles := GPUParticles2D.new()
		particles.name = "DustParticles%d" % i
		particles.z_index = 5
		particles.amount = 12
		particles.lifetime = 8.0
		particles.speed_scale = 0.3
		particles.randomness = 1.0
		particles.position = Vector2(emitter_x, emitter_y)

		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 5.0
		mat.initial_velocity_max = 15.0
		mat.gravity = Vector3(0, 2, 0)
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(400, total_h * 0.4, 0)
		mat.scale_min = 0.5
		mat.scale_max = 2.0
		mat.color = Color(0.6, 0.55, 0.45, 0.15)

		# Color variation over lifetime: fade in and out
		var color_curve := GradientTexture1D.new()
		var grad := Gradient.new()
		grad.set_color(0, Color(0.5, 0.45, 0.4, 0.0))
		grad.add_point(0.2, Color(0.6, 0.55, 0.45, 0.12))
		grad.add_point(0.5, Color(0.55, 0.5, 0.42, 0.15))
		grad.add_point(0.8, Color(0.5, 0.45, 0.4, 0.08))
		grad.set_color(1, Color(0.5, 0.45, 0.4, 0.0))
		color_curve.gradient = grad
		mat.color_ramp = color_curve

		particles.process_material = mat
		parent.add_child(particles)

	# Heavier fume/haze particles (fewer, larger, slower)
	var fumes := GPUParticles2D.new()
	fumes.name = "FumeParticles"
	fumes.z_index = 4
	fumes.amount = 6
	fumes.lifetime = 12.0
	fumes.speed_scale = 0.15
	fumes.randomness = 1.0
	fumes.position = Vector2(0, (top_y + bot_y) * 0.5)

	var fume_mat := ParticleProcessMaterial.new()
	fume_mat.direction = Vector3(1, -0.5, 0)
	fume_mat.spread = 120.0
	fume_mat.initial_velocity_min = 3.0
	fume_mat.initial_velocity_max = 8.0
	fume_mat.gravity = Vector3(0, -1, 0)
	fume_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fume_mat.emission_box_extents = Vector3(800, total_h * 0.4, 0)
	fume_mat.scale_min = 2.0
	fume_mat.scale_max = 5.0
	fume_mat.color = Color(0.4, 0.4, 0.35, 0.06)

	var fume_grad := Gradient.new()
	fume_grad.set_color(0, Color(0.3, 0.3, 0.28, 0.0))
	fume_grad.add_point(0.3, Color(0.4, 0.38, 0.32, 0.06))
	fume_grad.add_point(0.7, Color(0.35, 0.35, 0.3, 0.04))
	fume_grad.set_color(1, Color(0.3, 0.3, 0.28, 0.0))
	var fume_color_tex := GradientTexture1D.new()
	fume_color_tex.gradient = fume_grad
	fume_mat.color_ramp = fume_color_tex

	fumes.process_material = fume_mat
	parent.add_child(fumes)

func _build_floor_level(parent: Node2D, index: int, floor_y: float, hole_x: float, is_shaft_floor: bool, shaft_x: float) -> void:
	var level := Node2D.new()
	level.name = "Floor%d" % index
	parent.add_child(level)

	var ceiling_y: float = floor_y - floor_height + floor_thickness * 0.5
	var half_w: float = room_half_width

	# --- Floor platform with hole ---
	var floor_node := Node2D.new()
	floor_node.name = "Platform"
	level.add_child(floor_node)

	var inner_top: float = ceiling_y + floor_thickness * 0.5
	var inner_bot: float = floor_y - floor_thickness * 0.5

	if index < floor_count - 1:
		# Floor has a hole to drop through
		var hx: float = hole_x
		var hw: float = hole_width
		if is_shaft_floor:
			hx = shaft_x + elevator_shaft_width * 0.5
			hw = elevator_shaft_width

		# Add irregular jitter to hole edges
		var jitter_l: float = _rng.randf_range(-20, 30)
		var jitter_r: float = _rng.randf_range(-30, 20)
		var hole_left: float = hx - hw * 0.5 + jitter_l
		var hole_right: float = hx + hw * 0.5 + jitter_r

		# Left section of floor
		if hole_left > -half_w + 10:
			_add_floor_section(floor_node, -half_w, hole_left, floor_y)

		# Right section of floor
		if hole_right < half_w - 10:
			_add_floor_section(floor_node, hole_right, half_w, floor_y)

		# Decay hole visuals
		if not is_shaft_floor:
			_add_decay_hole(level, hx, floor_y, hw)

		# 60% chance of EXTRA floor decay: additional broken sections
		if _rng.randf() < 0.6 and not is_shaft_floor:
			var extra_hx: float = _rng.randf_range(-half_w + 200, half_w - 200)
			# Don't overlap with main hole
			if absf(extra_hx - hx) > hw + 80:
				var extra_hw: float = _rng.randf_range(60, 150)
				_add_floor_crack(floor_node, level, extra_hx, floor_y, extra_hw)
	else:
		# Bottom floor: solid but with cracks
		_add_floor_section(floor_node, -half_w, half_w, floor_y)

	# --- Back wall ---
	_build_back_wall(level, index, floor_y, ceiling_y, is_shaft_floor, shaft_x)

	# --- Lobby decay on top floor ---
	if index == 0:
		_add_lobby_decay(level, floor_y, ceiling_y)

	# --- Per-floor vines ---
	var vine_count: int = _rng.randi_range(2, 5)
	for _v in range(vine_count):
		var vx: float = _rng.randf_range(-half_w + 60, half_w - 60)
		if is_shaft_floor and vx > shaft_x - 50:
			continue
		_add_hanging_vine(level, vx, inner_top, inner_bot)

	# --- Per-floor office debris ---
	if _rng.randf() < 0.7:
		_add_office_debris(level, floor_y, ceiling_y, half_w)

	# --- Per-floor drip particles ---
	if _rng.randf() < 0.5:
		_add_drip_particles(level, inner_top, inner_bot, half_w)

	# --- Per-floor toxic vines (destructible hazards) ---
	if _rng.randf() < 0.5:
		var toxic_count: int = _rng.randi_range(1, 3)
		for _tv in range(toxic_count):
			var tvx: float = _rng.randf_range(-half_w + 100, half_w - 100)
			if is_shaft_floor and tvx > shaft_x - 80:
				continue
			var tv_height: float = _rng.randf_range(80, minf(200, (inner_bot - inner_top) * 0.7))
			_add_toxic_vine(level, tvx, inner_bot, tv_height)

	# --- Per-floor ambient light sources ---
	var light_count: int = _rng.randi_range(1, 3)
	for _li in range(light_count):
		var lx: float = _rng.randf_range(-half_w + 80, half_w - 80)
		if is_shaft_floor and lx > shaft_x - 60:
			continue
		var light_type: int = _rng.randi_range(0, 3)
		if light_type == 0:
			_add_emergency_light(level, lx, inner_top)
		elif light_type == 1:
			_add_sparking_wire(level, lx, inner_top)
		elif light_type == 2:
			_add_glowing_fungus(level, lx, inner_bot)
		else:
			_add_blinking_panel(level, lx, _rng.randf_range(inner_top + 30, inner_bot - 30))

func _add_floor_section(parent: Node2D, x_left: float, x_right: float, y: float) -> void:
	var w: float = x_right - x_left
	var cx: float = (x_left + x_right) * 0.5
	var half_t: float = floor_thickness * 0.5

	# Collision
	var body := StaticBody2D.new()
	parent.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, floor_thickness)
	shape.shape = rect
	shape.position = Vector2(cx, y)
	body.add_child(shape)

	# Visual: main slab — dark, opaque, above backdrop
	var surface := Polygon2D.new()
	surface.z_index = -1
	surface.color = Color(0.065, 0.065, 0.075, 1)
	surface.polygon = PackedVector2Array([
		Vector2(x_left, y - half_t), Vector2(x_right, y - half_t),
		Vector2(x_right, y + half_t), Vector2(x_left, y + half_t)
	])
	parent.add_child(surface)

	# Very subtle top edge (just a hint of lighter concrete)
	var edge := Polygon2D.new()
	edge.z_index = -1
	edge.color = Color(0.085, 0.085, 0.095, 1)
	edge.polygon = PackedVector2Array([
		Vector2(x_left, y - half_t), Vector2(x_right, y - half_t),
		Vector2(x_right, y - half_t + 2), Vector2(x_left, y - half_t + 2)
	])
	parent.add_child(edge)

	# Underside shadow
	var under := Polygon2D.new()
	under.z_index = -1
	under.color = Color(0.04, 0.04, 0.05, 1)
	under.polygon = PackedVector2Array([
		Vector2(x_left, y + half_t - 4), Vector2(x_right, y + half_t - 4),
		Vector2(x_right, y + half_t), Vector2(x_left, y + half_t)
	])
	parent.add_child(under)

	# Concrete texture: subtle random patches
	for i in range(mini(int(w / 200), 4)):
		var px: float = _rng.randf_range(x_left + 5, x_right - 20)
		var pw: float = _rng.randf_range(15, 50)
		var patch := Polygon2D.new()
		patch.z_index = -1
		var pb: float = _rng.randf_range(0.05, 0.08)
		patch.color = Color(pb, pb, pb * 1.05, _rng.randf_range(0.15, 0.35))
		patch.polygon = PackedVector2Array([
			Vector2(px, y - half_t + 2), Vector2(px + pw, y - half_t + 2),
			Vector2(px + pw, y - half_t + 2 + _rng.randf_range(8, 20)),
			Vector2(px, y - half_t + 2 + _rng.randf_range(8, 20))
		])
		parent.add_child(patch)

func _add_decay_hole(parent: Node2D, hx: float, floor_y: float, hw: float) -> void:
	# The hole is just empty space — no floor collision there.
	# We add jagged crumbling edges on the left and right floor lips,
	# plus rebar stubs and small rubble on the floor below.
	var decay := Node2D.new()
	decay.name = "DecayHole"
	parent.add_child(decay)

	var half_hw: float = hw * 0.5
	var half_t: float = floor_thickness * 0.5
	var top: float = floor_y - half_t
	var bot: float = floor_y + half_t

	# Jagged crumbling edge on the LEFT lip of the hole
	var left_edge := Polygon2D.new()
	left_edge.color = Color(0.14, 0.13, 0.11, 0.9)
	var le_x: float = hx - half_hw
	left_edge.polygon = PackedVector2Array([
		Vector2(le_x, top),
		Vector2(le_x + 8 + _rng.randf_range(0, 6), top + 4),
		Vector2(le_x + 12 + _rng.randf_range(0, 8), top + half_t),
		Vector2(le_x + 6 + _rng.randf_range(0, 10), bot - 4),
		Vector2(le_x + 3, bot),
		Vector2(le_x, bot)
	])
	decay.add_child(left_edge)

	# Jagged crumbling edge on the RIGHT lip
	var right_edge := Polygon2D.new()
	right_edge.color = Color(0.14, 0.13, 0.11, 0.9)
	var re_x: float = hx + half_hw
	right_edge.polygon = PackedVector2Array([
		Vector2(re_x, top),
		Vector2(re_x - 8 - _rng.randf_range(0, 6), top + 4),
		Vector2(re_x - 12 - _rng.randf_range(0, 8), top + half_t),
		Vector2(re_x - 6 - _rng.randf_range(0, 10), bot - 4),
		Vector2(re_x - 3, bot),
		Vector2(re_x, bot)
	])
	decay.add_child(right_edge)

	# Darker underside shadow on the lips
	for side in [-1.0, 1.0]:
		var lip_shadow := Polygon2D.new()
		lip_shadow.color = Color(0.06, 0.06, 0.07, 0.6)
		var sx: float = hx + side * half_hw
		var inward: float = -side * 15.0
		lip_shadow.polygon = PackedVector2Array([
			Vector2(sx, bot - 8), Vector2(sx + inward, bot - 8),
			Vector2(sx + inward, bot + 6), Vector2(sx, bot + 6)
		])
		decay.add_child(lip_shadow)

	# Rebar stubs poking out of the broken edges
	for r in range(_rng.randi_range(2, 5)):
		var rebar := Polygon2D.new()
		rebar.color = Color(
			_rng.randf_range(0.28, 0.38),
			_rng.randf_range(0.16, 0.24),
			_rng.randf_range(0.08, 0.15),
			_rng.randf_range(0.55, 0.8)
		)
		var from_left: bool = _rng.randf() < 0.5
		var rx: float
		var rdir: float
		if from_left:
			rx = hx - half_hw
			rdir = 1.0
		else:
			rx = hx + half_hw
			rdir = -1.0
		var ry: float = _rng.randf_range(top + 4, bot - 4)
		var rlen: float = _rng.randf_range(10.0, 30.0)
		var rw: float = _rng.randf_range(2.0, 3.5)
		rebar.polygon = PackedVector2Array([
			Vector2(rx, ry - rw * 0.5),
			Vector2(rx + rdir * rlen, ry - rw * 0.3),
			Vector2(rx + rdir * rlen, ry + rw * 0.3),
			Vector2(rx, ry + rw * 0.5)
		])
		decay.add_child(rebar)

	# Small concrete rubble chunks scattered on the floor below
	var rubble_y: float = floor_y + floor_height - half_t
	for r in range(_rng.randi_range(3, 7)):
		var rubble := Polygon2D.new()
		var rb: float = _rng.randf_range(0.12, 0.18)
		rubble.color = Color(rb, rb * 0.92, rb * 0.82, _rng.randf_range(0.45, 0.75))
		var rx: float = hx + _rng.randf_range(-half_hw * 0.7, half_hw * 0.7)
		var rw: float = _rng.randf_range(6.0, 18.0)
		var rh: float = _rng.randf_range(4.0, 10.0)
		rubble.polygon = PackedVector2Array([
			Vector2(rx - rw * 0.5, rubble_y - rh),
			Vector2(rx + rw * 0.3, rubble_y - rh + _rng.randf_range(0, 3)),
			Vector2(rx + rw * 0.5, rubble_y),
			Vector2(rx - rw * 0.4, rubble_y)
		])
		decay.add_child(rubble)

func _add_floor_crack(floor_parent: Node2D, level: Node2D, cx: float, floor_y: float, crack_w: float) -> void:
	# Visual-only irregular crack/break in the floor (no collision gap — just cosmetic decay)
	var half_t: float = floor_thickness * 0.5
	var top: float = floor_y - half_t
	var bot: float = floor_y + half_t

	# Irregular crack shape on the floor surface
	var num_pts: int = _rng.randi_range(6, 10)
	var crack_pts := PackedVector2Array()
	for p in range(num_pts):
		var angle: float = float(p) / float(num_pts) * TAU
		var rx: float = crack_w * 0.5 * (0.5 + _rng.randf_range(0.0, 0.6))
		var ry: float = half_t * (0.3 + _rng.randf_range(0.0, 0.7))
		crack_pts.append(Vector2(
			cx + cos(angle) * rx + _rng.randf_range(-8, 8),
			floor_y + sin(angle) * ry + _rng.randf_range(-3, 3)
		))

	# Dark crack line
	var crack_vis := Polygon2D.new()
	crack_vis.z_index = 0
	crack_vis.color = Color(0.03, 0.03, 0.04, 0.8)
	crack_vis.polygon = crack_pts
	level.add_child(crack_vis)

	# Crumbling edge around crack
	var edge_pts := PackedVector2Array()
	for p in range(num_pts):
		var angle2: float = float(p) / float(num_pts) * TAU
		var orig: Vector2 = crack_pts[p]
		edge_pts.append(Vector2(
			orig.x + cos(angle2) * _rng.randf_range(4, 12),
			orig.y + sin(angle2) * _rng.randf_range(3, 8)
		))
	for p in range(num_pts):
		var p2: int = (p + 1) % num_pts
		var seg := Polygon2D.new()
		seg.z_index = 0
		var eb: float = _rng.randf_range(0.09, 0.13)
		seg.color = Color(eb, eb * 0.95, eb * 0.85, 0.7)
		seg.polygon = PackedVector2Array([edge_pts[p], edge_pts[p2], crack_pts[p2], crack_pts[p]])
		level.add_child(seg)

	# Rebar stubs in crack
	for _r in range(_rng.randi_range(1, 3)):
		var rebar := Polygon2D.new()
		rebar.z_index = 1
		rebar.color = Color(_rng.randf_range(0.3, 0.45), _rng.randf_range(0.18, 0.25), _rng.randf_range(0.08, 0.14), 0.7)
		var rx: float = cx + _rng.randf_range(-crack_w * 0.3, crack_w * 0.3)
		var rlen: float = _rng.randf_range(8, 25)
		var rw: float = _rng.randf_range(1.5, 3.0)
		rebar.polygon = PackedVector2Array([
			Vector2(rx - rw, floor_y - rw), Vector2(rx + rlen, floor_y - rw * 0.5),
			Vector2(rx + rlen, floor_y + rw * 0.5), Vector2(rx - rw, floor_y + rw)
		])
		level.add_child(rebar)

func _add_hanging_vine(parent: Node2D, vx: float, top_y: float, bot_y: float) -> void:
	var vine_len: float = _rng.randf_range((bot_y - top_y) * 0.3, (bot_y - top_y) * 1.1)
	var vine_w: float = _rng.randf_range(2.5, 8)
	var vine_start_y: float = top_y - _rng.randf_range(0, 10)
	var segs: int = _rng.randi_range(5, 10)
	var seg_h: float = vine_len / float(segs)
	var vine_pts := PackedVector2Array()
	var vine_pts_r := PackedVector2Array()
	var cx: float = vx
	for s in range(segs + 1):
		var sy: float = minf(vine_start_y + float(s) * seg_h, bot_y + 15)
		vine_pts.append(Vector2(cx - vine_w * 0.5, sy))
		vine_pts_r.insert(0, Vector2(cx + vine_w * 0.5, sy))
		cx += _rng.randf_range(-10, 10)
	var all_pts := PackedVector2Array()
	all_pts.append_array(vine_pts)
	all_pts.append_array(vine_pts_r)
	var vine_stem := Polygon2D.new()
	vine_stem.z_index = 3
	var vg: float = _rng.randf_range(0.1, 0.2)
	vine_stem.color = Color(vg * 0.3, vg, vg * 0.4, _rng.randf_range(0.6, 0.9))
	vine_stem.polygon = all_pts
	parent.add_child(vine_stem)

	# Leaves
	var leaf_count: int = _rng.randi_range(2, 4)
	for _l in range(leaf_count):
		var lt2: float = _rng.randf_range(0.1, 0.9)
		var li: int = clampi(int(lt2 * float(segs)), 0, segs)
		var lx: float = vine_pts[li].x + _rng.randf_range(-6, 6)
		var ly: float = vine_pts[li].y + _rng.randf_range(-4, 4)
		var leaf := Polygon2D.new()
		leaf.z_index = 3
		var lg: float = _rng.randf_range(0.12, 0.3)
		leaf.color = Color(lg * 0.4, lg, lg * 0.5, _rng.randf_range(0.5, 0.8))
		var lw: float = _rng.randf_range(5, 15)
		var lh: float = _rng.randf_range(3, 10)
		var side_dir: float = 1.0 if _rng.randf() < 0.5 else -1.0
		leaf.polygon = PackedVector2Array([
			Vector2(lx, ly),
			Vector2(lx + side_dir * lw, ly + lh * 0.3),
			Vector2(lx + side_dir * lw * 0.7, ly + lh),
			Vector2(lx - side_dir * 2, ly + lh * 0.6)
		])
		parent.add_child(leaf)

func _add_office_debris(parent: Node2D, floor_y: float, ceiling_y: float, half_w: float) -> void:
	var half_t: float = floor_thickness * 0.5
	var ground: float = floor_y - half_t
	var debris_count: int = _rng.randi_range(2, 5)

	for _d in range(debris_count):
		var dx: float = _rng.randf_range(-half_w + 80, half_w - 80)
		var dtype: int = _rng.randi_range(0, 4)

		match dtype:
			0:  # Toppled desk
				var dw: float = _rng.randf_range(50, 90)
				var dh: float = _rng.randf_range(4, 8)
				var tilt: float = _rng.randf_range(-12, 12)
				var desk := Polygon2D.new()
				desk.z_index = 2
				desk.color = Color(0.1, 0.08, 0.06, _rng.randf_range(0.5, 0.8))
				desk.polygon = PackedVector2Array([
					Vector2(dx, ground - 20 + tilt), Vector2(dx + dw, ground - 20 - tilt),
					Vector2(dx + dw, ground - 20 - tilt + dh), Vector2(dx, ground - 20 + tilt + dh)
				])
				parent.add_child(desk)
				# Desk leg
				var leg := Polygon2D.new()
				leg.z_index = 2
				leg.color = Color(0.07, 0.06, 0.05, 0.6)
				leg.polygon = PackedVector2Array([
					Vector2(dx + 5, ground - 20 + tilt + dh), Vector2(dx + 9, ground - 20 + tilt + dh),
					Vector2(dx + 9, ground), Vector2(dx + 5, ground)
				])
				parent.add_child(leg)

			1:  # Broken monitor
				var mw: float = _rng.randf_range(20, 35)
				var mh: float = _rng.randf_range(15, 25)
				var mon := Polygon2D.new()
				mon.z_index = 2
				mon.color = Color(0.05, 0.05, 0.07, 0.75)
				mon.polygon = PackedVector2Array([
					Vector2(dx, ground - mh), Vector2(dx + mw, ground - mh),
					Vector2(dx + mw, ground), Vector2(dx, ground)
				])
				parent.add_child(mon)
				# Cracked screen
				var scr := Polygon2D.new()
				scr.z_index = 2
				scr.color = Color(0.06, 0.1, 0.08, _rng.randf_range(0.2, 0.4))
				scr.polygon = PackedVector2Array([
					Vector2(dx + 2, ground - mh + 2), Vector2(dx + mw - 2, ground - mh + 2),
					Vector2(dx + mw - 2, ground - 2), Vector2(dx + 2, ground - 2)
				])
				parent.add_child(scr)

			2:  # Fallen chair
				var cw2: float = _rng.randf_range(20, 35)
				var ch2: float = _rng.randf_range(15, 28)
				var tilt2: float = _rng.randf_range(-20, 20)
				var chair := Polygon2D.new()
				chair.z_index = 2
				chair.color = Color(0.07, 0.06, 0.05, _rng.randf_range(0.5, 0.7))
				chair.polygon = PackedVector2Array([
					Vector2(dx, ground - ch2 + tilt2), Vector2(dx + cw2, ground - ch2 - tilt2),
					Vector2(dx + cw2 + 2, ground - ch2 - tilt2 + 4), Vector2(dx - 2, ground - ch2 + tilt2 + 4)
				])
				parent.add_child(chair)

			3:  # Filing cabinet (tall, narrow)
				var fw: float = _rng.randf_range(18, 30)
				var fh: float = _rng.randf_range(30, 55)
				var tilt3: float = _rng.randf_range(-5, 5)
				var cab := Polygon2D.new()
				cab.z_index = 2
				cab.color = Color(0.08, 0.08, 0.09, _rng.randf_range(0.6, 0.85))
				cab.polygon = PackedVector2Array([
					Vector2(dx + tilt3, ground - fh), Vector2(dx + fw + tilt3, ground - fh),
					Vector2(dx + fw, ground), Vector2(dx, ground)
				])
				parent.add_child(cab)
				# Drawer lines
				for dr in range(_rng.randi_range(1, 3)):
					var dy: float = ground - fh + float(dr) * (fh / 3.0)
					var drawer := Polygon2D.new()
					drawer.z_index = 2
					drawer.color = Color(0.06, 0.06, 0.07, 0.5)
					drawer.polygon = PackedVector2Array([
						Vector2(dx + 2, dy), Vector2(dx + fw - 2, dy),
						Vector2(dx + fw - 2, dy + 2), Vector2(dx + 2, dy + 2)
					])
					parent.add_child(drawer)

			4:  # Scattered papers
				for _p in range(_rng.randi_range(2, 5)):
					var paper := Polygon2D.new()
					paper.z_index = 1
					paper.color = Color(0.18, 0.17, 0.15, _rng.randf_range(0.15, 0.4))
					var px: float = dx + _rng.randf_range(-30, 30)
					var pw: float = _rng.randf_range(8, 18)
					var ph: float = _rng.randf_range(5, 12)
					paper.polygon = PackedVector2Array([
						Vector2(px, ground - ph + _rng.randf_range(-2, 2)),
						Vector2(px + pw, ground - ph + _rng.randf_range(-2, 2)),
						Vector2(px + pw + _rng.randf_range(-3, 3), ground),
						Vector2(px + _rng.randf_range(-2, 2), ground)
					])
					parent.add_child(paper)

func _add_drip_particles(parent: Node2D, top_y: float, bot_y: float, half_w: float) -> void:
	var drips := GPUParticles2D.new()
	drips.name = "Drips"
	drips.z_index = 4
	drips.amount = _rng.randi_range(2, 4)
	drips.lifetime = 3.0
	drips.speed_scale = 0.6
	drips.randomness = 0.5
	drips.position = Vector2(_rng.randf_range(-half_w * 0.5, half_w * 0.5), top_y + 10)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 50.0
	mat.gravity = Vector3(0, 120, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(half_w * 0.4, 5, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8

	var grad := Gradient.new()
	grad.set_color(0, Color(0.3, 0.4, 0.5, 0.5))
	grad.add_point(0.5, Color(0.25, 0.35, 0.45, 0.3))
	grad.set_color(1, Color(0.2, 0.3, 0.4, 0.0))
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	mat.color_ramp = gtex

	drips.process_material = mat
	parent.add_child(drips)

func _add_emergency_light(parent: Node2D, x: float, ceiling_y: float) -> void:
	var container := Node2D.new()
	container.name = "EmergencyLight"
	container.position = Vector2(x, ceiling_y + 8)
	parent.add_child(container)
	# Fixture polygon
	var fixture := Polygon2D.new()
	fixture.z_index = 3
	fixture.color = Color(0.12, 0.1, 0.09, 1)
	fixture.polygon = PackedVector2Array([
		Vector2(-8, -4), Vector2(8, -4), Vector2(6, 4), Vector2(-6, 4)
	])
	container.add_child(fixture)
	# Bulb
	var bulb := Polygon2D.new()
	bulb.z_index = 4
	bulb.color = Color(0.6, 0.15, 0.1, 0.8)
	bulb.polygon = PackedVector2Array([
		Vector2(-3, 3), Vector2(3, 3), Vector2(2, 8), Vector2(-2, 8)
	])
	container.add_child(bulb)
	# PointLight2D — dim red glow
	var light := PointLight2D.new()
	light.color = Color(0.8, 0.2, 0.1, 1)
	light.energy = _rng.randf_range(0.3, 0.6)
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.position = Vector2(0, 6)
	light.texture = _get_light_tex_64()
	light.texture_scale = _rng.randf_range(2.0, 4.0)
	container.add_child(light)

func _add_sparking_wire(parent: Node2D, x: float, ceiling_y: float) -> void:
	var container := Node2D.new()
	container.name = "SparkingWire"
	container.position = Vector2(x, ceiling_y)
	parent.add_child(container)
	# Dangling wire
	var wire_len: float = _rng.randf_range(30, 80)
	var wire := Polygon2D.new()
	wire.z_index = 3
	wire.color = Color(0.06, 0.06, 0.06, 0.9)
	wire.polygon = PackedVector2Array([
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(3, wire_len * 0.4), Vector2(-2, wire_len * 0.7),
		Vector2(2, wire_len), Vector2(-1, wire_len)
	])
	container.add_child(wire)
	# Spark particles at wire tip
	var sparks := GPUParticles2D.new()
	sparks.name = "Sparks"
	sparks.z_index = 5
	sparks.amount = 3
	sparks.lifetime = 0.3
	sparks.speed_scale = 2.0
	sparks.randomness = 0.9
	sparks.position = Vector2(0, wire_len)
	var smat := ParticleProcessMaterial.new()
	smat.direction = Vector3(0, 1, 0)
	smat.spread = 120.0
	smat.initial_velocity_min = 20.0
	smat.initial_velocity_max = 60.0
	smat.gravity = Vector3(0, 80, 0)
	smat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	smat.scale_min = 0.2
	smat.scale_max = 0.6
	var sgrad := Gradient.new()
	sgrad.set_color(0, Color(1.0, 0.9, 0.4, 1.0))
	sgrad.add_point(0.4, Color(1.0, 0.6, 0.2, 0.8))
	sgrad.set_color(1, Color(0.8, 0.3, 0.1, 0.0))
	var sgtex := GradientTexture1D.new()
	sgtex.gradient = sgrad
	smat.color_ramp = sgtex
	sparks.process_material = smat
	container.add_child(sparks)
	# Small warm light at spark point
	var light := PointLight2D.new()
	light.color = Color(1.0, 0.7, 0.3, 1)
	light.energy = _rng.randf_range(0.2, 0.5)
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.position = Vector2(0, wire_len)
	light.texture = _get_light_tex_64()
	light.texture_scale = _rng.randf_range(1.5, 3.0)
	container.add_child(light)

func _add_glowing_fungus(parent: Node2D, x: float, floor_y: float) -> void:
	var container := Node2D.new()
	container.name = "GlowingFungus"
	container.position = Vector2(x, floor_y)
	parent.add_child(container)
	# 2-4 small mushroom caps
	var count: int = _rng.randi_range(2, 4)
	for i in range(count):
		var fx: float = _rng.randf_range(-15, 15)
		var cap := Polygon2D.new()
		cap.z_index = 3
		var g: float = _rng.randf_range(0.3, 0.6)
		cap.color = Color(0.1, g, 0.2, 0.7)
		var cw: float = _rng.randf_range(4, 10)
		var ch: float = _rng.randf_range(5, 12)
		cap.polygon = PackedVector2Array([
			Vector2(fx - cw, 0), Vector2(fx + cw, 0),
			Vector2(fx + cw * 0.5, -ch), Vector2(fx - cw * 0.5, -ch)
		])
		container.add_child(cap)
		# Tiny stem
		var stem := Polygon2D.new()
		stem.z_index = 2
		stem.color = Color(0.08, 0.15, 0.1, 0.8)
		stem.polygon = PackedVector2Array([
			Vector2(fx - 1.5, 0), Vector2(fx + 1.5, 0),
			Vector2(fx + 1, -ch + 2), Vector2(fx - 1, -ch + 2)
		])
		container.add_child(stem)
	# Soft green glow
	var light := PointLight2D.new()
	light.color = Color(0.2, 0.8, 0.3, 1)
	light.energy = _rng.randf_range(0.15, 0.35)
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.position = Vector2(0, -6)
	light.texture = _get_light_tex_64()
	light.texture_scale = _rng.randf_range(1.5, 3.0)
	container.add_child(light)

func _add_blinking_panel(parent: Node2D, x: float, y: float) -> void:
	var container := Node2D.new()
	container.name = "BlinkingPanel"
	container.position = Vector2(x, y)
	parent.add_child(container)
	# Small wall panel box
	var panel := Polygon2D.new()
	panel.z_index = 2
	panel.color = Color(0.07, 0.07, 0.08, 1)
	panel.polygon = PackedVector2Array([
		Vector2(-6, -5), Vector2(6, -5), Vector2(6, 5), Vector2(-6, 5)
	])
	container.add_child(panel)
	# LED dot
	var led := Polygon2D.new()
	led.z_index = 3
	var led_colors := [
		Color(0.1, 0.8, 0.2, 0.9),
		Color(0.9, 0.6, 0.1, 0.9),
		Color(0.8, 0.15, 0.1, 0.9),
		Color(0.2, 0.5, 0.9, 0.9)
	]
	led.color = led_colors[_rng.randi_range(0, 3)]
	led.polygon = PackedVector2Array([
		Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(1.5, 1.5), Vector2(-1.5, 1.5)
	])
	container.add_child(led)
	# Tiny glow from LED
	var light := PointLight2D.new()
	light.color = led.color
	light.energy = _rng.randf_range(0.1, 0.25)
	light.blend_mode = PointLight2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.texture = _get_light_tex_32()
	light.texture_scale = _rng.randf_range(0.8, 1.5)
	container.add_child(light)

func _add_toxic_vine(parent: Node2D, x: float, floor_y: float, height: float) -> void:
	var ToxicVineScript = preload("res://scenes/components/ToxicVine.gd")
	var vine := StaticBody2D.new()
	vine.set_script(ToxicVineScript)
	vine.name = "ToxicVine"
	vine.position = Vector2(x, floor_y)
	vine.vine_height = height
	vine.vine_width = _rng.randf_range(4, 8)
	parent.add_child(vine)

func _build_back_wall(parent: Node2D, index: int, floor_y: float, ceiling_y: float, is_shaft_floor: bool, shaft_x: float) -> void:
	var wall := Node2D.new()
	wall.name = "BackWall"
	wall.z_index = -5
	parent.add_child(wall)

	var half_w: float = room_half_width
	var half_t: float = floor_thickness * 0.5
	var inner_top: float = ceiling_y + half_t
	var inner_bot: float = floor_y - half_t
	var room_h: float = inner_bot - inner_top
	var right_limit: float = half_w if not is_shaft_floor else shaft_x

	# === SOLID DARK BACKDROP (blocks parallax from showing through wall holes) ===
	var backdrop := Polygon2D.new()
	backdrop.z_index = -8
	backdrop.color = Color(0.02, 0.02, 0.03, 1)
	backdrop.polygon = PackedVector2Array([
		Vector2(-half_w - 20, inner_top - 10), Vector2(right_limit + 20, inner_top - 10),
		Vector2(right_limit + 20, inner_bot + 10), Vector2(-half_w - 20, inner_bot + 10)
	])
	parent.add_child(backdrop)

	# === GENERATE IRREGULAR DECAY HOLES (2-4 per floor) ===
	var num_holes: int = _rng.randi_range(2, 4)
	# Each hole: center, radii, and irregular polygon points
	var hole_shapes: Array[Dictionary] = []
	for h in range(num_holes):
		var hcx: float = _rng.randf_range(-half_w + 200, right_limit - 200)
		var hcy: float = _rng.randf_range(inner_top + 50, inner_bot - 50)
		var hhw: float = _rng.randf_range(60, 150)
		var hhh: float = _rng.randf_range(40, room_h * 0.35)
		var num_pts: int = _rng.randi_range(8, 14)
		var pts := PackedVector2Array()
		for p in range(num_pts):
			var angle: float = float(p) / float(num_pts) * TAU
			var rx: float = hhw * (0.7 + _rng.randf_range(0.0, 0.5))
			var ry: float = hhh * (0.7 + _rng.randf_range(0.0, 0.5))
			var px: float = hcx + cos(angle) * rx + _rng.randf_range(-12, 12)
			var py: float = hcy + sin(angle) * ry + _rng.randf_range(-8, 8)
			px = clampf(px, -half_w + 30, right_limit - 30)
			py = clampf(py, inner_top + 10, inner_bot - 10)
			pts.append(Vector2(px, py))
		hole_shapes.append({"cx": hcx, "cy": hcy, "hw": hhw, "hh": hhh, "pts": pts})

	# === DRAW WALL AS TILES, SKIPPING TILES INSIDE HOLES ===
	var tile_w: float = 40.0
	var tile_h: float = 40.0
	var wall_b: float = _rng.randf_range(0.05, 0.07)
	var tx: float = -half_w
	while tx < right_limit:
		var ty: float = inner_top
		var tw: float = minf(tile_w, right_limit - tx)
		while ty < inner_bot:
			var th: float = minf(tile_h, inner_bot - ty)
			var tile_cx: float = tx + tw * 0.5
			var tile_cy: float = ty + th * 0.5
			# Check if tile center is inside any hole
			var in_hole: bool = false
			for hs in hole_shapes:
				if _point_in_polygon(Vector2(tile_cx, tile_cy), hs["pts"]):
					in_hole = true
					break
			if not in_hole:
				var tile := Polygon2D.new()
				var tb: float = wall_b + _rng.randf_range(-0.01, 0.01)
				tile.color = Color(tb, tb, tb * 1.1, 1)
				tile.polygon = PackedVector2Array([
					Vector2(tx, ty), Vector2(tx + tw, ty),
					Vector2(tx + tw, ty + th), Vector2(tx, ty + th)
				])
				wall.add_child(tile)
			ty += tile_h
		tx += tile_w

	# === EDGE DETAILS AROUND EACH HOLE ===
	for hs in hole_shapes:
		var pts: PackedVector2Array = hs["pts"]
		var num_pts: int = pts.size()

		# Crumbling concrete edge ring
		var edge_pts := PackedVector2Array()
		for p in range(num_pts):
			var angle2: float = float(p) / float(num_pts) * TAU
			var orig: Vector2 = pts[p]
			var edge_dist: float = _rng.randf_range(6, 18)
			edge_pts.append(Vector2(
				orig.x + cos(angle2) * edge_dist + _rng.randf_range(-4, 4),
				orig.y + sin(angle2) * edge_dist + _rng.randf_range(-3, 3)
			))
		# Draw edge segments (individual triangles for jagged look)
		for p in range(num_pts):
			var p2: int = (p + 1) % num_pts
			var edge_seg := Polygon2D.new()
			edge_seg.z_index = -4
			var eb2: float = _rng.randf_range(0.09, 0.14)
			edge_seg.color = Color(eb2, eb2 * 0.95, eb2 * 0.85, _rng.randf_range(0.7, 0.95))
			edge_seg.polygon = PackedVector2Array([
				edge_pts[p], edge_pts[p2], pts[p2], pts[p]
			])
			wall.add_child(edge_seg)

		# Rebar stubs poking inward from edges
		for r in range(_rng.randi_range(4, 8)):
			var rebar := Polygon2D.new()
			rebar.z_index = -3
			rebar.color = Color(
				_rng.randf_range(0.3, 0.5),
				_rng.randf_range(0.18, 0.28),
				_rng.randf_range(0.08, 0.15),
				_rng.randf_range(0.5, 0.85)
			)
			var pi2: int = _rng.randi_range(0, num_pts - 1)
			var edge_pt: Vector2 = pts[pi2]
			var angle4: float = float(pi2) / float(num_pts) * TAU
			var rlen: float = _rng.randf_range(15, 45)
			var rw: float = _rng.randf_range(1.5, 3.5)
			var inward_x: float = -cos(angle4)
			var inward_y: float = -sin(angle4)
			var perp_x: float = -inward_y
			var perp_y: float = inward_x
			var tip: Vector2 = edge_pt + Vector2(inward_x * rlen, inward_y * rlen)
			rebar.polygon = PackedVector2Array([
				edge_pt + Vector2(perp_x * rw, perp_y * rw),
				tip + Vector2(perp_x * rw * 0.3, perp_y * rw * 0.3),
				tip - Vector2(perp_x * rw * 0.3, perp_y * rw * 0.3),
				edge_pt - Vector2(perp_x * rw, perp_y * rw)
			])
			wall.add_child(rebar)

		# Concrete chunks scattered near hole edges
		for c in range(_rng.randi_range(3, 6)):
			var ci: int = _rng.randi_range(0, num_pts - 1)
			var chunk_base: Vector2 = edge_pts[ci]
			var chunk := Polygon2D.new()
			chunk.z_index = -3
			var cb2: float = _rng.randf_range(0.08, 0.14)
			chunk.color = Color(cb2, cb2 * 0.95, cb2 * 0.88, _rng.randf_range(0.5, 0.85))
			var cw2: float = _rng.randf_range(6, 20)
			var ch3: float = _rng.randf_range(5, 14)
			chunk.polygon = PackedVector2Array([
				chunk_base + Vector2(_rng.randf_range(-3, 3), -ch3),
				chunk_base + Vector2(cw2 + _rng.randf_range(-4, 4), -ch3 + _rng.randf_range(-3, 5)),
				chunk_base + Vector2(cw2 + _rng.randf_range(-2, 2), _rng.randf_range(-2, 3)),
				chunk_base + Vector2(_rng.randf_range(-4, 2), _rng.randf_range(-1, 4))
			])
			wall.add_child(chunk)

	# === STRUCTURAL PILLARS (some broken/partial) ===
	var pillar_xs: Array[float] = [-660.0, -410.0, -160.0, 160.0, 410.0, 660.0]
	for px in pillar_xs:
		if is_shaft_floor and px > shaft_x - 100:
			continue
		# Check if pillar overlaps a hole — if so, make it partial
		var pillar_broken: bool = false
		for hs2 in hole_shapes:
			if px > hs2["cx"] - hs2["hw"] - 20 and px < hs2["cx"] + hs2["hw"] + 20:
				pillar_broken = true
				break
		if pillar_broken and _rng.randf() < 0.5:
			continue  # Skip some pillars in broken areas
		var pillar := Polygon2D.new()
		pillar.z_index = -3
		pillar.color = Color(0.065, 0.065, 0.075, 1)
		var p_top: float = inner_top
		var p_bot: float = inner_bot
		if pillar_broken:
			# Partial pillar — only top or bottom portion
			if _rng.randf() < 0.5:
				p_bot = inner_top + room_h * _rng.randf_range(0.2, 0.5)
			else:
				p_top = inner_bot - room_h * _rng.randf_range(0.2, 0.5)
		pillar.polygon = PackedVector2Array([
			Vector2(px, p_top), Vector2(px + 18, p_top),
			Vector2(px + 18, p_bot), Vector2(px, p_bot)
		])
		parent.add_child(pillar)

	# === THICK HANGING VINES (organic, growing through holes and walls) ===
	var num_vines: int = _rng.randi_range(3, 7)
	for v in range(num_vines):
		var vx: float = _rng.randf_range(-half_w + 80, right_limit - 80)
		var vine_len: float = _rng.randf_range(room_h * 0.3, room_h * 1.2)
		var vine_w: float = _rng.randf_range(3, 10)
		var vine_start_y: float = inner_top - _rng.randf_range(0, 15)
		# Main vine stem — wavy
		var vine_pts: PackedVector2Array = PackedVector2Array()
		var vine_pts_r: PackedVector2Array = PackedVector2Array()
		var segs: int = _rng.randi_range(6, 12)
		var seg_h: float = vine_len / float(segs)
		var cx: float = vx
		for s in range(segs + 1):
			var sy: float = vine_start_y + float(s) * seg_h
			if sy > inner_bot + 20:
				sy = inner_bot + 20
			vine_pts.append(Vector2(cx - vine_w * 0.5, sy))
			vine_pts_r.insert(0, Vector2(cx + vine_w * 0.5, sy))
			cx += _rng.randf_range(-12, 12)
		var all_pts: PackedVector2Array = PackedVector2Array()
		all_pts.append_array(vine_pts)
		all_pts.append_array(vine_pts_r)
		var vine_stem := Polygon2D.new()
		vine_stem.z_index = 3
		var vg: float = _rng.randf_range(0.12, 0.22)
		vine_stem.color = Color(vg * 0.3, vg, vg * 0.4, _rng.randf_range(0.6, 0.9))
		vine_stem.polygon = all_pts
		parent.add_child(vine_stem)

		# Leaves along the vine
		var leaf_count: int = _rng.randi_range(4, 10)
		for l in range(leaf_count):
			var lt: float = _rng.randf_range(0.1, 0.9)
			var li: int = clampi(int(lt * float(segs)), 0, segs)
			var lx: float = vine_pts[li].x + _rng.randf_range(-8, 8)
			var ly: float = vine_pts[li].y + _rng.randf_range(-5, 5)
			var leaf := Polygon2D.new()
			leaf.z_index = 3
			var lg: float = _rng.randf_range(0.15, 0.35)
			leaf.color = Color(lg * 0.4, lg, lg * 0.5, _rng.randf_range(0.5, 0.8))
			var lw: float = _rng.randf_range(6, 18)
			var lh: float = _rng.randf_range(4, 12)
			var side_dir: float = 1.0 if _rng.randf() < 0.5 else -1.0
			leaf.polygon = PackedVector2Array([
				Vector2(lx, ly),
				Vector2(lx + side_dir * lw, ly + lh * 0.3),
				Vector2(lx + side_dir * lw * 0.7, ly + lh),
				Vector2(lx - side_dir * 3, ly + lh * 0.6)
			])
			parent.add_child(leaf)

	# === EXPOSED PIPES ===
	if _rng.randf() < 0.5:
		var pipe_x: float = _rng.randf_range(-half_w + 60, right_limit - 60)
		var pipe := Polygon2D.new()
		pipe.z_index = -2
		pipe.color = Color(0.12, 0.1, 0.08, _rng.randf_range(0.5, 0.8))
		pipe.polygon = PackedVector2Array([
			Vector2(pipe_x, inner_top + 5), Vector2(pipe_x + 5, inner_top + 5),
			Vector2(pipe_x + 5, inner_bot - 5), Vector2(pipe_x, inner_bot - 5)
		])
		parent.add_child(pipe)

	# === HANGING WIRES ===
	for w in range(_rng.randi_range(1, 3)):
		var wire_x: float = _rng.randf_range(-half_w + 80, right_limit - 80)
		var wire := Polygon2D.new()
		wire.z_index = 2
		wire.color = Color(0.04, 0.04, 0.05, _rng.randf_range(0.4, 0.7))
		var sag: float = _rng.randf_range(30, 100)
		var mid_x: float = wire_x + _rng.randf_range(-20, 20)
		wire.polygon = PackedVector2Array([
			Vector2(wire_x, inner_top), Vector2(wire_x + 2, inner_top),
			Vector2(mid_x + 2, inner_top + sag),
			Vector2(mid_x, inner_top + sag)
		])
		parent.add_child(wire)

	# === CRACKS on remaining wall ===
	for i in range(_rng.randi_range(2, 5)):
		var crack_x: float = _rng.randf_range(-half_w + 80, right_limit - 80)
		var crack_y: float = _rng.randf_range(inner_top + 20, inner_bot - 40)
		_add_wall_crack(parent, crack_x, crack_y, _rng.randf_range(30, 90))

	# === HIDDEN DETAILS (only visible under cursor reveal light, layer 2) ===
	_add_hidden_details(parent, inner_top, inner_bot, -half_w, right_limit, index)

func _add_hidden_details(parent: Node2D, top_y: float, bot_y: float, left_x: float, right_x: float, floor_idx: int) -> void:
	var detail_count: int = _rng.randi_range(2, 5)
	for _d in range(detail_count):
		var dx: float = _rng.randf_range(left_x + 40, right_x - 40)
		var dy: float = _rng.randf_range(top_y + 20, bot_y - 20)
		var dtype: int = _rng.randi_range(0, 4)

		match dtype:
			0:  # Scratched tally marks
				for t in range(_rng.randi_range(3, 7)):
					var mark := Polygon2D.new()
					mark.z_index = -4
					mark.visibility_layer = 2
					mark.color = Color(0.4, 0.35, 0.3, 0.6)
					var mx: float = dx + float(t) * 8.0
					var mh: float = _rng.randf_range(15, 30)
					mark.polygon = PackedVector2Array([
						Vector2(mx, dy), Vector2(mx + 2, dy),
						Vector2(mx + 2 + _rng.randf_range(-2, 2), dy + mh),
						Vector2(mx + _rng.randf_range(-2, 2), dy + mh)
					])
					parent.add_child(mark)
				# Diagonal cross every 5
				if _rng.randf() < 0.6:
					var cross := Polygon2D.new()
					cross.z_index = -4
					cross.visibility_layer = 2
					cross.color = Color(0.4, 0.35, 0.3, 0.5)
					cross.polygon = PackedVector2Array([
						Vector2(dx - 2, dy - 2), Vector2(dx + 38, dy + 25),
						Vector2(dx + 36, dy + 27), Vector2(dx - 4, dy)
					])
					parent.add_child(cross)

			1:  # Old bloodstain / dark splatter
				var splat_pts := PackedVector2Array()
				var num_sp: int = _rng.randi_range(5, 8)
				for p in range(num_sp):
					var angle: float = float(p) / float(num_sp) * TAU
					var sr: float = _rng.randf_range(8, 25)
					splat_pts.append(Vector2(
						dx + cos(angle) * sr + _rng.randf_range(-4, 4),
						dy + sin(angle) * sr + _rng.randf_range(-3, 3)
					))
				var splat := Polygon2D.new()
				splat.z_index = -4
				splat.visibility_layer = 2
				splat.color = Color(0.3, 0.08, 0.05, 0.5)
				splat.polygon = splat_pts
				parent.add_child(splat)
				# Drip trail
				if _rng.randf() < 0.5:
					var drip := Polygon2D.new()
					drip.z_index = -4
					drip.visibility_layer = 2
					drip.color = Color(0.25, 0.06, 0.04, 0.4)
					var drip_len: float = _rng.randf_range(20, 60)
					drip.polygon = PackedVector2Array([
						Vector2(dx - 2, dy + 10), Vector2(dx + 2, dy + 10),
						Vector2(dx + 1, dy + 10 + drip_len), Vector2(dx - 1, dy + 10 + drip_len)
					])
					parent.add_child(drip)

			2:  # Mysterious symbol / circle with lines
				var sym := Node2D.new()
				sym.name = "HiddenSymbol"
				parent.add_child(sym)
				# Outer circle (polygon approximation)
				var circle_pts := PackedVector2Array()
				var crad: float = _rng.randf_range(12, 25)
				for p in range(12):
					var angle: float = float(p) / 12.0 * TAU
					circle_pts.append(Vector2(dx + cos(angle) * crad, dy + sin(angle) * crad))
				# Draw as segments
				for p in range(12):
					var p2: int = (p + 1) % 12
					var seg := Polygon2D.new()
					seg.z_index = -4
					seg.visibility_layer = 2
					seg.color = Color(0.5, 0.4, 0.15, 0.5)
					var n1: Vector2 = circle_pts[p]
					var n2: Vector2 = circle_pts[p2]
					var perp := (n2 - n1).normalized().rotated(PI * 0.5) * 1.5
					seg.polygon = PackedVector2Array([n1 + perp, n2 + perp, n2 - perp, n1 - perp])
					sym.add_child(seg)
				# Cross lines through center
				for _l in range(_rng.randi_range(1, 3)):
					var la: float = _rng.randf_range(0, PI)
					var line := Polygon2D.new()
					line.z_index = -4
					line.visibility_layer = 2
					line.color = Color(0.5, 0.4, 0.15, 0.4)
					line.polygon = PackedVector2Array([
						Vector2(dx + cos(la) * crad * 0.8 - 1, dy + sin(la) * crad * 0.8),
						Vector2(dx - cos(la) * crad * 0.8 - 1, dy - sin(la) * crad * 0.8),
						Vector2(dx - cos(la) * crad * 0.8 + 1, dy - sin(la) * crad * 0.8),
						Vector2(dx + cos(la) * crad * 0.8 + 1, dy + sin(la) * crad * 0.8)
					])
					sym.add_child(line)

			3:  # Faded handprint
				var hand := Polygon2D.new()
				hand.z_index = -4
				hand.visibility_layer = 2
				hand.color = Color(0.3, 0.1, 0.08, 0.35)
				var hw2: float = _rng.randf_range(10, 18)
				var hh2: float = hw2 * 1.3
				hand.polygon = PackedVector2Array([
					Vector2(dx - hw2, dy), Vector2(dx + hw2, dy),
					Vector2(dx + hw2 * 0.8, dy + hh2), Vector2(dx - hw2 * 0.8, dy + hh2)
				])
				parent.add_child(hand)
				# Finger marks
				for f in range(4):
					var finger := Polygon2D.new()
					finger.z_index = -4
					finger.visibility_layer = 2
					finger.color = Color(0.3, 0.1, 0.08, 0.25)
					var fx: float = dx - hw2 * 0.6 + float(f) * hw2 * 0.4
					finger.polygon = PackedVector2Array([
						Vector2(fx - 3, dy - 2), Vector2(fx + 3, dy - 2),
						Vector2(fx + 2, dy - 12 - _rng.randf_range(0, 6)),
						Vector2(fx - 2, dy - 12 - _rng.randf_range(0, 6))
					])
					parent.add_child(finger)

			4:  # Scratched arrow / directional marking
				var arrow := Node2D.new()
				arrow.name = "HiddenArrow"
				parent.add_child(arrow)
				var adir: float = _rng.randf_range(-0.5, 0.5)  # Mostly pointing down
				var alen: float = _rng.randf_range(25, 50)
				# Shaft
				var shaft_p := Polygon2D.new()
				shaft_p.z_index = -4
				shaft_p.visibility_layer = 2
				shaft_p.color = Color(0.45, 0.4, 0.3, 0.5)
				shaft_p.polygon = PackedVector2Array([
					Vector2(dx - 2, dy), Vector2(dx + 2, dy),
					Vector2(dx + cos(adir) * 2 + 2, dy + alen),
					Vector2(dx + cos(adir) * 2 - 2, dy + alen)
				])
				arrow.add_child(shaft_p)
				# Arrowhead
				var ah := Polygon2D.new()
				ah.z_index = -4
				ah.visibility_layer = 2
				ah.color = Color(0.45, 0.4, 0.3, 0.5)
				var tip_y: float = dy + alen + 10
				ah.polygon = PackedVector2Array([
					Vector2(dx - 10, dy + alen - 3),
					Vector2(dx + cos(adir) * 2, tip_y),
					Vector2(dx + 10, dy + alen - 3)
				])
				arrow.add_child(ah)

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var n: int = polygon.size()
	if n < 3:
		return false
	var inside: bool = false
	var j: int = n - 1
	for i in range(n):
		var pi: Vector2 = polygon[i]
		var pj: Vector2 = polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and \
			(point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside

func _add_wall_crack(parent: Node2D, x: float, y: float, length: float) -> void:
	var segs: int = _rng.randi_range(3, 6)
	var seg_len: float = length / float(segs)
	var cx: float = x
	var cy: float = y
	var angle: float = _rng.randf_range(-0.6, 0.6) + PI * 0.5
	for i in range(segs):
		var nx: float = cx + cos(angle) * seg_len + _rng.randf_range(-3, 3)
		var ny: float = cy + sin(angle) * seg_len + _rng.randf_range(-2, 2)
		var w: float = _rng.randf_range(0.8, 2.5) * (1.0 - float(i) / float(segs) * 0.4)
		var crack := Polygon2D.new()
		crack.z_index = -4
		crack.color = Color(0.04, 0.04, 0.05, _rng.randf_range(0.3, 0.6))
		crack.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.7, ny), Vector2(nx - w * 0.7, ny)
		])
		parent.add_child(crack)
		angle += _rng.randf_range(-0.4, 0.4)
		cx = nx
		cy = ny

func _make_window_frame(cx: float, top: float, bot: float, half_w: float, fw: float) -> Array[Polygon2D]:
	var frames: Array[Polygon2D] = []
	# Top edge
	var ft := Polygon2D.new()
	ft.polygon = PackedVector2Array([
		Vector2(cx - half_w - fw, top - fw), Vector2(cx + half_w + fw, top - fw),
		Vector2(cx + half_w + fw, top), Vector2(cx - half_w - fw, top)
	])
	frames.append(ft)
	# Bottom edge
	var fb := Polygon2D.new()
	fb.polygon = PackedVector2Array([
		Vector2(cx - half_w - fw, bot), Vector2(cx + half_w + fw, bot),
		Vector2(cx + half_w + fw, bot + fw), Vector2(cx - half_w - fw, bot + fw)
	])
	frames.append(fb)
	# Left edge
	var fl := Polygon2D.new()
	fl.polygon = PackedVector2Array([
		Vector2(cx - half_w - fw, top), Vector2(cx - half_w, top),
		Vector2(cx - half_w, bot), Vector2(cx - half_w - fw, bot)
	])
	frames.append(fl)
	# Right edge
	var fr := Polygon2D.new()
	fr.polygon = PackedVector2Array([
		Vector2(cx + half_w, top), Vector2(cx + half_w + fw, top),
		Vector2(cx + half_w + fw, bot), Vector2(cx + half_w, bot)
	])
	frames.append(fr)
	return frames

func _make_floor_number(index: int, y: float, x: float) -> Polygon2D:
	# Simple visual floor indicator: a small colored square
	var indicator := Polygon2D.new()
	indicator.z_index = -3
	var t: float = float(index) / float(floor_count - 1)
	# Gradient from warm (top) to cool (bottom)
	indicator.color = Color(0.3 - t * 0.15, 0.15 + t * 0.1, 0.1 + t * 0.15, 0.4)
	indicator.polygon = PackedVector2Array([
		Vector2(x, y), Vector2(x + 20, y),
		Vector2(x + 20, y + 20), Vector2(x, y + 20)
	])
	return indicator

func _build_window_backdrop(parent: Node2D, index: int, floor_y: float, ceiling_y: float) -> void:
	# Muted dusk cityscape visible through windows. Dark, atmospheric.
	var backdrop := Node2D.new()
	backdrop.name = "CityBackdrop"
	backdrop.z_index = -8
	parent.add_child(backdrop)

	var half_w: float = room_half_width
	var half_t: float = floor_thickness * 0.5
	var inner_top: float = ceiling_y + half_t
	var inner_bot: float = floor_y - half_t
	var h: float = inner_bot - inner_top
	var depth: float = float(index) / float(floor_count - 1)

	# === DUSK SKY (visible, warm tones) ===
	var sky_h: float = h * (0.6 - depth * 0.3)
	if sky_h > 8:
		var sky_upper := Polygon2D.new()
		sky_upper.color = Color(0.25 - depth * 0.08, 0.2 - depth * 0.06, 0.32 - depth * 0.08, 1)
		sky_upper.polygon = PackedVector2Array([
			Vector2(-half_w, inner_top), Vector2(half_w, inner_top),
			Vector2(half_w, inner_top + sky_h * 0.4), Vector2(-half_w, inner_top + sky_h * 0.4)
		])
		backdrop.add_child(sky_upper)

		var sky_lower := Polygon2D.new()
		sky_lower.color = Color(0.35 - depth * 0.12, 0.25 - depth * 0.08, 0.18 - depth * 0.06, 1)
		sky_lower.polygon = PackedVector2Array([
			Vector2(-half_w, inner_top + sky_h * 0.4), Vector2(half_w, inner_top + sky_h * 0.4),
			Vector2(half_w, inner_top + sky_h), Vector2(-half_w, inner_top + sky_h)
		])
		backdrop.add_child(sky_lower)
	else:
		sky_h = 0

	# === OPPOSITE BUILDINGS (dark silhouettes) ===
	var bldg_zone_top: float = inner_top + sky_h * 0.2
	var street_y: float = inner_bot - 15

	var bx: float = -half_w
	while bx < half_w:
		var bw: float = _rng.randf_range(100.0, 250.0)
		var bt: float = bldg_zone_top + _rng.randf_range(-20, 30) - depth * 30
		bt = maxf(bt, inner_top)

		# Building body — visible silhouettes
		var bb: float = _rng.randf_range(0.1, 0.16)
		var bldg := Polygon2D.new()
		bldg.color = Color(bb, bb * 0.95, bb * 1.1, 1)
		bldg.polygon = PackedVector2Array([
			Vector2(bx, bt), Vector2(bx + bw - 3, bt),
			Vector2(bx + bw - 3, street_y), Vector2(bx, street_y)
		])
		backdrop.add_child(bldg)

		# Rooftop edge
		var roof_edge := Polygon2D.new()
		roof_edge.color = Color(bb + 0.03, bb + 0.02, bb + 0.02, 1)
		roof_edge.polygon = PackedVector2Array([
			Vector2(bx, bt), Vector2(bx + bw - 3, bt),
			Vector2(bx + bw - 3, bt + 3), Vector2(bx, bt + 3)
		])
		backdrop.add_child(roof_edge)

		# Windows — small, mostly dark, rare warm glow
		var wy: float = bt + 12
		while wy < street_y - 15:
			var wx: float = bx + 8
			while wx < bx + bw - 15:
				if _rng.randf() < 0.6:
					var owin := Polygon2D.new()
					if _rng.randf() < 0.3:
						# Warm lit window
						owin.color = Color(0.55, 0.45, 0.25, _rng.randf_range(0.4, 0.75))
					else:
						# Dark window
						owin.color = Color(0.06, 0.06, 0.08, _rng.randf_range(0.3, 0.6))
					owin.polygon = PackedVector2Array([
						Vector2(wx, wy), Vector2(wx + 8, wy),
						Vector2(wx + 8, wy + 10), Vector2(wx, wy + 10)
					])
					backdrop.add_child(owin)
				wx += _rng.randf_range(14, 24)
			wy += _rng.randf_range(16, 26)

		bx += bw + _rng.randf_range(1, 6)

	# === STREET LEVEL ===
	var sidewalk := Polygon2D.new()
	sidewalk.color = Color(0.1, 0.1, 0.09, 1)
	sidewalk.polygon = PackedVector2Array([
		Vector2(-half_w, street_y), Vector2(half_w, street_y),
		Vector2(half_w, street_y + 6), Vector2(-half_w, street_y + 6)
	])
	backdrop.add_child(sidewalk)

	var street := Polygon2D.new()
	street.color = Color(0.05, 0.05, 0.06, 1)
	street.polygon = PackedVector2Array([
		Vector2(-half_w, street_y + 6), Vector2(half_w, street_y + 6),
		Vector2(half_w, inner_bot), Vector2(-half_w, inner_bot)
	])
	backdrop.add_child(street)


	# === ATMOSPHERIC HAZE (subtle fog) ===
	var haze := Polygon2D.new()
	var haze_alpha: float = 0.03 + depth * 0.04
	haze.color = Color(0.08, 0.08, 0.1, haze_alpha)
	haze.polygon = PackedVector2Array([
		Vector2(-half_w, inner_top), Vector2(half_w, inner_top),
		Vector2(half_w, inner_bot), Vector2(-half_w, inner_bot)
	])
	backdrop.add_child(haze)

func _add_lobby_decay(parent: Node2D, floor_y: float, ceiling_y: float) -> void:
	var decay := Node2D.new()
	decay.name = "LobbyDecay"
	decay.z_index = 1
	parent.add_child(decay)

	var half_w: float = room_half_width
	var half_t: float = floor_thickness * 0.5
	var inner_top: float = ceiling_y + half_t
	var inner_bot: float = floor_y - half_t
	var room_h: float = inner_bot - inner_top

	# === RECEPTION DESK (right-center area) ===
	var desk_x: float = 200.0
	var desk_w: float = 250.0
	var desk_h: float = 55.0
	var desk_top: float = inner_bot - desk_h
	# Desk front face
	var desk_front := Polygon2D.new()
	desk_front.z_index = 2
	desk_front.color = Color(0.12, 0.09, 0.06, 0.9)
	desk_front.polygon = PackedVector2Array([
		Vector2(desk_x, desk_top), Vector2(desk_x + desk_w, desk_top),
		Vector2(desk_x + desk_w, inner_bot), Vector2(desk_x, inner_bot)
	])
	decay.add_child(desk_front)
	# Desk top surface
	var desk_surface := Polygon2D.new()
	desk_surface.z_index = 2
	desk_surface.color = Color(0.15, 0.12, 0.08, 0.9)
	desk_surface.polygon = PackedVector2Array([
		Vector2(desk_x - 5, desk_top - 4), Vector2(desk_x + desk_w + 5, desk_top - 4),
		Vector2(desk_x + desk_w + 5, desk_top), Vector2(desk_x - 5, desk_top)
	])
	decay.add_child(desk_surface)
	# Desk side panel (depth)
	var desk_side := Polygon2D.new()
	desk_side.z_index = 2
	desk_side.color = Color(0.09, 0.07, 0.05, 0.85)
	desk_side.polygon = PackedVector2Array([
		Vector2(desk_x + desk_w, desk_top), Vector2(desk_x + desk_w + 8, desk_top + 3),
		Vector2(desk_x + desk_w + 8, inner_bot), Vector2(desk_x + desk_w, inner_bot)
	])
	decay.add_child(desk_side)
	# Items on desk (scattered papers, monitor)
	var monitor := Polygon2D.new()
	monitor.z_index = 3
	monitor.color = Color(0.06, 0.06, 0.08, 0.8)
	monitor.polygon = PackedVector2Array([
		Vector2(desk_x + 30, desk_top - 35), Vector2(desk_x + 80, desk_top - 35),
		Vector2(desk_x + 80, desk_top - 4), Vector2(desk_x + 30, desk_top - 4)
	])
	decay.add_child(monitor)
	# Monitor screen (cracked, faint glow)
	var screen := Polygon2D.new()
	screen.z_index = 3
	screen.color = Color(0.08, 0.15, 0.12, 0.4)
	screen.polygon = PackedVector2Array([
		Vector2(desk_x + 33, desk_top - 32), Vector2(desk_x + 77, desk_top - 32),
		Vector2(desk_x + 77, desk_top - 7), Vector2(desk_x + 33, desk_top - 7)
	])
	decay.add_child(screen)
	# Monitor stand
	var stand := Polygon2D.new()
	stand.z_index = 3
	stand.color = Color(0.05, 0.05, 0.06, 0.7)
	stand.polygon = PackedVector2Array([
		Vector2(desk_x + 48, desk_top - 4), Vector2(desk_x + 62, desk_top - 4),
		Vector2(desk_x + 65, desk_top), Vector2(desk_x + 45, desk_top)
	])
	decay.add_child(stand)
	# Scattered papers on desk
	for i in range(4):
		var paper := Polygon2D.new()
		paper.z_index = 3
		paper.color = Color(0.2, 0.19, 0.17, _rng.randf_range(0.3, 0.6))
		var px: float = desk_x + _rng.randf_range(90, desk_w - 10)
		var pw: float = _rng.randf_range(12, 25)
		var ph: float = _rng.randf_range(8, 16)
		var tilt: float = _rng.randf_range(-3, 3)
		paper.polygon = PackedVector2Array([
			Vector2(px, desk_top - ph + tilt), Vector2(px + pw, desk_top - ph - tilt),
			Vector2(px + pw, desk_top - tilt), Vector2(px, desk_top + tilt)
		])
		decay.add_child(paper)

	# === DOOR FRAMES on right wall ===
	var door_positions: Array[float] = [550.0, 750.0]
	for dx in door_positions:
		var dw: float = 65.0
		var dh: float = room_h * 0.75
		var door_top: float = inner_bot - dh
		# Door frame
		var frame_color := Color(0.08, 0.07, 0.06, 0.9)
		# Left jamb
		var lj := Polygon2D.new()
		lj.z_index = 0
		lj.color = frame_color
		lj.polygon = PackedVector2Array([
			Vector2(dx - 5, door_top - 5), Vector2(dx, door_top - 5),
			Vector2(dx, inner_bot), Vector2(dx - 5, inner_bot)
		])
		decay.add_child(lj)
		# Right jamb
		var rj := Polygon2D.new()
		rj.z_index = 0
		rj.color = frame_color
		rj.polygon = PackedVector2Array([
			Vector2(dx + dw, door_top - 5), Vector2(dx + dw + 5, door_top - 5),
			Vector2(dx + dw + 5, inner_bot), Vector2(dx + dw, inner_bot)
		])
		decay.add_child(rj)
		# Top header
		var header := Polygon2D.new()
		header.z_index = 0
		header.color = frame_color
		header.polygon = PackedVector2Array([
			Vector2(dx - 5, door_top - 10), Vector2(dx + dw + 5, door_top - 10),
			Vector2(dx + dw + 5, door_top), Vector2(dx - 5, door_top)
		])
		decay.add_child(header)
		# Dark interior (hallway behind door)
		var interior := Polygon2D.new()
		interior.z_index = -6
		interior.color = Color(0.02, 0.02, 0.03, 0.9)
		interior.polygon = PackedVector2Array([
			Vector2(dx, door_top), Vector2(dx + dw, door_top),
			Vector2(dx + dw, inner_bot), Vector2(dx, inner_bot)
		])
		decay.add_child(interior)

	# === FALLEN CHAIRS (scattered around lobby) ===
	for i in range(3):
		var cx: float = _rng.randf_range(-200, 500)
		var cy: float = inner_bot
		# Chair seat (tilted)
		var chair := Polygon2D.new()
		chair.z_index = 2
		var tilt2: float = _rng.randf_range(-15, 15)
		chair.color = Color(0.08, 0.07, 0.06, _rng.randf_range(0.5, 0.75))
		var cw: float = _rng.randf_range(25, 40)
		var ch: float = _rng.randf_range(20, 35)
		chair.polygon = PackedVector2Array([
			Vector2(cx, cy - ch + tilt2), Vector2(cx + cw, cy - ch - tilt2),
			Vector2(cx + cw + 2, cy - ch - tilt2 + 4), Vector2(cx - 2, cy - ch + tilt2 + 4)
		])
		decay.add_child(chair)
		# Chair leg
		var cleg := Polygon2D.new()
		cleg.z_index = 2
		cleg.color = Color(0.06, 0.06, 0.07, 0.6)
		cleg.polygon = PackedVector2Array([
			Vector2(cx + 3, cy - ch + tilt2 + 4), Vector2(cx + 6, cy - ch + tilt2 + 4),
			Vector2(cx + 6, cy), Vector2(cx + 3, cy)
		])
		decay.add_child(cleg)

	# === SCATTERED PAPERS on floor ===
	for i in range(8):
		var paper := Polygon2D.new()
		paper.z_index = 1
		paper.color = Color(0.18, 0.17, 0.15, _rng.randf_range(0.2, 0.5))
		var px: float = _rng.randf_range(-half_w + 100, half_w - 100)
		var pw: float = _rng.randf_range(10, 22)
		var ph: float = _rng.randf_range(6, 14)
		paper.polygon = PackedVector2Array([
			Vector2(px, inner_bot - ph - _rng.randf_range(0, 3)),
			Vector2(px + pw, inner_bot - ph + _rng.randf_range(-2, 2)),
			Vector2(px + pw + _rng.randf_range(-3, 3), inner_bot),
			Vector2(px - _rng.randf_range(0, 3), inner_bot)
		])
		decay.add_child(paper)

	# === DEBRIS PILES ===
	for i in range(5):
		var dx2: float = _rng.randf_range(-half_w + 80, half_w - 80)
		_add_debris_pile(decay, dx2, inner_bot)

	# === CEILING DAMAGE (fallen chunks, exposed beams) ===
	for i in range(3):
		var bx: float = _rng.randf_range(-half_w + 100, half_w - 200)
		var beam := Polygon2D.new()
		beam.z_index = 2
		beam.color = Color(0.1, 0.09, 0.07, _rng.randf_range(0.4, 0.7))
		var bw: float = _rng.randf_range(80, 200)
		beam.polygon = PackedVector2Array([
			Vector2(bx, inner_top), Vector2(bx + bw, inner_top),
			Vector2(bx + bw, inner_top + 6), Vector2(bx, inner_top + 6)
		])
		decay.add_child(beam)

	# === WATER STAINS ===
	for i in range(4):
		var sx: float = _rng.randf_range(-half_w + 30, half_w - 30)
		var sy: float = _rng.randf_range(inner_top + 10, inner_top + 60)
		var sw: float = _rng.randf_range(15, 50)
		var sh: float = _rng.randf_range(30, 100)
		var stain := Polygon2D.new()
		stain.z_index = -2
		stain.color = Color(0.06, 0.08, 0.1, _rng.randf_range(0.08, 0.2))
		stain.polygon = PackedVector2Array([
			Vector2(sx, sy), Vector2(sx + sw, sy),
			Vector2(sx + sw * 0.6, sy + sh), Vector2(sx + sw * 0.3, sy + sh)
		])
		decay.add_child(stain)

func _add_debris_pile(parent: Node2D, x: float, y: float) -> void:
	var count: int = _rng.randi_range(3, 6)
	for i in range(count):
		var piece := Polygon2D.new()
		var b: float = _rng.randf_range(0.1, 0.18)
		piece.color = Color(b, b * _rng.randf_range(0.85, 1.0), b * _rng.randf_range(0.75, 0.95), _rng.randf_range(0.5, 0.85))
		var px: float = x + _rng.randf_range(-25, 25)
		var pw: float = _rng.randf_range(6, 20)
		var ph: float = _rng.randf_range(4, 14)
		piece.polygon = PackedVector2Array([
			Vector2(px, y - ph),
			Vector2(px + pw * 0.4, y - ph - _rng.randf_range(0, 4)),
			Vector2(px + pw, y - ph + _rng.randf_range(0, 3)),
			Vector2(px + pw + _rng.randf_range(-2, 2), y),
			Vector2(px - _rng.randf_range(0, 3), y)
		])
		parent.add_child(piece)

func _add_broken_furniture(parent: Node2D, x: float, y: float) -> void:
	# Desk shape (toppled)
	var desk := Polygon2D.new()
	desk.color = Color(0.1, 0.08, 0.06, _rng.randf_range(0.5, 0.75))
	var dw: float = _rng.randf_range(40, 70)
	var dh: float = _rng.randf_range(15, 25)
	var tilt: float = _rng.randf_range(-8, 8)
	desk.polygon = PackedVector2Array([
		Vector2(x, y - dh + tilt),
		Vector2(x + dw, y - dh - tilt),
		Vector2(x + dw, y - dh - tilt + 4),
		Vector2(x, y - dh + tilt + 4)
	])
	parent.add_child(desk)
	# Desk leg
	var leg := Polygon2D.new()
	leg.color = Color(0.08, 0.07, 0.05, 0.6)
	leg.polygon = PackedVector2Array([
		Vector2(x + 4, y - dh + tilt + 4),
		Vector2(x + 8, y - dh + tilt + 4),
		Vector2(x + 8, y),
		Vector2(x + 4, y)
	])
	parent.add_child(leg)
	# Another leg
	var leg2 := Polygon2D.new()
	leg2.color = Color(0.08, 0.07, 0.05, 0.5)
	leg2.polygon = PackedVector2Array([
		Vector2(x + dw - 8, y - dh - tilt + 4),
		Vector2(x + dw - 4, y - dh - tilt + 4),
		Vector2(x + dw - 2, y),
		Vector2(x + dw - 10, y)
	])
	parent.add_child(leg2)

func _build_elevator_shaft(parent: Node2D, shaft_x: float) -> void:
	var shaft := Node2D.new()
	shaft.name = "ElevatorShaft"
	parent.add_child(shaft)

	var sl: float = shaft_x  # shaft left
	var sr: float = shaft_x + elevator_shaft_width  # shaft right
	var sc: float = (sl + sr) * 0.5  # shaft center
	var sw: float = elevator_shaft_width

	# Shaft spans floors 5-9
	var shaft_top_y: float = base_y + 5.0 * floor_height - floor_height + floor_thickness
	var shaft_bot_y: float = base_y + float(floor_count - 1) * floor_height - floor_thickness * 0.5

	# ---- BACK WALL: dark concrete with panel seams ----
	var bg := Polygon2D.new()
	bg.z_index = -8
	bg.color = Color(0.035, 0.035, 0.045, 1)
	bg.polygon = PackedVector2Array([
		Vector2(sl, shaft_top_y), Vector2(sr, shaft_top_y),
		Vector2(sr, shaft_bot_y), Vector2(sl, shaft_bot_y)
	])
	shaft.add_child(bg)

	# Concrete panel seams (horizontal)
	var seam_y: float = shaft_top_y + 60
	while seam_y < shaft_bot_y - 20:
		var seam := Polygon2D.new()
		seam.z_index = -7
		seam.color = Color(0.02, 0.02, 0.03, 0.7)
		seam.polygon = PackedVector2Array([
			Vector2(sl + 2, seam_y), Vector2(sr - 2, seam_y),
			Vector2(sr - 2, seam_y + 2), Vector2(sl + 2, seam_y + 2)
		])
		shaft.add_child(seam)
		seam_y += _rng.randf_range(55, 75)

	# ---- METAL WALL PANELS (left and right inner walls) ----
	for side_x in [sl, sr]:
		var inward: float = 1.0 if side_x == sl else -1.0
		var panel_w: float = 14.0
		var px: float = side_x if inward > 0 else side_x - panel_w

		# Main metal panel
		var panel := Polygon2D.new()
		panel.z_index = -6
		panel.color = Color(0.07, 0.07, 0.08, 1)
		panel.polygon = PackedVector2Array([
			Vector2(px, shaft_top_y), Vector2(px + panel_w, shaft_top_y),
			Vector2(px + panel_w, shaft_bot_y), Vector2(px, shaft_bot_y)
		])
		shaft.add_child(panel)

		# Panel highlight edge (inner)
		var hl := Polygon2D.new()
		hl.z_index = -5
		hl.color = Color(0.1, 0.1, 0.12, 1)
		var hlx: float = px + panel_w - 2 if inward > 0 else px
		hl.polygon = PackedVector2Array([
			Vector2(hlx, shaft_top_y), Vector2(hlx + 2, shaft_top_y),
			Vector2(hlx + 2, shaft_bot_y), Vector2(hlx, shaft_bot_y)
		])
		shaft.add_child(hl)

		# Rivet line (dots along the panel)
		var rivet_y: float = shaft_top_y + 20
		var rivet_x: float = px + panel_w * 0.5
		while rivet_y < shaft_bot_y - 10:
			var rivet := Polygon2D.new()
			rivet.z_index = -5
			rivet.color = Color(0.12, 0.11, 0.1, _rng.randf_range(0.5, 0.8))
			rivet.polygon = PackedVector2Array([
				Vector2(rivet_x - 2, rivet_y - 2), Vector2(rivet_x + 2, rivet_y - 2),
				Vector2(rivet_x + 2, rivet_y + 2), Vector2(rivet_x - 2, rivet_y + 2)
			])
			shaft.add_child(rivet)
			rivet_y += _rng.randf_range(28, 40)

	# ---- VERTICAL T-RAIL GUIDES (center-left and center-right) ----
	for rail_offset in [-0.3, 0.3]:
		var rx: float = sc + rail_offset * sw
		# Rail web (thin vertical)
		var web := Polygon2D.new()
		web.z_index = -5
		web.color = Color(0.09, 0.09, 0.1, 1)
		web.polygon = PackedVector2Array([
			Vector2(rx - 2, shaft_top_y), Vector2(rx + 2, shaft_top_y),
			Vector2(rx + 2, shaft_bot_y), Vector2(rx - 2, shaft_bot_y)
		])
		shaft.add_child(web)
		# Rail flange (wider top)
		var flange := Polygon2D.new()
		flange.z_index = -4
		flange.color = Color(0.11, 0.1, 0.1, 1)
		flange.polygon = PackedVector2Array([
			Vector2(rx - 5, shaft_top_y), Vector2(rx + 5, shaft_top_y),
			Vector2(rx + 5, shaft_top_y + 3), Vector2(rx - 5, shaft_top_y + 3)
		])
		shaft.add_child(flange)

	# ---- CABLES (hanging from top, broken partway down) ----
	for c in range(3):
		var cx: float = sc + _rng.randf_range(-sw * 0.3, sw * 0.3)
		var cable_len: float = _rng.randf_range(200, 600)
		var cable_bot: float = min(shaft_top_y + cable_len, shaft_bot_y - 50)
		var cable := Polygon2D.new()
		cable.z_index = -4
		cable.color = Color(0.06, 0.06, 0.07, _rng.randf_range(0.6, 0.9))
		var sway: float = _rng.randf_range(-10, 10)
		cable.polygon = PackedVector2Array([
			Vector2(cx - 1.5, shaft_top_y), Vector2(cx + 1.5, shaft_top_y),
			Vector2(cx + sway + 1.5, cable_bot), Vector2(cx + sway - 1.5, cable_bot)
		])
		shaft.add_child(cable)
		# Frayed end
		for f in range(2):
			var fray := Polygon2D.new()
			fray.z_index = -4
			fray.color = Color(0.08, 0.07, 0.06, 0.5)
			var fx: float = cx + sway + _rng.randf_range(-4, 4)
			var fl: float = _rng.randf_range(8, 20)
			fray.polygon = PackedVector2Array([
				Vector2(fx - 1, cable_bot), Vector2(fx + 1, cable_bot),
				Vector2(fx + _rng.randf_range(-3, 3), cable_bot + fl),
			])
			shaft.add_child(fray)

	# ---- DOOR FRAMES at each floor level ----
	for i in range(5, floor_count):
		var door_y: float = base_y + float(i) * floor_height
		var door_top: float = door_y - floor_thickness * 0.5 - 80
		var door_bot: float = door_y - floor_thickness * 0.5
		var door_left: float = sl - 6
		var door_right: float = sl + 4

		# Door frame (on the left wall of shaft, facing into the building)
		var frame_root := Node2D.new()
		frame_root.name = "DoorFrame%d" % i
		frame_root.z_index = -3
		shaft.add_child(frame_root)

		# Top lintel
		var lintel := Polygon2D.new()
		lintel.color = Color(0.1, 0.1, 0.11, 1)
		lintel.polygon = PackedVector2Array([
			Vector2(door_left, door_top - 6), Vector2(door_left + 50, door_top - 6),
			Vector2(door_left + 50, door_top), Vector2(door_left, door_top)
		])
		frame_root.add_child(lintel)

		# Left jamb
		var ljamb := Polygon2D.new()
		ljamb.color = Color(0.09, 0.09, 0.1, 1)
		ljamb.polygon = PackedVector2Array([
			Vector2(door_left, door_top), Vector2(door_left + 6, door_top),
			Vector2(door_left + 6, door_bot), Vector2(door_left, door_bot)
		])
		frame_root.add_child(ljamb)

		# Right jamb
		var rjamb := Polygon2D.new()
		rjamb.color = Color(0.09, 0.09, 0.1, 1)
		rjamb.polygon = PackedVector2Array([
			Vector2(door_left + 44, door_top), Vector2(door_left + 50, door_top),
			Vector2(door_left + 50, door_bot), Vector2(door_left + 44, door_bot)
		])
		frame_root.add_child(rjamb)

		# Threshold
		var thresh := Polygon2D.new()
		thresh.color = Color(0.12, 0.11, 0.1, 1)
		thresh.polygon = PackedVector2Array([
			Vector2(door_left, door_bot), Vector2(door_left + 50, door_bot),
			Vector2(door_left + 50, door_bot + 4), Vector2(door_left, door_bot + 4)
		])
		frame_root.add_child(thresh)

		# Dark opening
		var opening := Polygon2D.new()
		opening.z_index = -4
		opening.color = Color(0.02, 0.02, 0.025, 0.8)
		opening.polygon = PackedVector2Array([
			Vector2(door_left + 6, door_top), Vector2(door_left + 44, door_top),
			Vector2(door_left + 44, door_bot), Vector2(door_left + 6, door_bot)
		])
		frame_root.add_child(opening)

		# Floor number plate
		var plate := Polygon2D.new()
		plate.color = Color(0.15, 0.13, 0.1, _rng.randf_range(0.4, 0.7))
		plate.polygon = PackedVector2Array([
			Vector2(door_left + 14, door_top - 14), Vector2(door_left + 36, door_top - 14),
			Vector2(door_left + 36, door_top - 4), Vector2(door_left + 14, door_top - 4)
		])
		frame_root.add_child(plate)

	# ---- RUST PATCHES ----
	for i in range(15):
		var rust := Polygon2D.new()
		rust.z_index = -5
		var rx: float = _rng.randf_range(sl + 4, sr - 4)
		var ry2: float = _rng.randf_range(shaft_top_y + 20, shaft_bot_y - 20)
		var rw: float = _rng.randf_range(8, 30)
		var rh: float = _rng.randf_range(6, 20)
		rust.color = Color(
			_rng.randf_range(0.15, 0.25),
			_rng.randf_range(0.08, 0.14),
			_rng.randf_range(0.04, 0.08),
			_rng.randf_range(0.2, 0.45)
		)
		rust.polygon = PackedVector2Array([
			Vector2(rx, ry2), Vector2(rx + rw, ry2),
			Vector2(rx + rw, ry2 + rh), Vector2(rx, ry2 + rh)
		])
		shaft.add_child(rust)

	# ---- OUTER FRAME (thick structural I-beam edges) ----
	for side_x in [sl, sr]:
		var beam := Polygon2D.new()
		beam.z_index = -2
		beam.color = Color(0.065, 0.065, 0.075, 1)
		var bw: float = 10.0
		var bx: float = side_x - bw * 0.5
		beam.polygon = PackedVector2Array([
			Vector2(bx, shaft_top_y), Vector2(bx + bw, shaft_top_y),
			Vector2(bx + bw, shaft_bot_y), Vector2(bx, shaft_bot_y)
		])
		shaft.add_child(beam)
		# Beam highlight
		var bhl := Polygon2D.new()
		bhl.z_index = -2
		bhl.color = Color(0.1, 0.1, 0.11, 1)
		var bhl_x: float = bx if side_x == sl else bx + bw - 2
		bhl.polygon = PackedVector2Array([
			Vector2(bhl_x, shaft_top_y), Vector2(bhl_x + 2, shaft_top_y),
			Vector2(bhl_x + 2, shaft_bot_y), Vector2(bhl_x, shaft_bot_y)
		])
		shaft.add_child(bhl)

	# ---- VINES growing through the structure ----
	var vine_root := Node2D.new()
	vine_root.name = "ShaftVines"
	vine_root.z_index = -1
	shaft.add_child(vine_root)

	# Main stems (fewer, thicker)
	for s in range(2):
		var sx2: float = sl + 25 + float(s) * (sw - 50)
		_add_shaft_vine_stem(vine_root, sx2, shaft_top_y, shaft_bot_y)

	# Foliage and branches
	var vy: float = shaft_top_y + 30
	while vy < shaft_bot_y - 30:
		var fx: float = _rng.randf_range(sl + 15, sr - 15)
		_add_vine_foliage_cluster(vine_root, fx, vy, _rng.randf_range(10.0, 22.0))
		if _rng.randf() < 0.4:
			var bx2: float = _rng.randf_range(sl + 10, sr - 10)
			_add_vine_branch(vine_root, bx2, vy, _rng.randf_range(15.0, 45.0))
		vy += _rng.randf_range(30.0, 55.0)

	# Subtle vine glow
	var glow := Polygon2D.new()
	glow.z_index = 0
	glow.color = Color(0.15, 0.7, 0.4, 0.04)
	glow.polygon = PackedVector2Array([
		Vector2(sl - 10, shaft_top_y), Vector2(sr + 10, shaft_top_y),
		Vector2(sr + 15, shaft_bot_y), Vector2(sl - 15, shaft_bot_y)
	])
	shaft.add_child(glow)

func _add_shaft_vine_stem(parent: Node2D, x: float, top_y: float, bot_y: float) -> void:
	var segments: int = int((bot_y - top_y) / 30.0)
	var cy: float = top_y
	var cx: float = x
	for i in range(segments):
		var ny: float = min(cy + 30.0, bot_y)
		var nx: float = cx + _rng.randf_range(-4.0, 4.0)
		var w: float = _rng.randf_range(3.0, 6.0)
		var stem := Polygon2D.new()
		stem.color = VINE_STEM
		stem.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.8, ny), Vector2(nx - w * 0.8, ny)
		])
		parent.add_child(stem)

		# Occasional small leaves on stem
		if _rng.randf() < 0.3:
			_add_small_leaf(parent, nx + _rng.randf_range(-8, 8), ny)

		cx = nx
		cy = ny

func _add_vine_foliage_cluster(parent: Node2D, x: float, y: float, size: float) -> void:
	var count: int = _rng.randi_range(4, 8)
	for i in range(count):
		var leaf := Polygon2D.new()
		var g: float = _rng.randf_range(0.18, 0.38)
		leaf.color = Color(g * _rng.randf_range(0.3, 0.5), g, g * _rng.randf_range(0.2, 0.5), _rng.randf_range(0.5, 0.85))
		var angle: float = _rng.randf_range(0.0, TAU)
		var dist: float = _rng.randf_range(0.0, size * 0.5)
		var lx: float = x + cos(angle) * dist
		var ly: float = y + sin(angle) * dist
		var ls: float = _rng.randf_range(size * 0.25, size * 0.6)
		var la: float = _rng.randf_range(0.0, TAU)
		leaf.polygon = PackedVector2Array([
			Vector2(lx + cos(la) * ls, ly + sin(la) * ls),
			Vector2(lx + cos(la + 1.2) * ls * 0.5, ly + sin(la + 1.2) * ls * 0.5),
			Vector2(lx + cos(la + PI) * ls * 0.7, ly + sin(la + PI) * ls * 0.7),
			Vector2(lx + cos(la - 1.2) * ls * 0.5, ly + sin(la - 1.2) * ls * 0.5)
		])
		parent.add_child(leaf)

func _add_vine_branch(parent: Node2D, x: float, y: float, length: float) -> void:
	var angle: float = _rng.randf_range(-0.8, 0.8)
	var segs: int = _rng.randi_range(3, 6)
	var seg_len: float = length / float(segs)
	var cx: float = x
	var cy: float = y
	for i in range(segs):
		var nx: float = cx + cos(angle) * seg_len + _rng.randf_range(-3, 3)
		var ny: float = cy + sin(angle) * seg_len + _rng.randf_range(-2, 2)
		var w: float = _rng.randf_range(1.5, 3.5) * (1.0 - float(i) / float(segs) * 0.5)
		var branch := Polygon2D.new()
		branch.color = Color(VINE_STEM.r, VINE_STEM.g, VINE_STEM.b, VINE_STEM.a * 0.8)
		branch.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.7, ny), Vector2(nx - w * 0.7, ny)
		])
		parent.add_child(branch)
		angle += _rng.randf_range(-0.3, 0.3)
		cx = nx
		cy = ny

func _add_small_leaf(parent: Node2D, x: float, y: float) -> void:
	var leaf := Polygon2D.new()
	var g: float = _rng.randf_range(0.2, 0.35)
	leaf.color = Color(g * 0.4, g, g * 0.4, _rng.randf_range(0.5, 0.8))
	var s: float = _rng.randf_range(4.0, 9.0)
	var a: float = _rng.randf_range(0.0, TAU)
	leaf.polygon = PackedVector2Array([
		Vector2(x + cos(a) * s, y + sin(a) * s),
		Vector2(x + cos(a + 1.5) * s * 0.4, y + sin(a + 1.5) * s * 0.4),
		Vector2(x + cos(a + PI) * s * 0.6, y + sin(a + PI) * s * 0.6),
		Vector2(x + cos(a - 1.5) * s * 0.4, y + sin(a - 1.5) * s * 0.4)
	])
	parent.add_child(leaf)

func _add_vine_platform(parent: Node2D, x: float, y: float, w: float) -> void:
	# A vine-covered platform the player can stand on inside the shaft
	var plat := Node2D.new()
	plat.name = "VinePlatform"
	parent.add_child(plat)

	var half_w: float = w * 0.5
	var thickness: float = 16.0

	# Collision
	var body := StaticBody2D.new()
	plat.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, thickness)
	shape.shape = rect
	shape.position = Vector2(x, y)
	body.add_child(shape)

	# Vine platform visual (thick vine mass)
	var base := Polygon2D.new()
	base.color = Color(0.06, 0.2, 0.1, 0.9)
	base.polygon = PackedVector2Array([
		Vector2(x - half_w, y - thickness * 0.5),
		Vector2(x + half_w, y - thickness * 0.5),
		Vector2(x + half_w + 5, y + thickness * 0.5),
		Vector2(x - half_w - 5, y + thickness * 0.5)
	])
	plat.add_child(base)

	# Highlight
	var hl := Polygon2D.new()
	hl.color = Color(0.1, 0.3, 0.15, 0.6)
	hl.polygon = PackedVector2Array([
		Vector2(x - half_w + 3, y - thickness * 0.5),
		Vector2(x + half_w - 3, y - thickness * 0.5),
		Vector2(x + half_w - 3, y - thickness * 0.5 + 4),
		Vector2(x - half_w + 3, y - thickness * 0.5 + 4)
	])
	plat.add_child(hl)

	# Leaf clusters on platform
	for i in range(3):
		var lx: float = x + _rng.randf_range(-half_w * 0.6, half_w * 0.6)
		_add_vine_foliage_cluster(plat, lx, y - _rng.randf_range(8, 16), _rng.randf_range(8.0, 16.0))

func _build_city_backdrop(parent: Node2D) -> void:
	var backdrop := Node2D.new()
	backdrop.name = "CityBackdrop"
	backdrop.z_index = -8
	parent.add_child(backdrop)

	var half_w: float = room_half_width
	var total_h: float = float(floor_count) * floor_height
	var top_y: float = base_y - floor_height
	var bot_y: float = base_y + total_h + 200

	# Night sky gradient behind everything
	var sky := Polygon2D.new()
	sky.z_index = -10
	sky.color = Color(0.03, 0.03, 0.06, 1)
	sky.polygon = PackedVector2Array([
		Vector2(-half_w - 200, top_y - 400),
		Vector2(half_w + 200, top_y - 400),
		Vector2(half_w + 200, bot_y),
		Vector2(-half_w - 200, bot_y)
	])
	backdrop.add_child(sky)

	# Horizon glow (subtle warm band near the top)
	var horizon := Polygon2D.new()
	horizon.z_index = -10
	horizon.color = Color(0.08, 0.05, 0.04, 0.6)
	var hz_y: float = top_y + 50
	horizon.polygon = PackedVector2Array([
		Vector2(-half_w - 200, hz_y - 80),
		Vector2(half_w + 200, hz_y - 80),
		Vector2(half_w + 200, hz_y + 60),
		Vector2(-half_w - 200, hz_y + 60)
	])
	backdrop.add_child(horizon)

	# === 3 DEPTH LAYERS of building silhouettes ===
	# Layer 0: Far — small, dark blue-gray, few windows
	# Layer 1: Mid — medium, darker, more windows
	# Layer 2: Close — large, darkest, many windows, some detail
	var layer_configs: Array[Dictionary] = [
		{"z": -9, "color": Color(0.06, 0.06, 0.09, 1), "win_color": Color(0.25, 0.2, 0.1, 0.5),
		 "min_w": 60, "max_w": 140, "min_h": 100, "max_h": 350, "count": 18, "gap": 10},
		{"z": -8, "color": Color(0.04, 0.04, 0.06, 1), "win_color": Color(0.3, 0.25, 0.12, 0.6),
		 "min_w": 80, "max_w": 200, "min_h": 150, "max_h": 500, "count": 14, "gap": 20},
		{"z": -7, "color": Color(0.025, 0.025, 0.04, 1), "win_color": Color(0.35, 0.28, 0.1, 0.7),
		 "min_w": 100, "max_w": 280, "min_h": 200, "max_h": 700, "count": 10, "gap": 40},
	]

	for cfg in layer_configs:
		var layer_node := Node2D.new()
		layer_node.z_index = int(cfg["z"])
		backdrop.add_child(layer_node)

		var bx: float = -half_w - 100
		var building_count: int = int(cfg["count"])
		for _b in range(building_count):
			var bw: float = _rng.randf_range(float(cfg["min_w"]), float(cfg["max_w"]))
			var bh: float = _rng.randf_range(float(cfg["min_h"]), float(cfg["max_h"]))
			var gap: float = _rng.randf_range(float(cfg["gap"]) * 0.3, float(cfg["gap"]) * 1.5)
			bx += gap

			# Building base sits at a consistent "ground level" that varies slightly
			var ground_y: float = top_y + 180 + _rng.randf_range(-30, 30)
			var b_top: float = ground_y - bh
			var b_bot: float = ground_y + 400  # Extend well below to fill gaps

			var building := Polygon2D.new()
			building.color = cfg["color"] as Color
			# Slight random variation
			var bv: float = _rng.randf_range(-0.005, 0.005)
			building.color.r += bv
			building.color.g += bv
			building.color.b += bv

			# Irregular roofline
			var roof_pts := PackedVector2Array()
			roof_pts.append(Vector2(bx, b_bot))
			roof_pts.append(Vector2(bx, b_top + _rng.randf_range(-10, 10)))
			# Add some rooftop variation
			var roof_segs: int = _rng.randi_range(2, 5)
			var seg_w: float = bw / float(roof_segs)
			for s in range(1, roof_segs):
				var sx: float = bx + seg_w * float(s)
				var step: float = _rng.randf_range(-20, 20)
				roof_pts.append(Vector2(sx, b_top + step))
			roof_pts.append(Vector2(bx + bw, b_top + _rng.randf_range(-10, 10)))
			roof_pts.append(Vector2(bx + bw, b_bot))
			building.polygon = roof_pts
			layer_node.add_child(building)

			# Windows (lit rectangles)
			var win_color: Color = cfg["win_color"] as Color
			var win_w: float = _rng.randf_range(4, 10)
			var win_h: float = _rng.randf_range(5, 12)
			var win_gap_x: float = win_w + _rng.randf_range(8, 20)
			var win_gap_y: float = win_h + _rng.randf_range(10, 25)
			var wx: float = bx + _rng.randf_range(6, 15)
			while wx + win_w < bx + bw - 6:
				var wy: float = b_top + _rng.randf_range(15, 30)
				while wy + win_h < ground_y - 10:
					if _rng.randf() < 0.4:  # Not all windows are lit
						var win := Polygon2D.new()
						# Vary window color slightly
						var wc := win_color
						wc.r += _rng.randf_range(-0.05, 0.05)
						wc.g += _rng.randf_range(-0.05, 0.05)
						win.color = wc
						win.polygon = PackedVector2Array([
							Vector2(wx, wy), Vector2(wx + win_w, wy),
							Vector2(wx + win_w, wy + win_h), Vector2(wx, wy + win_h)
						])
						layer_node.add_child(win)
					wy += win_gap_y
				wx += win_gap_x

			bx += bw

	# Street level fill at the bottom (dark ground)
	var street := Polygon2D.new()
	street.z_index = -6
	street.color = Color(0.02, 0.02, 0.03, 1)
	var street_y: float = top_y + 220
	street.polygon = PackedVector2Array([
		Vector2(-half_w - 200, street_y),
		Vector2(half_w + 200, street_y),
		Vector2(half_w + 200, bot_y),
		Vector2(-half_w - 200, bot_y)
	])
	backdrop.add_child(street)

func _build_side_walls(parent: Node2D) -> void:
	var total_height: float = float(floor_count) * floor_height + 2000
	var top_y: float = base_y - floor_height - 500
	var half_w: float = room_half_width

	for side in [-1.0, 1.0]:
		var wall_node := Node2D.new()
		wall_node.name = "SideWall" + ("L" if side < 0 else "R")
		parent.add_child(wall_node)

		var wx: float = half_w * side

		# Collision (thin, at the room edge)
		var body := StaticBody2D.new()
		wall_node.add_child(body)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(60, total_height)
		shape.shape = rect
		shape.position = Vector2(wx, top_y + total_height * 0.5)
		body.add_child(shape)

		# Visual wall face (only the visible 60px strip at the room edge)
		var vis := Polygon2D.new()
		vis.z_index = -5
		vis.color = Color(0.05, 0.05, 0.06, 1)
		vis.polygon = PackedVector2Array([
			Vector2(wx - 30, top_y), Vector2(wx + 30, top_y),
			Vector2(wx + 30, top_y + total_height), Vector2(wx - 30, top_y + total_height)
		])
		wall_node.add_child(vis)
