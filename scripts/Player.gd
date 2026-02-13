extends CharacterBody2D

@export var speed := 260.0
@export var jump_velocity := -420.0
@export var air_control := 0.85
@export var attack_cooldown := 0.25
@export var attack_damage := 1
@export var attack_knockback := Vector2(260.0, -120.0)
@export var wheel_radius := 12.0
@export var max_hp: int = 5
@export var hurt_duration := 0.4

@onready var attack_area: Area2D = $AttackArea
@onready var wheel: Node2D = $Wheel
@onready var sprite: AnimatedSprite2D = $Sprite

var _jumps_used: int = 0
var _facing: int = 1
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var _has_spawned: bool = false
var _was_jump_down: bool = false
var _was_attack_down: bool = false
var _attacking: bool = false
var hp: int

func _ready() -> void:
	hp = max_hp
	_setup_sprite_frames()
	if is_instance_valid(sprite):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		sprite.centered = true
		_has_spawned = true
		sprite.animation = "idle"
		sprite.play()

func _physics_process(delta: float) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
	velocity.y += gravity * delta

	# Horizontal input: WASD only (A/D), no arrow keys.
	var input_dir: float = 0.0
	if Input.is_key_pressed(KEY_A):
		input_dir -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir += 1.0
	var target_x: float = input_dir * speed

	# Face toward the mouse cursor if it is meaningfully offset; otherwise
	# fall back to movement direction.
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dx: float = mouse_pos.x - global_position.x
	if absf(dx) > 2.0:
		_facing = 1 if dx > 0.0 else -1
	elif input_dir != 0.0:
		_facing = 1 if input_dir > 0.0 else -1
	if is_instance_valid(attack_area):
		attack_area.position.x = 24.0 * float(_facing)
	if is_on_floor():
		velocity.x = target_x
		_jumps_used = 0
	else:
		velocity.x = lerp(velocity.x, target_x, air_control)

	# Jump: W key only, with manual edge detection so Space never jumps.
	var max_jumps: int = Global.get_max_jumps()
	var jump_down: bool = Input.is_key_pressed(KEY_W)
	if jump_down and not _was_jump_down and (_jumps_used < max_jumps):
		velocity.y = jump_velocity
		_jumps_used += 1
	_was_jump_down = jump_down

	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer < 0.0:
			_attack_timer = 0.0
	# Attack: Space bar (and optional attack action) with manual edge detection.
	var attack_down: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("attack")
	if attack_down and not _was_attack_down and _attack_timer <= 0.0:
		_do_attack()
	_was_attack_down = attack_down
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)

	_update_wheel(delta)
	_update_animation()
	move_and_slide()

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	_attacking = true
	if not is_instance_valid(attack_area):
		return
	var bodies: Array = attack_area.get_overlapping_bodies()
	for b in bodies:
		if is_instance_valid(b) and b.has_method("take_hit"):
			var dir := float(_facing)
			var knockback := Vector2(attack_knockback.x * dir, attack_knockback.y)
			b.call("take_hit", attack_damage, knockback)

func _update_wheel(delta: float) -> void:
	if not is_instance_valid(wheel):
		return
	if wheel_radius <= 0.0:
		return
	var vx: float = velocity.x
	if vx == 0.0:
		return
	wheel.rotation -= (vx / wheel_radius) * delta

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.flip_h = _facing < 0
	if max_hp > 0 and hp <= 0:
		if sprite.animation != "dying":
			sprite.play("dying")
		return
	if not _has_spawned:
		if sprite.animation != "spawning":
			sprite.play("spawning")
		return
	if _hurt_timer > 0.0:
		if sprite.animation != "hurting":
			sprite.play("hurting")
		return
	if _attacking:
		if sprite.animation != "attack-1-ing":
			sprite.play("attack-1-ing")
		return
	if not is_on_floor():
		if sprite.animation != "jumping":
			sprite.play("jumping")
		return
	if abs(velocity.x) < 1.0:
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	if sprite.animation != "walking":
		sprite.play("walking")

func _setup_sprite_frames() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var sheet_configs: Array = [
		{"anim": "idle",         "path": "res://gen/robot-idle.png",          "speed": 8.0,  "loop": true},
		{"anim": "walking",      "path": "res://gen/robot-walking.png",       "speed": 18.0, "loop": true},
		{"anim": "jumping",      "path": "res://gen/robot-jumping.png",       "speed": 18.0, "loop": true},
		{"anim": "attack-1-ing", "path": "res://gen/robot-attack-1-ing.png",  "speed": 30.0, "loop": false},
	]

	var frames: SpriteFrames = SpriteFrames.new()
	for cfg in sheet_configs:
		if cfg["anim"] == "walking":
			_add_animation_mode_range(frames, "walking", "walking", 25, 36, cfg["speed"], cfg["loop"])
		else:
			_add_animation_mode(frames, cfg["anim"], cfg["anim"], 36, cfg["speed"], cfg["loop"])

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
	for extra_anim in ["hurting", "spawning", "dying"]:
		frames.add_animation(extra_anim)
		frames.set_animation_speed(extra_anim, 8.0)
		frames.set_animation_loop(extra_anim, false)
		for i in range(idle_count):
			var tex: Texture2D = frames.get_frame_texture("idle", i)
			if tex != null:
				frames.add_frame(extra_anim, tex)

	sprite.sprite_frames = frames

func _add_animation_mode(frames: SpriteFrames, anim_name: String, mode_name: String, frame_count: int, speed: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var path: String = "res://assets/robot/robot_%s_%02d.png" % [mode_name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			break
		frames.add_frame(anim_name, tex)

func _add_animation_mode_range(
		frames: SpriteFrames,
		anim_name: String,
		mode_name: String,
		start_frame: int,
		end_frame_exclusive: int,
		speed: float,
		loop: bool
	) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(start_frame, end_frame_exclusive):
		var path: String = "res://assets/robot/robot_%s_%02d.png" % [mode_name, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			break
		frames.add_frame(anim_name, tex)

func _add_sheet_animation(
		frames: SpriteFrames,
		anim_name: String,
		sheet_path: String,
		cols: int,
		frame_count: int,
		speed: float,
		loop: bool
	) -> void:
	if cols <= 0 or frame_count <= 0:
		return
	if not ResourceLoader.exists(sheet_path):
		return
	var sheet_tex: Texture2D = load(sheet_path) as Texture2D
	if sheet_tex == null:
		return
	var sheet_w: int = sheet_tex.get_width()
	var sheet_h: int = sheet_tex.get_height()
	if sheet_w <= 0 or sheet_h <= 0:
		return
	var frame_w: int = sheet_w / cols
	if frame_w <= 0:
		return
	var rows: int = int(ceil(float(frame_count) / float(cols)))
	if rows <= 0:
		return
	var frame_h: int = sheet_h / rows
	if frame_h <= 0:
		return

	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var row: int = i / cols
		var col: int = i % cols
		var region := Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_tex
		atlas.region = region
		atlas.filter_clip = true
		frames.add_frame(anim_name, atlas)

func _on_sprite_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.animation == "spawning":
		_has_spawned = true
		sprite.play("idle")
	elif sprite.animation == "attack-1-ing":
		_attacking = false

func take_damage(damage: int, dir: int) -> void:
	if max_hp <= 0:
		return
	if hp <= 0:
		return
	hp -= damage
	_hurt_timer = hurt_duration
	velocity.x = speed * -float(dir) * 0.5
	if hp < 0:
		hp = 0
