extends RefCounted

## Utility class for building SpriteFrames from individual frame images and sprite sheets.
## Used by both Player and Enemy to set up their AnimatedSprite2D frames at runtime.

static func add_animation_mode(frames: SpriteFrames, anim_name: String, mode_name: String, frame_count: int, anim_speed: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var path: String = "res://assets/robot/robot_%s_%02d.png" % [mode_name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			break
		frames.add_frame(anim_name, tex)

static func add_animation_mode_range(
		frames: SpriteFrames,
		anim_name: String,
		mode_name: String,
		start_frame: int,
		end_frame_exclusive: int,
		anim_speed: float,
		loop: bool
	) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(start_frame, end_frame_exclusive):
		var path: String = "res://assets/robot/robot_%s_%02d.png" % [mode_name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			break
		frames.add_frame(anim_name, tex)

static func add_animation_mode_baked_padded(
		frames: SpriteFrames,
		anim_name: String,
		mode_name: String,
		frame_count: int,
		anim_speed: float,
		loop: bool,
		pad_w: int,
		pad_h: int,
		allow_upscale: bool = true,
		scale_bias: float = 1.0
	) -> void:
	var texs: Array[Texture2D] = []
	var max_w := 0
	var max_h := 0
	for i in range(frame_count):
		var path: String = "res://assets/robot/robot_%s_%02d.png" % [mode_name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			break
		texs.append(tex)
		max_w = maxi(max_w, tex.get_width())
		max_h = maxi(max_h, tex.get_height())
	if texs.is_empty():
		return
	pad_w = maxi(pad_w, max_w)
	pad_h = maxi(pad_h, max_h)
	if pad_w <= 0 or pad_h <= 0:
		return
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for tex in texs:
		var src_img := tex.get_image()
		if src_img == null:
			continue
		if src_img.get_format() != Image.FORMAT_RGBA8:
			src_img.convert(Image.FORMAT_RGBA8)
		var src_w := tex.get_width()
		var src_h := tex.get_height()
		var scale_limit := minf(float(pad_w) / maxf(1.0, float(src_w)), float(pad_h) / maxf(1.0, float(src_h)))
		if not allow_upscale:
			scale_limit = minf(scale_limit, 1.0)
		var img_scale := scale_limit * clampf(scale_bias, 0.01, 10.0)
		img_scale = clampf(img_scale, 0.01, scale_limit)
		var target_w := int(round(float(src_w) * img_scale))
		var target_h := int(round(float(src_h) * img_scale))
		if target_w <= 0 or target_h <= 0:
			continue
		if target_w != src_w or target_h != src_h:
			var resize_mode := Image.INTERPOLATE_NEAREST
			if target_w < src_w or target_h < src_h:
				resize_mode = Image.INTERPOLATE_BILINEAR
			src_img.resize(target_w, target_h, resize_mode)
			src_w = target_w
			src_h = target_h
		var dst_img := Image.create(pad_w, pad_h, false, Image.FORMAT_RGBA8)
		dst_img.fill(Color(0, 0, 0, 0))
		var dx := int(floor(float(pad_w - src_w) * 0.5))
		var dy := int(floor(float(pad_h - src_h) * 0.5))
		dst_img.blit_rect(src_img, Rect2i(0, 0, src_w, src_h), Vector2i(dx, dy))
		var out_tex := ImageTexture.create_from_image(dst_img)
		frames.add_frame(anim_name, out_tex)

static func add_sheet_animation(
		frames: SpriteFrames,
		anim_name: String,
		sheet_path: String,
		cols: int,
		frame_count: int,
		anim_speed: float,
		loop: bool
	) -> void:
	if cols <= 0 or frame_count <= 0:
		return
	var sheet_tex: Texture2D = load(sheet_path) as Texture2D
	if sheet_tex == null:
		var img := Image.new()
		if img.load(sheet_path) != OK:
			return
		sheet_tex = ImageTexture.create_from_image(img)
		if sheet_tex == null:
			return
	var sheet_w: int = sheet_tex.get_width()
	var sheet_h: int = sheet_tex.get_height()
	if sheet_w <= 0 or sheet_h <= 0:
		return
	var frame_w: int = int(float(sheet_w) / float(cols))
	if frame_w <= 0:
		return
	var rows: int = int(ceil(float(frame_count) / float(cols)))
	if rows <= 0:
		return
	var frame_h: int = int(float(sheet_h) / float(rows))
	if frame_h <= 0:
		return

	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var row: int = int(i / float(cols))
		var col: int = i % cols
		var region := Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_tex
		atlas.region = region
		atlas.filter_clip = true
		frames.add_frame(anim_name, atlas)

static func add_sheet_animation_baked_padded(
		frames: SpriteFrames,
		anim_name: String,
		sheet_path: String,
		cols: int,
		frame_count: int,
		anim_speed: float,
		loop: bool,
		pad_w: int,
		pad_h: int,
		scale_bias: float = 1.0,
		allow_downscale: bool = true
	) -> void:
	if cols <= 0 or frame_count <= 0:
		return
	var sheet_tex: Texture2D = load(sheet_path) as Texture2D
	if sheet_tex == null:
		var img := Image.new()
		if img.load(sheet_path) != OK:
			return
		sheet_tex = ImageTexture.create_from_image(img)
		if sheet_tex == null:
			return
	var sheet_w: int = sheet_tex.get_width()
	var sheet_h: int = sheet_tex.get_height()
	if sheet_w <= 0 or sheet_h <= 0:
		return
	var frame_w: int = int(float(sheet_w) / float(cols))
	if frame_w <= 0:
		return
	var rows: int = int(ceil(float(frame_count) / float(cols)))
	if rows <= 0:
		return
	var frame_h: int = int(float(sheet_h) / float(rows))
	if frame_h <= 0:
		return
	if pad_w <= 0:
		pad_w = frame_w
	if pad_h <= 0:
		pad_h = frame_h
	if not allow_downscale:
		pad_w = maxi(pad_w, frame_w)
		pad_h = maxi(pad_h, frame_h)
	if pad_w <= 0 or pad_h <= 0:
		return
	var sheet_img := sheet_tex.get_image()
	if sheet_img == null:
		return
	if sheet_img.get_format() != Image.FORMAT_RGBA8:
		sheet_img.convert(Image.FORMAT_RGBA8)
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var row: int = int(i / float(cols))
		var col: int = i % cols
		var region := Rect2i(col * frame_w, row * frame_h, frame_w, frame_h)
		var frame_img := sheet_img.get_region(region)
		if frame_img == null:
			continue
		if frame_img.get_format() != Image.FORMAT_RGBA8:
			frame_img.convert(Image.FORMAT_RGBA8)
		var img_scale := minf(float(pad_w) / float(frame_w), float(pad_h) / float(frame_h))
		img_scale *= clampf(scale_bias, 0.01, 10.0)
		if img_scale <= 0.0:
			continue
		var target_w := int(round(float(frame_w) * img_scale))
		var target_h := int(round(float(frame_h) * img_scale))
		if target_w <= 0 or target_h <= 0:
			continue
		if target_w != frame_w or target_h != frame_h:
			var resize_mode := Image.INTERPOLATE_NEAREST
			if target_w < frame_w or target_h < frame_h:
				resize_mode = Image.INTERPOLATE_BILINEAR
			frame_img.resize(target_w, target_h, resize_mode)
		var dst_img := Image.create(pad_w, pad_h, false, Image.FORMAT_RGBA8)
		dst_img.fill(Color(0, 0, 0, 0))
		var dx := int(floor(float(pad_w - target_w) * 0.5))
		var dy := int(floor(float(pad_h - target_h) * 0.5))
		dst_img.blit_rect(frame_img, Rect2i(0, 0, target_w, target_h), Vector2i(dx, dy))
		var out_tex := ImageTexture.create_from_image(dst_img)
		frames.add_frame(anim_name, out_tex)

## Sprite sheet region utilities (used by Enemy)

static func get_autocrop_regions(tex: Texture2D, cols: int, rows: int, frame_count: int, padding: int) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	if tex == null:
		return out
	if cols <= 0 or rows <= 0 or frame_count <= 0:
		return out
	var img: Image = tex.get_image()
	if img == null:
		return out
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var sheet_w := tex.get_width()
	var sheet_h := tex.get_height()
	var base_w := int(float(sheet_w) / float(cols))
	var base_h := int(float(sheet_h) / float(rows))
	if base_w <= 0 or base_h <= 0:
		return out
	for i in range(frame_count):
		var row := int(i / float(cols))
		var col := i % cols
		if row >= rows:
			break
		var base := Rect2i(col * base_w, row * base_h, base_w, base_h)
		var bbox := _alpha_bbox(img, base)
		if bbox.size.x <= 0 or bbox.size.y <= 0:
			bbox = base
		bbox.position.x = maxi(base.position.x, bbox.position.x - padding)
		bbox.position.y = maxi(base.position.y, bbox.position.y - padding)
		bbox.size.x = mini(base.end.x - bbox.position.x, bbox.size.x + padding * 2)
		bbox.size.y = mini(base.end.y - bbox.position.y, bbox.size.y + padding * 2)
		out.append(bbox)
	return out

static func _alpha_bbox(img: Image, rect: Rect2i) -> Rect2i:
	var min_x := rect.end.x
	var min_y := rect.end.y
	var max_x := rect.position.x - 1
	var max_y := rect.position.y - 1
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var a := img.get_pixel(x, y).a
			if a > 0.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(rect.position.x, rect.position.y, 0, 0)
	return Rect2i(min_x, min_y, (max_x - min_x) + 1, (max_y - min_y) + 1)

static func add_regions_animation(
		frames: SpriteFrames,
		anim_name: String,
		tex: Texture2D,
		regions: Array[Rect2i],
		std_w: int,
		std_h: int,
		anim_speed: float,
		loop: bool
	) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, anim_speed)
	frames.set_animation_loop(anim_name, loop)
	for r in regions:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(r.position, r.size)
		atlas.filter_clip = true
		var left := int(floor(float(std_w - r.size.x) * 0.5))
		var top := int(floor(float(std_h - r.size.y) * 0.5))
		var right := std_w - r.size.x - left
		var bottom := std_h - r.size.y - top
		atlas.margin = Rect2(left, top, right, bottom)
		frames.add_frame(anim_name, atlas)
