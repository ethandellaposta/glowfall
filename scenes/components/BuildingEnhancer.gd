extends Node2D

## Procedurally adds brick texture detail, wall holes/decay, and granular vine
## detail to the building facade below the roofline.  Attach to any Node2D that
## contains BuildingFacade, FacadeVines, FacadeDecay, and/or RoofVines children.

@export var seed_value: int = 0
@export var enable_brick_detail: bool = true
@export var enable_wall_holes: bool = true
@export var enable_vine_detail: bool = true

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = seed_value if seed_value != 0 else hash(get_path())
	if enable_brick_detail:
		_add_brick_detail()
	if enable_wall_holes:
		_add_wall_holes()
	if enable_vine_detail:
		_add_vine_detail()

# ---------------------------------------------------------------------------
# Brick texture detail
# ---------------------------------------------------------------------------

func _add_brick_detail() -> void:
	var facade := get_node_or_null("BuildingFacade")
	if facade == null:
		return

	var brick_root := Node2D.new()
	brick_root.name = "BrickDetailGen"
	facade.add_child(brick_root)

	var y_start: float = 466.0
	var y_end: float = 1650.0
	var x_left: float = -1000.0
	var x_right: float = 1000.0

	# Horizontal mortar lines with slight variation
	var row_h: float = 64.0
	var y: float = y_start
	while y < y_end:
		# Mortar line with slight color variation
		var mortar := Polygon2D.new()
		var brightness: float = _rng.randf_range(0.11, 0.15)
		mortar.color = Color(brightness, brightness * 0.92, brightness * 0.82, _rng.randf_range(0.3, 0.6))
		mortar.polygon = PackedVector2Array([
			Vector2(x_left, y), Vector2(x_right, y),
			Vector2(x_right, y + 2), Vector2(x_left, y + 2)
		])
		brick_root.add_child(mortar)

		# Vertical mortar joints (staggered every other row)
		var row_idx := int((y - y_start) / row_h)
		var offset: float = 0.0 if row_idx % 2 == 0 else row_h * 1.5
		var x: float = x_left + offset
		while x < x_right:
			var joint := Polygon2D.new()
			var jb: float = _rng.randf_range(0.11, 0.14)
			joint.color = Color(jb, jb * 0.92, jb * 0.82, _rng.randf_range(0.25, 0.5))
			joint.polygon = PackedVector2Array([
				Vector2(x, y), Vector2(x + 2, y),
				Vector2(x + 2, y + row_h), Vector2(x, y + row_h)
			])
			brick_root.add_child(joint)
			x += row_h * 6.0 + _rng.randf_range(-4.0, 4.0)

		# Individual brick color variation patches
		if _rng.randf() < 0.4:
			var bx: float = _rng.randf_range(x_left + 20, x_right - 80)
			var bw: float = _rng.randf_range(40.0, 90.0)
			var brick_var := Polygon2D.new()
			var bv: float = _rng.randf_range(0.13, 0.2)
			brick_var.color = Color(bv, bv * _rng.randf_range(0.8, 0.95), bv * _rng.randf_range(0.7, 0.9), _rng.randf_range(0.15, 0.35))
			brick_var.polygon = PackedVector2Array([
				Vector2(bx, y + 2), Vector2(bx + bw, y + 2),
				Vector2(bx + bw, y + row_h), Vector2(bx, y + row_h)
			])
			brick_root.add_child(brick_var)

		y += row_h

	# Scattered weathering streaks (vertical drip stains)
	for i in range(5):
		var sx: float = _rng.randf_range(x_left + 50, x_right - 50)
		var sy: float = _rng.randf_range(y_start, y_start + 400)
		var sh: float = _rng.randf_range(60.0, 200.0)
		var sw: float = _rng.randf_range(3.0, 10.0)
		var streak := Polygon2D.new()
		var sb: float = _rng.randf_range(0.06, 0.1)
		streak.color = Color(sb, sb * 0.9, sb * 0.8, _rng.randf_range(0.15, 0.35))
		streak.polygon = PackedVector2Array([
			Vector2(sx, sy), Vector2(sx + sw, sy),
			Vector2(sx + sw * 0.6, sy + sh), Vector2(sx + sw * 0.4, sy + sh)
		])
		brick_root.add_child(streak)

	# Surface noise: small random-color patches to break up uniformity
	for i in range(8):
		var nx: float = _rng.randf_range(x_left + 10, x_right - 40)
		var ny: float = _rng.randf_range(y_start, y_end - 40)
		var nw: float = _rng.randf_range(15.0, 60.0)
		var nh: float = _rng.randf_range(10.0, 30.0)
		var noise := Polygon2D.new()
		var nb: float = _rng.randf_range(0.1, 0.2)
		noise.color = Color(nb, nb * _rng.randf_range(0.85, 1.0), nb * _rng.randf_range(0.75, 0.95), _rng.randf_range(0.08, 0.2))
		noise.polygon = PackedVector2Array([
			Vector2(nx, ny), Vector2(nx + nw, ny),
			Vector2(nx + nw, ny + nh), Vector2(nx, ny + nh)
		])
		brick_root.add_child(noise)

