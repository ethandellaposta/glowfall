extends ParallaxBackground

class _LayerTiles:
	var layer: ParallaxLayer
	var template: Sprite2D
	var tiles: Array[Sprite2D] = []
	var tile_w: float = 0.0
	var y: float = 0.0

	func _init(l: ParallaxLayer, t: Sprite2D, w: float, yy: float) -> void:
		layer = l
		template = t
		tile_w = w
		y = yy

var _layer_tiles: Array[_LayerTiles] = []

var _tex_content_bottom_cache: Dictionary = {}

@export var default_bottom_y: float = 520.0

func _ready() -> void:
	# Dynamically discover all ParallaxLayer children and their Sprite2D children
	for child in get_children():
		if child is ParallaxLayer:
			var layer := child as ParallaxLayer
			for sub in layer.get_children():
				if sub is Sprite2D:
					_init_layer_tiles(layer, sub as Sprite2D, default_bottom_y)
					break  # One sprite per layer
	_update_tiles()

func _process(_delta: float) -> void:
	_update_tiles()

func _init_layer_tiles(layer: ParallaxLayer, sprite: Sprite2D, bottom_y: float) -> void:
	if layer == null or sprite == null:
		return
	var tex := sprite.texture
	if tex == null:
		return
	var size := tex.get_size()
	if size.x <= 0:
		return
	# Account for sprite scale
	var sx: float = maxf(0.01, sprite.scale.x)
	var sy: float = maxf(0.01, sprite.scale.y)
	var w: float = float(size.x) * sx
	var content_bottom: float = _get_texture_content_bottom(tex) * sy
	sprite.position.y = bottom_y - content_bottom
	layer.motion_mirroring = Vector2(w, 0.0)
	var lt := _LayerTiles.new(layer, sprite, w, sprite.position.y)
	lt.tiles.append(sprite)
	_layer_tiles.append(lt)

	var cam: Camera2D = get_viewport().get_camera_2d()
	var view_w: float = float(get_viewport().get_visible_rect().size.x)
	if cam != null:
		view_w = view_w / maxf(0.0001, cam.zoom.x)
	var desired: int = int(ceil(view_w / w)) + 4
	while lt.tiles.size() < desired:
		var dup := sprite.duplicate() as Sprite2D
		if dup == null:
			break
		layer.add_child(dup)
		lt.tiles.append(dup)

func _get_texture_content_bottom(tex: Texture2D) -> float:
	if tex == null:
		return 0.0
	var key := tex.resource_path
	if key.is_empty():
		key = str(tex.get_instance_id())
	if _tex_content_bottom_cache.has(key):
		return float(_tex_content_bottom_cache[key])
	var size := tex.get_size()
	var fallback := float(size.y)
	var img := tex.get_image()
	if img == null:
		_tex_content_bottom_cache[key] = fallback
		return fallback
	var w := img.get_width()
	var h := img.get_height()
	var y := h - 1
	while y >= 0:
		var has_opaque := false
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a > 0.01:
				has_opaque = true
				break
		if has_opaque:
			break
		y -= 1
	var bottom := float(maxi(0, y + 1))
	if bottom <= 0.0:
		bottom = fallback
	_tex_content_bottom_cache[key] = bottom
	return bottom

func _update_tiles() -> void:
	if _layer_tiles.is_empty():
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	var view_w: float = float(get_viewport().get_visible_rect().size.x)
	var cam_x: float = 0.0
	var zoom_x: float = 1.0
	if cam != null:
		cam_x = cam.global_position.x
		zoom_x = cam.zoom.x
	view_w = view_w / maxf(0.0001, zoom_x)
	var half_w: float = view_w * 0.5

	for lt in _layer_tiles:
		if lt == null or lt.layer == null:
			continue
		if lt.tile_w <= 0.0:
			continue
		var s: float = cam_x * float(lt.layer.motion_scale.x) + float(scroll_base_offset.x)
		var base_x: float = floor((s - half_w) / lt.tile_w) * lt.tile_w
		for i in range(lt.tiles.size()):
			var spr := lt.tiles[i]
			if spr == null:
				continue
			spr.centered = false
			spr.position = Vector2(base_x + float(i) * lt.tile_w, lt.y)
