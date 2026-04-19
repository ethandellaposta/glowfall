extends Node2D

## Debug overlay that draws outline rectangles around all CollisionShape2D nodes
## in the scene tree. Uses red/orange/yellow shades to distinguish types:
##   - Red:    Player body collision
##   - Orange: Enemy body collision
##   - Yellow: Attack areas / Area2D hitboxes
##
## Toggle with F3 at runtime. Only active in debug builds by default.

@export var enabled: bool = true
@export var line_width: float = 1.5

var _visible: bool = true
var _was_f3_down: bool = false

func _ready() -> void:
	z_index = 100
	_visible = enabled

func _process(_delta: float) -> void:
	var f3_down := Input.is_key_pressed(KEY_F3)
	if f3_down and not _was_f3_down:
		_visible = not _visible
	_was_f3_down = f3_down
	queue_redraw()

func _draw() -> void:
	if not _visible:
		return
	var shapes := _collect_shapes(get_tree().root)
	for info in shapes:
		var rect: Rect2 = info["rect"]
		var color: Color = info["color"]
		# Draw outline (4 lines)
		var tl := rect.position
		var tr := Vector2(rect.end.x, rect.position.y)
		var br := rect.end
		var bl := Vector2(rect.position.x, rect.end.y)
		# Convert from global to local (this node is at 0,0 in the scene)
		tl = to_local(tl)
		tr = to_local(tr)
		br = to_local(br)
		bl = to_local(bl)
		draw_line(tl, tr, color, line_width)
		draw_line(tr, br, color, line_width)
		draw_line(br, bl, color, line_width)
		draw_line(bl, tl, color, line_width)

func _collect_shapes(root: Node) -> Array:
	var result := []
	var collision_shapes := root.find_children("*", "CollisionShape2D", true, false)
	for node in collision_shapes:
		var cs: CollisionShape2D = node as CollisionShape2D
		if cs == null or cs.shape == null or cs.disabled:
			continue
		var parent := cs.get_parent()
		if parent == null:
			continue
		var color := _get_color_for(cs, parent)
		var rect := _shape_to_global_rect(cs)
		if rect.size.length() < 0.1:
			continue
		result.append({"rect": rect, "color": color})
	return result

func _get_color_for(cs: CollisionShape2D, parent: Node) -> Color:
	# Area2D children (attack hitboxes) → yellow
	if parent is Area2D:
		return Color(1.0, 0.85, 0.1, 0.85)
	# Player body → red
	if parent is CharacterBody2D and parent.is_in_group("") == false:
		if parent.name == "Player" or parent.get_script() != null and "Player" in parent.get_script().resource_path:
			return Color(1.0, 0.2, 0.15, 0.85)
	# Enemy body → orange
	if parent is CharacterBody2D and parent.is_in_group("enemies"):
		return Color(1.0, 0.55, 0.1, 0.85)
	# CharacterBody2D (player fallback) → red
	if parent is CharacterBody2D:
		return Color(1.0, 0.3, 0.2, 0.85)
	# StaticBody / other → dim yellow
	return Color(0.9, 0.75, 0.3, 0.5)

func _shape_to_global_rect(cs: CollisionShape2D) -> Rect2:
	var shape := cs.shape
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		var center := cs.global_position
		return Rect2(center - half, (shape as RectangleShape2D).size)
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		var center := cs.global_position
		return Rect2(center - Vector2(r, r), Vector2(r * 2, r * 2))
	if shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		var half := Vector2(cap.radius, cap.height * 0.5)
		var center := cs.global_position
		return Rect2(center - half, half * 2.0)
	if shape is SegmentShape2D:
		var seg := shape as SegmentShape2D
		var a := cs.global_position + seg.a
		var b := cs.global_position + seg.b
		var mn := Vector2(minf(a.x, b.x), minf(a.y, b.y))
		var mx := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
		return Rect2(mn, mx - mn)
	return Rect2()