# ---------------------------------------------------------------------------
# Wall holes and decay
# ---------------------------------------------------------------------------

func _add_wall_holes() -> void:
	var facade := get_node_or_null("BuildingFacade")
	if facade == null:
		return

	var decay_root := Node2D.new()
	decay_root.name = "WallHolesGen"
	facade.add_child(decay_root)

	var y_start: float = 460.0
	var y_end: float = 1000.0
	var x_left: float = -950.0
	var x_right: float = 950.0

	# Large holes in the wall
	var hole_count: int = _rng.randi_range(3, 6)
	for i in range(hole_count):
		var hx: float = _rng.randf_range(x_left, x_right - 100)
		var hy: float = _rng.randf_range(y_start + 30, y_end - 80)
		var hw: float = _rng.randf_range(40.0, 120.0)
		var hh: float = _rng.randf_range(30.0, 80.0)

		# Crumbling edge (lighter outline, added first so hole draws on top)
		var edge := Polygon2D.new()
		edge.color = Color(0.1, 0.09, 0.07, _rng.randf_range(0.4, 0.7))
		var edge_pts := _make_irregular_rect(hx - 4, hy - 4, hw + 8, hh + 8, 8)
		edge.polygon = edge_pts
		decay_root.add_child(edge)

		# Dark hole interior
		var hole := Polygon2D.new()
		hole.color = Color(0.02, 0.02, 0.03, _rng.randf_range(0.7, 0.95))
		var pts := _make_irregular_rect(hx, hy, hw, hh, 6)
		hole.polygon = pts
		decay_root.add_child(hole)

		# Exposed rebar sticking out
		var rebar_count: int = _rng.randi_range(1, 3)
		for r in range(rebar_count):
			var rebar := Polygon2D.new()
			rebar.color = Color(_rng.randf_range(0.25, 0.35), _rng.randf_range(0.15, 0.22), _rng.randf_range(0.1, 0.16), _rng.randf_range(0.5, 0.8))
			var rx: float = hx + _rng.randf_range(hw * 0.1, hw * 0.9)
			var ry: float
			var rw: float = _rng.randf_range(2.0, 4.0)
			var rh: float = _rng.randf_range(12.0, 35.0)
			if _rng.randf() < 0.5:
				ry = hy - rh * 0.3
			else:
				ry = hy + hh - rh * 0.7
			rebar.polygon = PackedVector2Array([
				Vector2(rx, ry), Vector2(rx + rw, ry),
				Vector2(rx + rw, ry + rh), Vector2(rx, ry + rh)
			])
			decay_root.add_child(rebar)

	# Spalling / chipped patches
	for i in range(4):
		var sx: float = _rng.randf_range(x_left, x_right - 60)
		var sy: float = _rng.randf_range(y_start, y_end)
		var sw: float = _rng.randf_range(20.0, 70.0)
		var sh: float = _rng.randf_range(10.0, 40.0)
		var spall := Polygon2D.new()
		var sb: float = _rng.randf_range(0.08, 0.13)
		spall.color = Color(sb, sb * 0.9, sb * 0.75, _rng.randf_range(0.3, 0.6))
		spall.polygon = _make_irregular_rect(sx, sy, sw, sh, 5)
		decay_root.add_child(spall)

	# Edge erosion along the top of the facade
	for i in range(6):
		var ex: float = _rng.randf_range(x_left, x_right - 30)
		var ew: float = _rng.randf_range(10.0, 50.0)
		var eh: float = _rng.randf_range(4.0, 14.0)
		var erosion := Polygon2D.new()
		erosion.color = Color(0.04, 0.04, 0.05, _rng.randf_range(0.3, 0.6))
		erosion.polygon = PackedVector2Array([
			Vector2(ex, y_start - 2), Vector2(ex + ew, y_start - 2),
			Vector2(ex + ew * 0.8, y_start + eh), Vector2(ex + ew * 0.2, y_start + eh)
		])
		decay_root.add_child(erosion)

