extends RefCounted

## Sets up enemy AnimatedSprite2D frames from sprite sheets using SpriteFrameBuilder.

const SFB = preload("res://scenes/sprites/SpriteFrameBuilder.gd")

var sprite: AnimatedSprite2D

func _init(s: AnimatedSprite2D) -> void:
	sprite = s

func setup(walk_anim_speed: float, attack_anim_speed: float, sprite_scale: float) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.centered = true

	var padding := 2
	var move_tex: Texture2D = load("res://gen/scuttle-moving.png") as Texture2D
	var attack_tex: Texture2D = load("res://gen/scuttle-attack-1.png") as Texture2D
	if move_tex == null or attack_tex == null:
		return
	var move_regions: Array[Rect2i] = SFB.get_autocrop_regions(move_tex, 6, 6, 36, padding)
	var attack_regions: Array[Rect2i] = SFB.get_autocrop_regions(attack_tex, 6, 6, 36, padding)
	if move_regions.is_empty() or attack_regions.is_empty():
		var fallback_frames: SpriteFrames = SpriteFrames.new()
		SFB.add_sheet_animation(fallback_frames, "walk", "res://gen/scuttle-moving.png", 6, 36, walk_anim_speed, true)
		SFB.add_sheet_animation(fallback_frames, "attack", "res://gen/scuttle-attack-1.png", 6, 36, attack_anim_speed, false)
		if fallback_frames.get_frame_count("walk") > 0:
			if not fallback_frames.has_animation("idle"):
				fallback_frames.add_animation("idle")
			fallback_frames.set_animation_speed("idle", walk_anim_speed * 0.5)
			fallback_frames.set_animation_loop("idle", true)
			var idle_tex := fallback_frames.get_frame_texture("walk", 0)
			if idle_tex != null:
				fallback_frames.add_frame("idle", idle_tex)
		sprite.sprite_frames = fallback_frames
		return
	var std_w := 0
	var std_h := 0
	for r in move_regions:
		std_w = maxi(std_w, r.size.x)
		std_h = maxi(std_h, r.size.y)
	for r in attack_regions:
		std_w = maxi(std_w, r.size.x)
		std_h = maxi(std_h, r.size.y)
	if std_w <= 0 or std_h <= 0:
		return

	var frames: SpriteFrames = SpriteFrames.new()
	SFB.add_regions_animation(frames, "idle", move_tex, move_regions.slice(0, 6), std_w, std_h, walk_anim_speed * 0.5, true)
	SFB.add_regions_animation(frames, "walk", move_tex, move_regions, std_w, std_h, walk_anim_speed, true)
	SFB.add_regions_animation(frames, "attack", attack_tex, attack_regions, std_w, std_h, attack_anim_speed, false)
	sprite.sprite_frames = frames
