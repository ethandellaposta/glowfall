extends RefCounted

## Manages player animation state transitions on an AnimatedSprite2D.

const SFB = preload("res://scenes/sprites/SpriteFrameBuilder.gd")

const CROUCH_HOLD_FRAME: int = 9
const CROUCH_SCALE_BIAS: float = 0.8
const HURT_PAD_BIAS: float = 1.0
const SPAWN_SCALE_BIAS: float = 1.05
const HURT_SCALE_BIAS: float = 1.0

var sprite: AnimatedSprite2D

func _init(s: AnimatedSprite2D) -> void:
	sprite = s

func update(facing: int, dying: bool, max_hp: int, hp: int, has_spawned: bool,
		hurt_timer: float, crouch_finishing: bool, crouching: bool,
		attacking: bool, attack_anim: String, on_floor: bool, velocity_x: float) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.flip_h = facing < 0
	if dying or (max_hp > 0 and hp <= 0):
		if sprite.animation != "dying":
			sprite.play("dying")
		return
	if not has_spawned:
		if sprite.animation != "spawning":
			sprite.play("spawning")
		return
	if hurt_timer > 0.0:
		if sprite.animation != "hurting":
			sprite.play("hurting")
		elif not sprite.is_playing():
			sprite.play("hurting")
		return
	if crouch_finishing:
		if sprite.animation != "crouching":
			sprite.play("crouching")
		elif not sprite.is_playing():
			sprite.play()
		return
	if crouching:
		if abs(velocity_x) > 1.0:
			# Crouch-walking
			if sprite.animation != "crouch-walking":
				sprite.play("crouch-walking")
		else:
			# Stationary crouch
			if sprite.animation != "crouching":
				sprite.play("crouching")
			if sprite.sprite_frames != null:
				var frame_count := sprite.sprite_frames.get_frame_count("crouching")
				if frame_count > 0:
					var hold_frame := clampi(CROUCH_HOLD_FRAME, 0, frame_count - 1)
					if sprite.frame >= hold_frame:
						sprite.frame = hold_frame
						if sprite.is_playing():
							sprite.pause()
					elif not sprite.is_playing():
						sprite.play("crouching")
		return
	if attacking:
		if sprite.animation != attack_anim:
			sprite.play(attack_anim)
		return
	if not on_floor:
		if sprite.animation != "jumping":
			sprite.play("jumping")
		return
	if abs(velocity_x) < 1.0:
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	if sprite.animation != "walking":
		sprite.play("walking")

