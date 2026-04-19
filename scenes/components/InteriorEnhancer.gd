extends Node2D

## Procedurally adds wall texture detail, decay/holes, and vine granularity
## to interior rooms (TopFloor-style scenes with WallPanels, Windows, Vines).

@export var seed_value: int = 0
@export var enable_wall_texture: bool = true
@export var enable_wall_holes: bool = true
@export var enable_vine_detail: bool = true

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = seed_value if seed_value != 0 else hash(get_path())
	if enable_wall_texture:
		_add_wall_texture()
	if enable_wall_holes:
		_add_wall_holes()
	if enable_vine_detail:
		_add_vine_detail()

# ---------------------------------------------------------------------------
# Wall texture detail
# ---------------------------------------------------------------------------

func _add_wall_texture() -> void:
	var panels := get_node_or_null("WallPanels")
	if panels == null:
		return

	var detail := Node2D.new()
	detail.name = "WallTextureGen"
	detail.z_index = -5
	panels.add_child(detail)

	var x_left: float = -1000.0
	var x_right: float = 1000.0
	var y_top: float = 90.0
	var y_bot: float = 420.0

	# Concrete/plaster texture: horizontal mortar-like lines
	var row_h: float = 28.0
	var y: float = y_top
	while y < y_bot:
		if _rng.randf() < 0.6:
			var line := Polygon2D.new()
			var b: float = _rng.randf_range(0.08, 0.13)
			line.color = Color(b, b, b * 1.1, _rng.randf_range(0.1, 0.3))
			line.polygon = PackedVector2Array([
				Vector2(x_left, y), Vector2(x_right, y),
				Vector2(x_right, y + 1.5), Vector2(x_left, y + 1.5)
			])
			detail.add_child(line)
		y += row_h + _rng.randf_range(-4.0, 4.0)

	# Plaster patches / discoloration
	for i in range(18):
		var px: float = _rng.randf_range(x_left + 20, x_right - 60)
		var py: float = _rng.randf_range(y_top + 10, y_bot - 30)
		var pw: float = _rng.randf_range(20.0, 80.0)
		var ph: float = _rng.randf_range(15.0, 50.0)
		var patch := Polygon2D.new()
		var pb: float = _rng.randf_range(0.09, 0.16)
		patch.color = Color(pb, pb, pb * _rng.randf_range(1.0, 1.2), _rng.randf_range(0.06, 0.18))
		patch.polygon = PackedVector2Array([
			Vector2(px, py), Vector2(px + pw, py),
			Vector2(px + pw, py + ph), Vector2(px, py + ph)
		])
		detail.add_child(patch)

	# Vertical water stains
	for i in range(8):
		var sx: float = _rng.randf_range(x_left + 30, x_right - 30)
		var sy: float = _rng.randf_range(y_top, y_top + 60)
		var sh: float = _rng.randf_range(40.0, 160.0)
		var sw: float = _rng.randf_range(3.0, 8.0)
		var stain := Polygon2D.new()
		stain.color = Color(0.07, 0.07, 0.09, _rng.randf_range(0.1, 0.25))
		stain.polygon = PackedVector2Array([
			Vector2(sx, sy), Vector2(sx + sw, sy),
			Vector2(sx + sw * 0.6, sy + sh), Vector2(sx + sw * 0.4, sy + sh)
		])
		detail.add_child(stain)

# ---------------------------------------------------------------------------
# Wall holes and decay
# ---------------------------------------------------------------------------