# ---------------------------------------------------------------------------
# Vine detail enhancement
# ---------------------------------------------------------------------------

func _add_vine_detail() -> void:
	_enhance_facade_vines()
	_enhance_roof_vines()

func _enhance_facade_vines() -> void:
	var facade_vines := get_node_or_null("FacadeVines")
	if facade_vines == null:
		return

	var detail := Node2D.new()
	detail.name = "VineDetailGen"
	facade_vines.add_child(detail)

	# Add small leaf clusters along existing vine stems
	var y_start: float = 440.0
	var y_end: float = 900.0

	# Scattered individual leaves along the facade
	for i in range(12):
		var lx: float = _rng.randf_range(-980.0, 980.0)
		var ly: float = _rng.randf_range(y_start, y_end)
		_add_leaf_cluster(detail, lx, ly, _rng.randf_range(6.0, 18.0))

	# Thin branching tendrils
	for i in range(5):
		var tx: float = _rng.randf_range(-900.0, 900.0)
		var ty: float = _rng.randf_range(y_start, y_start + 200)
		_add_tendril(detail, tx, ty, _rng.randf_range(60.0, 180.0), _rng.randf_range(-0.3, 0.3))

	# Small curling tips at vine ends
	for i in range(4):
		var cx: float = _rng.randf_range(-900.0, 900.0)
		var cy: float = _rng.randf_range(y_start + 100, y_end)
		_add_curl(detail, cx, cy)

func _enhance_roof_vines() -> void:
	var roof_vines := get_node_or_null("RoofVines")
	if roof_vines == null:
		return

	var detail := Node2D.new()
	detail.name = "RoofVineDetailGen"
	roof_vines.add_child(detail)

	# Add leaf clusters along the parapet
	for i in range(10):
		var lx: float = _rng.randf_range(-980.0, 980.0)
		var ly: float = _rng.randf_range(300.0, 410.0)
		_add_leaf_cluster(detail, lx, ly, _rng.randf_range(5.0, 14.0))

	# Thin tendrils hanging from parapet
	for i in range(4):
		var tx: float = _rng.randf_range(-950.0, 950.0)
		var ty: float = _rng.randf_range(388.0, 396.0)
		_add_tendril(detail, tx, ty, _rng.randf_range(30.0, 100.0), _rng.randf_range(-0.2, 0.2))

	# Small leaves on drapes
	for i in range(8):
		var lx: float = _rng.randf_range(-950.0, 950.0)
		var ly: float = _rng.randf_range(400.0, 560.0)
		_add_leaf_cluster(detail, lx, ly, _rng.randf_range(4.0, 10.0))

func _add_leaf_cluster(parent: Node2D, x: float, y: float, size: float) -> void:
	var leaf_count: int = _rng.randi_range(2, 4)
	for i in range(leaf_count):
		var leaf := Polygon2D.new()
		var g: float = _rng.randf_range(0.15, 0.35)
		var r: float = g * _rng.randf_range(0.3, 0.6)
		var b: float = g * _rng.randf_range(0.2, 0.5)
		leaf.color = Color(r, g, b, _rng.randf_range(0.4, 0.8))

		var angle: float = _rng.randf_range(0.0, TAU)
		var dist: float = _rng.randf_range(0.0, size * 0.6)
		var lx: float = x + cos(angle) * dist
		var ly: float = y + sin(angle) * dist
		var ls: float = _rng.randf_range(size * 0.3, size * 0.8)

		# Leaf shape: pointed oval
		var pts: PackedVector2Array = PackedVector2Array()
		var la: float = _rng.randf_range(0.0, TAU)
		pts.append(Vector2(lx + cos(la) * ls, ly + sin(la) * ls))
		pts.append(Vector2(lx + cos(la + 1.2) * ls * 0.5, ly + sin(la + 1.2) * ls * 0.5))
		pts.append(Vector2(lx + cos(la + PI) * ls * 0.8, ly + sin(la + PI) * ls * 0.8))
		pts.append(Vector2(lx + cos(la - 1.2) * ls * 0.5, ly + sin(la - 1.2) * ls * 0.5))
		leaf.polygon = pts
		parent.add_child(leaf)