func setup_frames() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var sheet_configs: Array = [
		{"anim": "idle",         "path": "res://gen/robot-idle.png",          "speed": 8.0,  "loop": true},
		{"anim": "walking",      "path": "res://gen/robot-walking.png",       "speed": 18.0, "loop": true},
		{"anim": "jumping",      "path": "res://gen/robot-jumping.png",       "speed": 18.0, "loop": true},
		{"anim": "attack-1-ing", "path": "res://gen/robot-attack-1-ing.png",  "speed": 30.0, "loop": false},
		{"anim": "attack-2-ing", "path": "res://gen/robot-attack-2-ing.png",  "speed": 30.0, "loop": false},
		{"anim": "dying",        "path": "res://gen/robot-dying.png",         "speed": 18.0, "loop": false},
		{"anim": "spawning",     "path": "res://gen/robot-spawning.png",      "speed": 18.0, "loop": false},
		{"anim": "hurting",      "path": "res://gen/robot-hurting.png",       "speed": 18.0, "loop": false},
		{"anim": "crouching",    "path": "res://gen/robot-crouching.png",     "speed": 18.0, "loop": false},
		{"anim": "crouch-walking", "path": "res://gen/robot-crouch-walking.png", "speed": 12.0, "loop": true},
	]

	var frames: SpriteFrames = SpriteFrames.new()
	var baked_anims := ["attack-2-ing", "crouching", "crouch-walking", "hurting", "spawning", "dying"]
	for cfg in sheet_configs:
		var anim_name: String = cfg["anim"]
		if baked_anims.has(anim_name):
			continue
		if anim_name == "walking":
			SFB.add_animation_mode_range(frames, "walking", "walking", 25, 36, cfg["speed"], cfg["loop"])
		else:
			SFB.add_animation_mode(frames, anim_name, anim_name, 36, cfg["speed"], cfg["loop"])
	var std_w := 0
	var std_h := 0
	if frames.has_animation("idle") and frames.get_frame_count("idle") > 0:
		var idle_tex := frames.get_frame_texture("idle", 0)
		if idle_tex != null:
			std_w = idle_tex.get_width()
			std_h = idle_tex.get_height()
	SFB.add_sheet_animation_baked_padded(frames, "attack-2-ing", "res://gen/robot-attack-2-ing.png", 4, 16, 30.0, false, std_w, std_h, 0.85)
	if not frames.has_animation("attack-2-ing") or frames.get_frame_count("attack-2-ing") == 0:
		frames.add_animation("attack-2-ing")
		frames.set_animation_speed("attack-2-ing", 30.0)
		frames.set_animation_loop("attack-2-ing", false)
		if frames.has_animation("attack-1-ing"):
			var a1_count := frames.get_frame_count("attack-1-ing")
			for i in range(a1_count):
				var tex := frames.get_frame_texture("attack-1-ing", i)
				if tex != null:
					frames.add_frame("attack-2-ing", tex)
	SFB.add_sheet_animation_baked_padded(frames, "crouching", "res://gen/robot-crouching.png", 4, 16, 18.0, false, std_w, std_h, CROUCH_SCALE_BIAS)
	SFB.add_sheet_animation_baked_padded(frames, "crouch-walking", "res://gen/robot-crouch-walking.png", 4, 8, 12.0, true, std_w, std_h, CROUCH_SCALE_BIAS)
	var hurt_pad_w := int(round(float(std_w) * HURT_PAD_BIAS))
	var hurt_pad_h := int(round(float(std_h) * HURT_PAD_BIAS))
	SFB.add_sheet_animation_baked_padded(frames, "hurting", "res://gen/robot-hurting.png", 5, 25, 18.0, false, hurt_pad_w, hurt_pad_h, HURT_SCALE_BIAS, true)
	SFB.add_animation_mode_baked_padded(frames, "spawning", "idle", 10, 18.0, false, std_w, std_h, true, 1.0)
	SFB.add_animation_mode_baked_padded(frames, "dying", "idle", 10, 18.0, false, std_w, std_h, true, 1.0)

	# Fallback: any animation with 0 frames gets idle's frames
	var idle_count: int = frames.get_frame_count("idle") if frames.has_animation("idle") else 0
	for cfg in sheet_configs:
		var anim_name: String = cfg["anim"]
		if not frames.has_animation(anim_name) or frames.get_frame_count(anim_name) == 0:
			if not frames.has_animation(anim_name):
				frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, cfg["speed"])
			frames.set_animation_loop(anim_name, cfg["loop"])
			for i in range(idle_count):
				var tex: Texture2D = frames.get_frame_texture("idle", i)
				if tex != null:
					frames.add_frame(anim_name, tex)

	# Extra states that reuse idle
	for extra_anim in ["hurting", "spawning", "dying", "crouching", "crouch-walking"]:
		if not frames.has_animation(extra_anim):
			frames.add_animation(extra_anim)
		frames.set_animation_speed(extra_anim, 18.0)
		frames.set_animation_loop(extra_anim, false)
		if frames.get_frame_count(extra_anim) == 0:
			for i in range(idle_count):
				var tex: Texture2D = frames.get_frame_texture("idle", i)
				if tex != null:
					frames.add_frame(extra_anim, tex)

	sprite.sprite_frames = frames