func _add_wall_holes() -> void:
	var panels := get_node_or_null("WallPanels")
	if panels == null:
		return

	var decay := Node2D.new()
	decay.name = "WallDecayGen"
	decay.z_index = -4
	panels.add_child(decay)

	var y_top: float = 100.0
	var y_bot: float = 410.0
	var x_left: float = -950.0
	var x_right: float = 950.0

	# Holes in the wall
	var hole_count: int = _rng.randi_range(2, 5)
	for i in range(hole_count):
		var hx: float = _rng.randf_range(x_left, x_right - 80)
		var hy: float = _rng.randf_range(y_top + 20, y_bot - 60)
		var hw: float = _rng.randf_range(25.0, 80.0)
		var hh: float = _rng.randf_range(20.0, 55.0)

		# Crumbling edge
		var edge := Polygon2D.new()
		edge.color = Color(0.08, 0.08, 0.1, _rng.randf_range(0.3, 0.6))
		edge.polygon = _make_irregular_rect(hx - 3, hy - 3, hw + 6, hh + 6, 6)
		decay.add_child(edge)

		# Dark hole
		var hole := Polygon2D.new()
		hole.color = Color(0.02, 0.02, 0.03, _rng.randf_range(0.6, 0.9))
		hole.polygon = _make_irregular_rect(hx, hy, hw, hh, 6)
		decay.add_child(hole)

		# Rebar
		if _rng.randf() < 0.6:
			var rebar := Polygon2D.new()
			rebar.color = Color(_rng.randf_range(0.25, 0.35), _rng.randf_range(0.15, 0.22), _rng.randf_range(0.1, 0.16), _rng.randf_range(0.5, 0.75))
			var rx: float = hx + _rng.randf_range(hw * 0.2, hw * 0.8)
			var rw: float = _rng.randf_range(1.5, 3.0)
			var rh: float = _rng.randf_range(10.0, 25.0)
			var ry: float = hy - rh * 0.2 if _rng.randf() < 0.5 else hy + hh - rh * 0.8
			rebar.polygon = PackedVector2Array([
				Vector2(rx, ry), Vector2(rx + rw, ry),
				Vector2(rx + rw, ry + rh), Vector2(rx, ry + rh)
			])
			decay.add_child(rebar)

	# Cracks
	for i in range(6):
		var cx: float = _rng.randf_range(x_left + 50, x_right - 50)
		var cy: float = _rng.randf_range(y_top + 20, y_bot - 40)
		_add_crack(decay, cx, cy)

	# Spalling
	for i in range(5):
		var sx: float = _rng.randf_range(x_left, x_right - 50)
		var sy: float = _rng.randf_range(y_top, y_bot - 20)
		var sw: float = _rng.randf_range(15.0, 50.0)
		var sh: float = _rng.randf_range(8.0, 25.0)
		var spall := Polygon2D.new()
		spall.color = Color(0.07, 0.07, 0.08, _rng.randf_range(0.2, 0.45))
		spall.polygon = _make_irregular_rect(sx, sy, sw, sh, 5)
		decay.add_child(spall)

func _add_crack(parent: Node2D, x: float, y: float) -> void:
	var length: float = _rng.randf_range(30.0, 100.0)
	var segments: int = _rng.randi_range(4, 8)
	var seg_len: float = length / float(segments)
	var cx: float = x
	var cy: float = y
	var angle: float = _rng.randf_range(-0.5, 0.5) + PI * 0.5

	for i in range(segments):
		var nx: float = cx + cos(angle) * seg_len + _rng.randf_range(-3.0, 3.0)
		var ny: float = cy + sin(angle) * seg_len + _rng.randf_range(-2.0, 2.0)
		var w: float = _rng.randf_range(1.0, 3.0) * (1.0 - float(i) / float(segments) * 0.5)
		var crack := Polygon2D.new()
		crack.color = Color(0.04, 0.04, 0.05, _rng.randf_range(0.35, 0.65))
		crack.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.7, ny), Vector2(nx - w * 0.7, ny)
		])
		parent.add_child(crack)
		angle += _rng.randf_range(-0.4, 0.4)
		cx = nx
		cy = ny

# ---------------------------------------------------------------------------
# Vine detail enhancement
# ---------------------------------------------------------------------------

func _add_vine_detail() -> void:
	var vines := get_node_or_null("Vines")
	if vines == null:
		return

	var detail := Node2D.new()
	detail.name = "VineDetailGen"
	vines.add_child(detail)

	# The ceiling hole vines hang from y~60 down to y~260
	# Add leaf clusters along existing vine paths
	for i in range(25):
		var lx: float = _rng.randf_range(-110.0, 110.0)
		var ly: float = _rng.randf_range(70.0, 270.0)
		_add_leaf_cluster(detail, lx, ly, _rng.randf_range(5.0, 14.0))

	# Thin branching tendrils from the ceiling opening
	for i in range(8):
		var tx: float = _rng.randf_range(-115.0, 115.0)
		var ty: float = _rng.randf_range(60.0, 80.0)
		_add_tendril(detail, tx, ty, _rng.randf_range(40.0, 150.0), _rng.randf_range(-0.3, 0.3))

	# Small curling tips
	for i in range(6):
		var cx: float = _rng.randf_range(-100.0, 100.0)
		var cy: float = _rng.randf_range(150.0, 280.0)
		_add_curl(detail, cx, cy)

	# Add some wall-creeping vines along the interior walls
	for i in range(6):
		var wx: float
		if _rng.randf() < 0.5:
			wx = _rng.randf_range(-970.0, -920.0)
		else:
			wx = _rng.randf_range(920.0, 970.0)
		var wy: float = _rng.randf_range(100.0, 200.0)
		_add_tendril(detail, wx, wy, _rng.randf_range(60.0, 200.0), _rng.randf_range(-0.1, 0.1))
		_add_leaf_cluster(detail, wx, wy + 30, _rng.randf_range(6.0, 12.0))