func _add_tendril(parent: Node2D, x: float, y: float, length: float, lean: float) -> void:
	var segments: int = _rng.randi_range(4, 7)
	var seg_len: float = length / float(segments)
	var cx: float = x
	var cy: float = y

	for i in range(segments):
		var nx: float = cx + _rng.randf_range(-6.0, 6.0) + lean * seg_len
		var ny: float = cy + seg_len
		var tendril := Polygon2D.new()
		var g: float = _rng.randf_range(0.12, 0.2)
		tendril.color = Color(g * 0.4, g, g * 0.5, _rng.randf_range(0.5, 0.85))
		var w: float = _rng.randf_range(1.5, 3.5) * (1.0 - float(i) / float(segments) * 0.6)
		tendril.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.7, ny), Vector2(nx - w * 0.7, ny)
		])
		parent.add_child(tendril)

		# Occasional small leaf at joint
		if _rng.randf() < 0.35:
			_add_leaf_cluster(parent, nx, ny, _rng.randf_range(4.0, 9.0))

		cx = nx
		cy = ny

func _add_curl(parent: Node2D, x: float, y: float) -> void:
	var curl := Polygon2D.new()
	var g: float = _rng.randf_range(0.12, 0.22)
	curl.color = Color(g * 0.4, g, g * 0.5, _rng.randf_range(0.4, 0.7))
	var steps: int = 8
	var pts := PackedVector2Array()
	var radius: float = _rng.randf_range(4.0, 10.0)
	var start_angle: float = _rng.randf_range(0.0, TAU)
	for i in range(steps):
		var t: float = float(i) / float(steps)
		var a: float = start_angle + t * PI * 1.5
		var r: float = radius * (1.0 - t * 0.7)
		pts.append(Vector2(x + cos(a) * r, y + sin(a) * r))
	# Return path (inner edge)
	for i in range(steps - 1, -1, -1):
		var t: float = float(i) / float(steps)
		var a: float = start_angle + t * PI * 1.5
		var r: float = radius * (1.0 - t * 0.7) * 0.5
		pts.append(Vector2(x + cos(a) * r, y + sin(a) * r))
	curl.polygon = pts
	parent.add_child(curl)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_irregular_rect(x: float, y: float, w: float, h: float, point_count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var jitter: float = min(w, h) * 0.15
	# Top edge
	pts.append(Vector2(x + _rng.randf_range(0, jitter), y + _rng.randf_range(0, jitter)))
	for i in range(1, point_count / 2):
		var t: float = float(i) / float(point_count / 2)
		pts.append(Vector2(x + w * t + _rng.randf_range(-jitter, jitter), y + _rng.randf_range(-jitter, jitter)))
	pts.append(Vector2(x + w + _rng.randf_range(-jitter, 0), y + _rng.randf_range(0, jitter)))
	# Right edge
	pts.append(Vector2(x + w + _rng.randf_range(-jitter, 0), y + h + _rng.randf_range(-jitter, 0)))
	# Bottom edge (reversed)
	for i in range(point_count / 2 - 1, 0, -1):
		var t: float = float(i) / float(point_count / 2)
		pts.append(Vector2(x + w * t + _rng.randf_range(-jitter, jitter), y + h + _rng.randf_range(-jitter, jitter)))
	pts.append(Vector2(x + _rng.randf_range(0, jitter), y + h + _rng.randf_range(-jitter, 0)))
	return pts
