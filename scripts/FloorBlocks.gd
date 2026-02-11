extends Node2D

@export var half_width: float = 1000.0
@export var block_width: float = 64.0
@export var block_height: float = 64.0
@export var block_gap: float = 0.0
@export var use_glow: bool = false
@export var glow_color: Color = Color(0.133333, 0.94902, 0.780392, 0.3)
@export var glow_height: float = 24.0
@export var glow_top_offset: float = -8.0
@export var texture: Texture2D = preload("res://assets/textures/ground.png")

func _ready() -> void:
	var original_polygons: Array[Polygon2D] = []
	for child in get_children():
		if child is Polygon2D:
			original_polygons.append(child)

	for poly in original_polygons:
		poly.visible = false

	var blocks_root := Node2D.new()
	blocks_root.name = "Blocks"
	add_child(blocks_root)

	var tex_w: float = 1.0
	var tex_h: float = 1.0
	if texture != null:
		tex_w = float(texture.get_width())
		tex_h = float(texture.get_height())

	var x: float = -half_width
	var step: float = block_width + block_gap
	while x < half_width:
		var block_start: float = x
		var block_end: float = float(min(block_start + block_width, half_width))
		var left: float = block_start + block_gap * 0.5
		var right: float = block_end - block_gap * 0.5
		if right <= left:
			break

		var block_poly := Polygon2D.new()
		block_poly.texture = texture
		block_poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		block_poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		block_poly.polygon = PackedVector2Array([
			Vector2(left, -block_height * 0.5),
			Vector2(right, -block_height * 0.5),
			Vector2(right, block_height * 0.5),
			Vector2(left, block_height * 0.5),
		])
		block_poly.uv = PackedVector2Array([
			Vector2(0, 0),
			Vector2(tex_w, 0),
			Vector2(tex_w, tex_h),
			Vector2(0, tex_h),
		])
		blocks_root.add_child(block_poly)

		if use_glow:
			var glow_poly := Polygon2D.new()
			glow_poly.color = glow_color
			glow_poly.polygon = PackedVector2Array([
				Vector2(left, glow_top_offset - glow_height),
				Vector2(right, glow_top_offset - glow_height),
				Vector2(right, glow_top_offset),
				Vector2(left, glow_top_offset),
			])
			blocks_root.add_child(glow_poly)

		x += step