func _add_leaf_cluster(parent: Node2D, x: float, y: float, size: float) -> void:
	var leaf_count: int = _rng.randi_range(3, 7)
	for i in range(leaf_count):
		var leaf := Polygon2D.new()
		var g: float = _rng.randf_range(0.15, 0.38)
		var r: float = g * _rng.randf_range(0.3, 0.6)
		var b: float = g * _rng.randf_range(0.2, 0.5)
		leaf.color = Color(r, g, b, _rng.randf_range(0.4, 0.8))

		var angle: float = _rng.randf_range(0.0, TAU)
		var dist: float = _rng.randf_range(0.0, size * 0.6)
		var lx: float = x + cos(angle) * dist
		var ly: float = y + sin(angle) * dist
		var ls: float = _rng.randf_range(size * 0.3, size * 0.8)

		var pts := PackedVector2Array()
		var la: float = _rng.randf_range(0.0, TAU)
		pts.append(Vector2(lx + cos(la) * ls, ly + sin(la) * ls))
		pts.append(Vector2(lx + cos(la + 1.2) * ls * 0.5, ly + sin(la + 1.2) * ls * 0.5))
		pts.append(Vector2(lx + cos(la + PI) * ls * 0.8, ly + sin(la + PI) * ls * 0.8))
		pts.append(Vector2(lx + cos(la - 1.2) * ls * 0.5, ly + sin(la - 1.2) * ls * 0.5))
		leaf.polygon = pts
		parent.add_child(leaf)

func _add_tendril(parent: Node2D, x: float, y: float, length: float, lean: float) -> void:
	var segments: int = _rng.randi_range(6, 12)
	var seg_len: float = length / float(segments)
	var cx: float = x
	var cy: float = y

	for i in range(segments):
		var nx: float = cx + _rng.randf_range(-5.0, 5.0) + lean * seg_len
		var ny: float = cy + seg_len
		var tendril := Polygon2D.new()
		var g: float = _rng.randf_range(0.12, 0.22)
		tendril.color = Color(g * 0.4, g, g * 0.5, _rng.randf_range(0.5, 0.85))
		var w: float = _rng.randf_range(1.5, 3.0) * (1.0 - float(i) / float(segments) * 0.6)
		tendril.polygon = PackedVector2Array([
			Vector2(cx - w, cy), Vector2(cx + w, cy),
			Vector2(nx + w * 0.7, ny), Vector2(nx - w * 0.7, ny)
		])
		parent.add_child(tendril)

		if _rng.randf() < 0.3:
			_add_leaf_cluster(parent, nx, ny, _rng.randf_range(3.0, 8.0))

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
	pts.append(Vector2(x + _rng.randf_range(0, jitter), y + _rng.randf_range(0, jitter)))
	for i in range(1, point_count / 2):
		var t: float = float(i) / float(point_count / 2)
		pts.append(Vector2(x + w * t + _rng.randf_range(-jitter, jitter), y + _rng.randf_range(-jitter, jitter)))
	pts.append(Vector2(x + w + _rng.randf_range(-jitter, 0), y + _rng.randf_range(0, jitter)))
	pts.append(Vector2(x + w + _rng.randf_range(-jitter, 0), y + h + _rng.randf_range(-jitter, 0)))
	for i in range(point_count / 2 - 1, 0, -1):
		var t: float = float(i) / float(point_count / 2)
		pts.append(Vector2(x + w * t + _rng.randf_range(-jitter, jitter), y + h + _rng.randf_range(-jitter, jitter)))
	pts.append(Vector2(x + _rng.randf_range(0, jitter), y + h + _rng.randf_range(-jitter, 0)))
	return pts
