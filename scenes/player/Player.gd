extends CharacterBody2D

const PlayerCombatScript = preload("res://scenes/player/PlayerCombat.gd")
const PlayerAnimationScript = preload("res://scenes/player/PlayerAnimation.gd")

# Determines player movement and combat properties
@export var speed := 260.0

# Jump and movement physics
@export var jump_velocity := -700.0

# Ground movement parameters
@export var ground_accel := 1800.0
@export var ground_decel := 2200.0

# Air movement parameters
@export var air_accel := 900.0
@export var air_decel := 400.0

# Jump mechanics
@export var jump_cut_multiplier := 0.4
@export var apex_gravity_mult := 0.4
@export var apex_speed_threshold := 80.0
@export var attack_cooldown := 0.12
@export var attack_2_cooldown := 0.03
@export var attack_damage := 1
@export var attack_knockback := Vector2(260.0, -120.0)
@export var attack_offset := 60.0
@export var power_punch_combo: int = 3
@export var power_punch_damage_mult: float = 3.0
@export var power_punch_knockback_mult: float = 2.0
@export var combo_window: float = 0.5
@export var wheel_radius := 12.0
@export var max_hp: int = 5
@export var hurt_duration := 0.3
@export var death_duration := 0.7
@export var max_soul: int = 99
@export var soul_gain_on_hit: int = 6
@export var soul_catcher_bonus: int = 3
@export var heal_soul_cost: int = 33
@export var heal_amount: int = 1
@export var charge_time: float = 0.5
@export var charge_damage_multiplier: float = 2.0
@export var charge_knockback_multiplier: float = 1.35
@export var charge_cooldown: float = 0.35
@export var crouch_speed := 80.0
@export var crouch_height_ratio := 0.55

@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var wheel: Node2D = $Wheel
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _combat: RefCounted
var _anim: RefCounted
var _jumps_used: int = 0
var _facing: int = 1
var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var _has_spawned: bool = false
var _was_jump_down: bool = false
var _was_attack_down: bool = false
var _was_mouse_attack_down: bool = false
var _attacking: bool = false
var _attack_anim: String = "attack-1-ing"
var _mouse_attack_queued: bool = false
var _mouse_attack_anim: String = "attack-2-ing"
var _attack_buffer_timer: float = 0.0
const ATTACK_BUFFER_WINDOW: float = 0.15
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _crouching: bool = false
var _crouch_finishing: bool = false
var _dying: bool = false
var _spawn_position: Vector2
var _death_timer: float = 0.0
var _death_tween
var hp: int
var soul: int
var _standing_collision_size: Vector2
var _standing_collision_pos: Vector2
var _landing_crouch_timer: float = 0.0
var _pre_land_velocity_y: float = 0.0

# Cached procedural textures (generated once, shared across instances)
static var _cached_glow_tex: ImageTexture
static var _cached_mouse_tex: ImageTexture
var _glow_light: PointLight2D
var _glow_time: float = 0.0
var _screen_flicker_timer: float = 0.0
var _footstep_timer: float = 0.0
var _was_on_floor: bool = true
var _afterimage_timer: float = 0.0
var _eye_particles: GPUParticles2D
var _footstep_particles: GPUParticles2D
var _landing_particles: GPUParticles2D
var _screen_overlay: Polygon2D
var _mouse_light: PointLight2D
var corrupted: bool = false
var _corruption_sparks: GPUParticles2D
var _corruption_arcs: Node2D
var _corruption_arc_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	soul = 0
	_spawn_position = global_position
	_anim = PlayerAnimationScript.new(sprite)
	_anim.setup_frames()
	_combat = PlayerCombatScript.new(self, attack_area, attack_shape)
	if is_instance_valid(sprite):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		sprite.centered = true
		_has_spawned = true
		sprite.animation = "idle"
		sprite.play()
	if is_instance_valid(attack_area):
		attack_area.monitoring = true
		attack_area.monitorable = true
	if is_instance_valid(_collision_shape) and _collision_shape.shape is RectangleShape2D:
		_standing_collision_size = (_collision_shape.shape as RectangleShape2D).size
		_standing_collision_pos = _collision_shape.position
	_setup_visual_effects()

func _setup_visual_effects() -> void:
	# --- Corruption electrical sparks ---
	_corruption_sparks = GPUParticles2D.new()
	_corruption_sparks.name = "CorruptionSparks"
	_corruption_sparks.z_index = 10
	_corruption_sparks.amount = 8
	_corruption_sparks.lifetime = 0.4
	_corruption_sparks.speed_scale = 2.0
	_corruption_sparks.randomness = 0.8
	_corruption_sparks.position = Vector2(0, -20)
	var cspark_mat := ParticleProcessMaterial.new()
	cspark_mat.direction = Vector3(0, 0, 0)
	cspark_mat.spread = 180.0
	cspark_mat.initial_velocity_min = 40.0
	cspark_mat.initial_velocity_max = 120.0
	cspark_mat.gravity = Vector3(0, 50, 0)
	cspark_mat.damping_min = 20.0
	cspark_mat.damping_max = 60.0
	cspark_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	cspark_mat.emission_box_extents = Vector3(25, 35, 0)
	cspark_mat.scale_min = 0.3
	cspark_mat.scale_max = 1.0
	var cspark_grad := Gradient.new()
	cspark_grad.set_color(0, Color(0.7, 0.85, 1.0, 1.0))
	cspark_grad.add_point(0.3, Color(0.4, 0.6, 1.0, 0.9))
	cspark_grad.add_point(0.6, Color(0.6, 0.3, 1.0, 0.6))
	cspark_grad.set_color(1, Color(0.8, 0.4, 1.0, 0.0))
	var cspark_gtex := GradientTexture1D.new()
	cspark_gtex.gradient = cspark_grad
	cspark_mat.color_ramp = cspark_gtex
	_corruption_sparks.process_material = cspark_mat
	_corruption_sparks.emitting = corrupted
	add_child(_corruption_sparks)

	# --- Corruption arc container ---
	_corruption_arcs = Node2D.new()
	_corruption_arcs.name = "CorruptionArcs"
	_corruption_arcs.z_index = 9
	add_child(_corruption_arcs)

	# --- Pulsing glow light ---
	_glow_light = PointLight2D.new()
	_glow_light.name = "PlayerGlow"
	_glow_light.color = Color(0.3, 0.95, 0.7, 1)
	_glow_light.energy = 1.2
	_glow_light.blend_mode = PointLight2D.BLEND_MODE_ADD
	_glow_light.shadow_enabled = false
	if _cached_glow_tex == null:
		var glow_img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var glow_center := Vector2(32, 32)
		var glow_radius := 32.0
		for gy in range(64):
			for gx in range(64):
				var d: float = Vector2(gx, gy).distance_to(glow_center) / glow_radius
				var ga: float = 0.0
				if d < 1.0:
					ga = clampf(1.0 - d * d * d, 0.0, 1.0)
				glow_img.set_pixel(gx, gy, Color(1, 1, 1, ga))
		_cached_glow_tex = ImageTexture.create_from_image(glow_img)
	_glow_light.texture = _cached_glow_tex
	_glow_light.texture_scale = 5.0
	_glow_light.position = Vector2(0, -10)
	add_child(_glow_light)

	# --- Mouse cursor flashlight (single small circle with gradual fade) ---
	_mouse_light = PointLight2D.new()
	_mouse_light.name = "MouseLight"
	_mouse_light.color = Color(0.6, 0.95, 0.8, 1)
	_mouse_light.energy = 0.8
	_mouse_light.blend_mode = PointLight2D.BLEND_MODE_ADD
	_mouse_light.shadow_enabled = false
	if _cached_mouse_tex == null:
		var mimg := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var center := Vector2(32, 32)
		var radius := 32.0
		for y in range(64):
			for x in range(64):
				var dist: float = Vector2(x, y).distance_to(center) / radius
				var a: float = 0.0
				if dist < 1.0:
					a = clampf(1.0 - dist * dist, 0.0, 1.0)
				mimg.set_pixel(x, y, Color(1, 1, 1, a))
		_cached_mouse_tex = ImageTexture.create_from_image(mimg)
	_mouse_light.texture = _cached_mouse_tex
	_mouse_light.texture_scale = 1.2
	add_child(_mouse_light)

	# --- Reveal light child (same position, reveals hidden details on layer 2) ---
	var _reveal_light := PointLight2D.new()
	_reveal_light.name = "RevealLight"
	_reveal_light.color = Color(1, 1, 1, 1)
	_reveal_light.energy = 0.8
	_reveal_light.blend_mode = PointLight2D.BLEND_MODE_ADD
	_reveal_light.shadow_enabled = false
	_reveal_light.range_item_cull_mask = 2
	_reveal_light.texture = _cached_mouse_tex
	_reveal_light.texture_scale = 1.2
	_mouse_light.add_child(_reveal_light)

	# --- Eye/screen glow particles (tiny sparks from the chest screen) ---
	_eye_particles = GPUParticles2D.new()
	_eye_particles.name = "ScreenSparks"
	_eye_particles.z_index = 10
	_eye_particles.amount = 6
	_eye_particles.lifetime = 0.8
	_eye_particles.speed_scale = 1.0
	_eye_particles.randomness = 0.8
	_eye_particles.position = Vector2(0, -15)
	var eye_mat := ParticleProcessMaterial.new()
	eye_mat.direction = Vector3(0, -1, 0)
	eye_mat.spread = 60.0
	eye_mat.initial_velocity_min = 15.0
	eye_mat.initial_velocity_max = 35.0
	eye_mat.gravity = Vector3(0, 20, 0)
	eye_mat.scale_min = 0.3
	eye_mat.scale_max = 0.8
	var eye_grad := Gradient.new()
	eye_grad.set_color(0, Color(0.3, 1.0, 0.8, 0.9))
	eye_grad.add_point(0.3, Color(0.2, 0.9, 0.7, 0.7))
	eye_grad.set_color(1, Color(0.1, 0.6, 0.4, 0.0))
	var eye_tex := GradientTexture1D.new()
	eye_tex.gradient = eye_grad
	eye_mat.color_ramp = eye_tex
	_eye_particles.process_material = eye_mat
	add_child(_eye_particles)

	# --- Footstep spark particles (emit when walking) ---
	_footstep_particles = GPUParticles2D.new()
	_footstep_particles.name = "FootstepSparks"
	_footstep_particles.z_index = 1
	_footstep_particles.amount = 4
	_footstep_particles.lifetime = 0.4
	_footstep_particles.speed_scale = 1.0
	_footstep_particles.emitting = false
	_footstep_particles.one_shot = true
	_footstep_particles.position = Vector2(0, 55)
	var foot_mat := ParticleProcessMaterial.new()
	foot_mat.direction = Vector3(0, -1, 0)
	foot_mat.spread = 70.0
	foot_mat.initial_velocity_min = 20.0
	foot_mat.initial_velocity_max = 50.0
	foot_mat.gravity = Vector3(0, 80, 0)
	foot_mat.scale_min = 0.3
	foot_mat.scale_max = 0.6
	var foot_grad := Gradient.new()
	foot_grad.set_color(0, Color(0.8, 0.6, 0.3, 0.8))
	foot_grad.add_point(0.5, Color(0.6, 0.4, 0.2, 0.5))
	foot_grad.set_color(1, Color(0.4, 0.3, 0.2, 0.0))
	var foot_tex := GradientTexture1D.new()
	foot_tex.gradient = foot_grad
	foot_mat.color_ramp = foot_tex
	_footstep_particles.process_material = foot_mat
	add_child(_footstep_particles)

	# --- Landing dust burst (big puff on landing) ---
	_landing_particles = GPUParticles2D.new()
	_landing_particles.name = "LandingDust"
	_landing_particles.z_index = 1
	_landing_particles.amount = 12
	_landing_particles.lifetime = 0.6
	_landing_particles.speed_scale = 1.0
	_landing_particles.emitting = false
	_landing_particles.one_shot = true
	_landing_particles.position = Vector2(0, 55)
	var land_mat := ParticleProcessMaterial.new()
	land_mat.direction = Vector3(0, -1, 0)
	land_mat.spread = 160.0
	land_mat.initial_velocity_min = 30.0
	land_mat.initial_velocity_max = 80.0
	land_mat.gravity = Vector3(0, 60, 0)
	land_mat.scale_min = 0.5
	land_mat.scale_max = 1.5
	var land_grad := Gradient.new()
	land_grad.set_color(0, Color(0.5, 0.45, 0.35, 0.6))
	land_grad.add_point(0.4, Color(0.4, 0.38, 0.3, 0.35))
	land_grad.set_color(1, Color(0.3, 0.28, 0.22, 0.0))
	var land_tex := GradientTexture1D.new()
	land_tex.gradient = land_grad
	land_mat.color_ramp = land_tex
	_landing_particles.process_material = land_mat
	add_child(_landing_particles)

	# --- Screen overlay (flickers on the chest) ---
	_screen_overlay = Polygon2D.new()
	_screen_overlay.name = "ScreenFlicker"
	_screen_overlay.z_index = 11
	_screen_overlay.color = Color(0.2, 0.95, 0.7, 0.0)
	_screen_overlay.polygon = PackedVector2Array([
		Vector2(-12, -24), Vector2(12, -24),
		Vector2(12, -6), Vector2(-12, -6)
	])
	add_child(_screen_overlay)

func set_spawn_position(pos: Vector2) -> void:
	_spawn_position = pos

func _physics_process(delta: float) -> void:
	_update_visual_effects(delta)
	if _dying or (max_hp > 0 and hp <= 0):
		if _dying:
			_death_timer = maxf(0.0, _death_timer - delta)
			if _death_timer <= 0.0:
				_respawn()
				return
		_update_animation()
		return
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
	# Smooth apex: reduce gravity near the peak of the jump for a floaty feel
	var grav_mult: float = 1.0
	if not is_on_floor() and absf(velocity.y) < apex_speed_threshold:
		grav_mult = apex_gravity_mult
	# Apply gravity
	velocity.y += gravity * grav_mult * delta
	# Variable jump height: cut upward velocity when W is released mid-jump
	if not is_on_floor() and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y = move_toward(velocity.y, 0.0, gravity * jump_cut_multiplier * delta)

	# Horizontal input: WASD only (A/D), no arrow keys.
	var input_dir: float = 0.0
	if Input.is_action_pressed("move_left"):
		input_dir -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir += 1.0
	var target_x: float = input_dir * speed

	# Face toward the mouse cursor if it is meaningfully offset; otherwise
	# fall back to movement direction.
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dx: float = mouse_pos.x - global_position.x
	if absf(dx) > 0.1:
		_facing = 1 if dx > 0.0 else -1
	elif input_dir != 0.0:
		_facing = 1 if input_dir > 0.0 else -1
	if is_instance_valid(attack_area):
		attack_area.position.x = attack_offset * float(_facing)
	if is_on_floor():
		_jumps_used = 0
		if absf(input_dir) > 0.01:
			velocity.x = move_toward(velocity.x, target_x, ground_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	else:
		if absf(input_dir) > 0.01:
			velocity.x = move_toward(velocity.x, target_x, air_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, air_decel * delta)

	# Cancel landing crouch if player starts moving or jumping
	if _landing_crouch_timer > 0.0 and (absf(input_dir) > 0.01 or Input.is_action_pressed("jump")):
		_landing_crouch_timer = 0.0

	# Jump: W key only, with manual edge detection so Space never jumps.
	var max_jumps: int = Global.get_max_jumps()
	var jump_down: bool = Input.is_action_pressed("jump")
	if jump_down and not _was_jump_down and (_jumps_used < max_jumps):
		velocity.y = jump_velocity
		_jumps_used += 1
	_was_jump_down = jump_down

	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer < 0.0:
			_attack_timer = 0.0
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
	var was_crouching := _crouching
	var crouch_down: bool = Input.is_action_pressed("crouch")
	_crouching = crouch_down and is_on_floor() and not _attacking and _hurt_timer <= 0.0
	if _hurt_timer > 0.0 or not is_on_floor():
		_crouch_finishing = false
	elif _crouching:
		_crouch_finishing = false
	elif was_crouching and not _crouching:
		_crouch_finishing = true
	var crouch_blocked := _crouching or _crouch_finishing
	var mouse_down: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var shift_held: bool = Input.is_key_pressed(KEY_SHIFT)  # Shift modifier stays as raw key
	if mouse_down and not _was_mouse_attack_down and not crouch_blocked:
		_mouse_attack_queued = true
		_attack_buffer_timer = ATTACK_BUFFER_WINDOW
		_mouse_attack_anim = "attack-1-ing" if shift_held else "attack-2-ing"
	_was_mouse_attack_down = mouse_down
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer -= delta
		if _attack_buffer_timer <= 0.0:
			_mouse_attack_queued = false
	if crouch_blocked:
		_mouse_attack_queued = false
		_was_attack_down = false
		# Allow slow movement while crouched
		if is_on_floor():
			var crouch_target: float = input_dir * crouch_speed
			if absf(input_dir) > 0.01:
				velocity.x = move_toward(velocity.x, crouch_target, ground_accel * 0.5 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
		# Shrink hitbox while crouching
		_set_crouch_collision(true)
		if _hurt_timer > 0.0:
			_hurt_timer = maxf(0.0, _hurt_timer - delta)
		_update_wheel(delta)
		_update_animation()
		move_and_slide()
		return
	# Restore standing hitbox when not crouching
	_set_crouch_collision(false)
	if _mouse_attack_queued and _attack_timer <= 0.0:
		_mouse_attack_queued = false
		_attack_buffer_timer = 0.0
		_do_attack(_mouse_attack_anim)
		_was_attack_down = false
		if _hurt_timer > 0.0:
			_hurt_timer = maxf(0.0, _hurt_timer - delta)
		_update_wheel(delta)
		_update_animation()
		move_and_slide()
		return
	_was_attack_down = false
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)

	_update_wheel(delta)
	_update_animation()
	move_and_slide()

func _set_crouch_collision(crouching: bool) -> void:
	if not is_instance_valid(_collision_shape) or not (_collision_shape.shape is RectangleShape2D):
		return
	var rect := _collision_shape.shape as RectangleShape2D
	if crouching:
		var crouch_h: float = _standing_collision_size.y * crouch_height_ratio
		rect.size = Vector2(_standing_collision_size.x, crouch_h)
		# Shift collision down so feet stay on the ground
		var height_diff: float = _standing_collision_size.y - crouch_h
		_collision_shape.position = _standing_collision_pos + Vector2(0, height_diff * 0.5)
	else:
		rect.size = _standing_collision_size
		_collision_shape.position = _standing_collision_pos

func _do_attack(anim: String) -> void:
	_attack_timer = attack_2_cooldown if anim == "attack-2-ing" else attack_cooldown
	_attacking = true
	_attack_anim = anim
	if is_instance_valid(sprite) and sprite.sprite_frames != null:
		if not sprite.sprite_frames.has_animation(_attack_anim) or sprite.sprite_frames.get_frame_count(_attack_anim) == 0:
			_attack_anim = "attack-1-ing"
	# Combo tracking — increment and reset window
	_combo_count += 1
	_combo_timer = combo_window
	var is_power_punch: bool = _combo_count >= power_punch_combo
	# Calculate damage and knockback (power punch multipliers)
	var dmg: int = attack_damage
	var kb := attack_knockback
	if is_power_punch:
		dmg = int(ceilf(float(attack_damage) * power_punch_damage_mult))
		kb = attack_knockback * power_punch_knockback_mult
	# Attack lunge — push player forward; power punch lunges harder
	var lunge_speed: float
	if is_power_punch:
		lunge_speed = 300.0
	elif anim == "attack-1-ing":
		lunge_speed = 180.0
	else:
		lunge_speed = 120.0
	velocity.x = float(_facing) * lunge_speed
	# Lean forward during attack-1 + shard + sweep particles
	if anim == "attack-1-ing" and is_instance_valid(sprite):
		var lean_angle: float = deg_to_rad(12.0) * float(_facing)
		var tween := create_tween()
		tween.tween_property(sprite, "rotation", lean_angle, 0.04).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(sprite, "rotation", 0.0, 0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		_spawn_blade_shards()
		_spawn_attack_sweep()
	elif anim == "attack-2-ing" and is_instance_valid(sprite):
		var lean_angle: float = deg_to_rad(8.0) * float(_facing)
		var tween := create_tween()
		tween.tween_property(sprite, "rotation", lean_angle, 0.02).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(sprite, "rotation", 0.0, 0.05).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	# Power punch effects
	if is_power_punch:
		_spawn_power_punch_effect()
		_combo_count = 0
	_update_animation()
	if _combat != null:
		var hits: int = _combat.perform_attack(_facing, dmg, kb)
		if hits > 0:
			var gain: int = soul_gain_on_hit
			if Global.has_charm("soul_catcher"):
				gain += soul_catcher_bonus
			soul = mini(soul + gain * hits, max_soul)

func _spawn_blade_shards() -> void:
	if get_parent() == null:
		return
	var dir: float = float(_facing)
	var origin: Vector2 = global_position + Vector2(dir * 30, -10)
	var shard_count := randi_range(4, 7)
	for i in range(shard_count):
		var shard := Polygon2D.new()
		shard.z_index = 11
		var sw: float = randf_range(1.5, 4.0)
		var sh: float = randf_range(3.0, 10.0)
		shard.polygon = PackedVector2Array([
			Vector2(-sw, -sh), Vector2(sw, -sh * 0.6),
			Vector2(sw * 0.8, sh), Vector2(-sw * 0.5, sh * 0.7)
		])
		shard.color = Color(0.4, 0.95, 0.85, randf_range(0.6, 1.0))
		shard.rotation = randf_range(-0.8, 0.8)
		shard.global_position = origin + Vector2(randf_range(-10, 10), randf_range(-15, 15))
		get_parent().add_child(shard)
		var end_pos: Vector2 = shard.global_position + Vector2(dir * randf_range(40, 100), randf_range(-30, 30))
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "global_position", end_pos, randf_range(0.12, 0.25)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(shard, "modulate:a", 0.0, randf_range(0.15, 0.28)).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "rotation", shard.rotation + randf_range(-1.5, 1.5), 0.25)
		tw.set_parallel(false)
		tw.tween_callback(shard.queue_free)

func _spawn_attack_sweep() -> void:
	if get_parent() == null:
		return
	var dir: float = float(_facing)
	# Horizontal arc showing the full attack-1 reach
	# The attack hitbox is 180px wide centered 60px in front of the player
	var sweep_start_x: float = dir * 10.0
	var sweep_end_x: float = dir * 150.0
	for i in range(6):
		var t: float = float(i) / 5.0
		var arc := Polygon2D.new()
		arc.z_index = 11
		var w: float = randf_range(2.0, 5.0)
		var h: float = randf_range(1.0, 2.5)
		arc.polygon = PackedVector2Array([
			Vector2(-w, -h), Vector2(w, -h),
			Vector2(w, h), Vector2(-w, h)
		])
		var px: float = lerpf(sweep_start_x, sweep_end_x, t)
		var py: float = randf_range(-40.0, 40.0)
		arc.global_position = global_position + Vector2(px, py)
		arc.color = Color(0.4, 0.95, 0.9, randf_range(0.5, 0.9))
		get_parent().add_child(arc)
		var end_pos := arc.global_position + Vector2(dir * randf_range(20, 50), randf_range(-10, 10))
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(arc, "global_position", end_pos, randf_range(0.08, 0.15)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(arc, "modulate:a", 0.0, randf_range(0.1, 0.18)).set_ease(Tween.EASE_IN)
		tw.tween_property(arc, "scale:x", 2.0, 0.15).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
		tw.tween_callback(arc.queue_free)
	# Sweep arc line — a wide slash trail
	var trail := Polygon2D.new()
	trail.z_index = 11
	var arc_pts := PackedVector2Array()
	var segs: int = 8
	for s in range(segs + 1):
		var angle: float = lerpf(-0.6, 0.6, float(s) / float(segs))
		var radius: float = 120.0
		arc_pts.append(Vector2(dir * (cos(angle) * radius + 30.0), sin(angle) * radius * 0.4))
	for s in range(segs, -1, -1):
		var angle: float = lerpf(-0.6, 0.6, float(s) / float(segs))
		var radius: float = 115.0
		arc_pts.append(Vector2(dir * (cos(angle) * radius + 30.0), sin(angle) * radius * 0.4))
	trail.polygon = arc_pts
	trail.color = Color(0.5, 1.0, 0.9, 0.5)
	trail.global_position = global_position
	get_parent().add_child(trail)
	var tw2 := get_tree().create_tween()
	tw2.tween_property(trail, "modulate:a", 0.0, 0.12).set_ease(Tween.EASE_IN)
	tw2.tween_callback(trail.queue_free)

func _spawn_power_punch_effect() -> void:
	if get_parent() == null:
		return
	var dir: float = float(_facing)
	var punch_pos: Vector2 = global_position + Vector2(dir * 80.0, -10.0)
	# Screen shake via camera
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var shake_tw := get_tree().create_tween()
		shake_tw.tween_property(cam, "offset", Vector2(dir * 8, -4), 0.03)
		shake_tw.tween_property(cam, "offset", Vector2(-dir * 4, 3), 0.03)
		shake_tw.tween_property(cam, "offset", Vector2.ZERO, 0.06)
	# Shockwave ring — expanding circle outline
	for ring_i in range(2):
		var ring := Polygon2D.new()
		ring.z_index = 13
		var ring_pts := PackedVector2Array()
		var ring_segs: int = 16
		var outer_r: float = 15.0 + float(ring_i) * 8.0
		var inner_r: float = outer_r - 3.0
		for s in range(ring_segs + 1):
			var a: float = TAU * float(s) / float(ring_segs)
			ring_pts.append(Vector2(cos(a) * outer_r, sin(a) * outer_r))
		for s in range(ring_segs, -1, -1):
			var a: float = TAU * float(s) / float(ring_segs)
			ring_pts.append(Vector2(cos(a) * inner_r, sin(a) * inner_r))
		ring.polygon = ring_pts
		ring.color = Color(1.0, 0.6, 0.1, 0.9)
		ring.global_position = punch_pos
		get_parent().add_child(ring)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		var final_scale: float = 4.0 + float(ring_i) * 2.0
		tw.tween_property(ring, "scale", Vector2(final_scale, final_scale), 0.2 + float(ring_i) * 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ring, "modulate:a", 0.0, 0.25 + float(ring_i) * 0.05).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
		tw.tween_callback(ring.queue_free)
	# Big impact sparks — more and brighter than normal
	for i in range(randi_range(8, 14)):
		var spark := Polygon2D.new()
		spark.z_index = 13
		var sz: float = randf_range(2.5, 6.0)
		spark.polygon = PackedVector2Array([
			Vector2(-sz, -sz * 0.5), Vector2(sz, -sz * 0.5),
			Vector2(sz, sz * 0.5), Vector2(-sz, sz * 0.5)
		])
		var hue: float = randf_range(0.05, 0.12)
		spark.color = Color.from_hsv(hue, randf_range(0.6, 1.0), 1.0, 1.0)
		spark.global_position = punch_pos + Vector2(randf_range(-10, 10), randf_range(-15, 15))
		spark.rotation = randf_range(-1.0, 1.0)
		get_parent().add_child(spark)
		var end_pos := spark.global_position + Vector2(dir * randf_range(30, 120), randf_range(-60, 60))
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "global_position", end_pos, randf_range(0.12, 0.25)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(spark, "modulate:a", 0.0, randf_range(0.15, 0.3)).set_ease(Tween.EASE_IN)
		tw.tween_property(spark, "rotation", spark.rotation + randf_range(-2.0, 2.0), 0.25)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)
	# Floating damage number
	var dmg_label := Polygon2D.new()
	dmg_label.z_index = 15
	# "POW" text approximated as a bold block
	dmg_label.polygon = PackedVector2Array([
		Vector2(-18, -8), Vector2(18, -8),
		Vector2(18, 8), Vector2(-18, 8)
	])
	dmg_label.color = Color(1.0, 0.3, 0.1, 1.0)
	dmg_label.global_position = punch_pos + Vector2(0, -30)
	get_parent().add_child(dmg_label)
	var dtw := get_tree().create_tween()
	dtw.set_parallel(true)
	dtw.tween_property(dmg_label, "global_position:y", dmg_label.global_position.y - 50.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	dtw.tween_property(dmg_label, "scale", Vector2(1.5, 1.5), 0.08).set_ease(Tween.EASE_OUT)
	dtw.tween_property(dmg_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.15)
	dtw.set_parallel(false)
	dtw.tween_callback(dmg_label.queue_free)

func _update_visual_effects(delta: float) -> void:
	_glow_time += delta
	var spd: float = velocity.length()
	var moving: bool = absf(velocity.x) > 10.0
	var on_floor_now: bool = is_on_floor()

	# --- Pulsing glow: breathes slowly, intensifies when moving ---
	if is_instance_valid(_glow_light):
		var base_energy: float = 0.9
		var pulse: float = sin(_glow_time * 2.5) * 0.15
		var move_boost: float = clampf(spd / 400.0, 0.0, 0.4)
		_glow_light.energy = base_energy + pulse + move_boost
		# Slight color shift when moving fast
		var t: float = clampf(spd / 500.0, 0.0, 1.0)
		_glow_light.color = Color(
			lerpf(0.3, 0.4, t),
			lerpf(0.9, 0.85, t),
			lerpf(0.7, 0.9, t),
			1.0
		)
		# Scale grows slightly when moving
		_glow_light.texture_scale = lerpf(4.5, 6.0, t)

	# --- Screen flicker overlay ---
	if is_instance_valid(_screen_overlay):
		_screen_flicker_timer += delta
		# Random flicker pulses
		var flicker_alpha: float = 0.0
		if fmod(_screen_flicker_timer, 0.15) < 0.03:
			flicker_alpha = randf_range(0.05, 0.2)
		if _attacking:
			flicker_alpha = randf_range(0.15, 0.35)
		if _hurt_timer > 0.0:
			flicker_alpha = randf_range(0.2, 0.5)
			_screen_overlay.color = Color(1.0, 0.3, 0.2, flicker_alpha)
		else:
			_screen_overlay.color = Color(0.2, 0.95, 0.7, flicker_alpha)

	# --- Eye/screen sparks: more when attacking or hurt ---
	if is_instance_valid(_eye_particles):
		var eye_mat: ParticleProcessMaterial = _eye_particles.process_material as ParticleProcessMaterial
		if eye_mat:
			if _attacking:
				eye_mat.initial_velocity_max = 50.0
				_eye_particles.amount = 6
			elif _hurt_timer > 0.0:
				eye_mat.initial_velocity_max = 60.0
				_eye_particles.amount = 8
			else:
				eye_mat.initial_velocity_max = 30.0
				_eye_particles.amount = 4

	# --- Footstep sparks: periodic bursts while walking on floor ---
	if moving and on_floor_now:
		_footstep_timer += delta
		if _footstep_timer >= 0.15:
			_footstep_timer = 0.0
			if is_instance_valid(_footstep_particles):
				_footstep_particles.restart()
				_footstep_particles.emitting = true
	else:
		_footstep_timer = 0.0

	# --- Landing dust burst + shock absorption crouch ---
	if on_floor_now and not _was_on_floor:
		if is_instance_valid(_landing_particles):
			_landing_particles.restart()
			_landing_particles.emitting = true
		# Landing squash effect with smooth bezier easing
		if is_instance_valid(sprite):
			var tween := create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.7, 1.3), 0.07).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(sprite, "scale", Vector2(1.4, 1.6), 0.07).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# Shock absorption crouch — quick and subtle, scales with fall speed
		var fall_speed: float = maxf(_pre_land_velocity_y, 0.0)
		if fall_speed > 400.0:
			var crouch_dur: float = clampf((fall_speed - 400.0) / 1200.0, 0.04, 0.25)
			_landing_crouch_timer = crouch_dur
	if not on_floor_now:
		_pre_land_velocity_y = velocity.y
	_was_on_floor = on_floor_now

	# --- Landing crouch timer countdown ---
	if _landing_crouch_timer > 0.0:
		_landing_crouch_timer -= delta
		if _landing_crouch_timer <= 0.0:
			_landing_crouch_timer = 0.0

	# --- Faint silhouette trail when moving ---
	if spd > 200.0:
		_afterimage_timer += delta
		if _afterimage_timer >= 0.18:
			_afterimage_timer = 0.0
			_spawn_afterimage()
	else:
		_afterimage_timer = 0.0

	# --- Mouse cursor light follows mouse ---
	if is_instance_valid(_mouse_light):
		var mouse_pos: Vector2 = get_global_mouse_position()
		_mouse_light.global_position = mouse_pos

	# --- Reset vertical sprite offset when not idle-bobbing ---
	if is_instance_valid(sprite):
		sprite.offset.y = lerpf(sprite.offset.y, 0.0, 0.2)

	# --- Reset sprite offset and rotation ---
	if is_instance_valid(sprite):
		sprite.offset.x = lerpf(sprite.offset.x, 0.0, 0.2)
		var move_lean: float = clampf(velocity.x / speed, -1.0, 1.0) * deg_to_rad(2.0)
		sprite.rotation = lerpf(sprite.rotation, move_lean, 0.15)

	# --- Corruption electrical arcs ---
	if corrupted:
		if is_instance_valid(_corruption_sparks):
			_corruption_sparks.emitting = true
		# Shift glow color to corrupted purple/blue
		if is_instance_valid(_glow_light):
			var corrupt_pulse: float = 0.5 + sin(_glow_time * 4.0) * 0.3
			_glow_light.color = Color(0.5, 0.3, 0.95, 1).lerp(Color(0.3, 0.6, 1.0, 1), corrupt_pulse)
			_glow_light.energy = 1.0 + sin(_glow_time * 6.0) * 0.4
		# Spawn jagged electrical arcs periodically
		_corruption_arc_timer += delta
		if _corruption_arc_timer >= 0.15 and is_instance_valid(_corruption_arcs):
			_corruption_arc_timer = 0.0
			if _corruption_arcs.get_child_count() < 8:
				_spawn_corruption_arc()
		# Clean up old arcs
		if is_instance_valid(_corruption_arcs):
			for child in _corruption_arcs.get_children():
				if child.has_meta("life"):
					var life: float = child.get_meta("life") - delta
					if life <= 0.0:
						child.queue_free()
					else:
						child.set_meta("life", life)
						child.modulate.a = maxf(0.0, life / 0.15)
	else:
		if is_instance_valid(_corruption_sparks):
			_corruption_sparks.emitting = false
		if is_instance_valid(_corruption_arcs):
			for child in _corruption_arcs.get_children():
				child.queue_free()

func _spawn_corruption_arc() -> void:
	var arc := Polygon2D.new()
	arc.z_index = 9
	# Random start point on the player body
	var sx: float = randf_range(-20, 20)
	var sy: float = randf_range(-50, 30)
	# Random end point nearby
	var ex: float = sx + randf_range(-35, 35)
	var ey: float = sy + randf_range(-35, 35)
	# Build jagged lightning path
	var pts := PackedVector2Array()
	var segs: int = randi_range(3, 6)
	var w: float = randf_range(1.0, 2.5)
	for s in range(segs + 1):
		var t: float = float(s) / float(segs)
		var px: float = lerpf(sx, ex, t) + randf_range(-8, 8)
		var py: float = lerpf(sy, ey, t) + randf_range(-6, 6)
		pts.append(Vector2(px - w, py))
	for s in range(segs, -1, -1):
		var t: float = float(s) / float(segs)
		var px: float = lerpf(sx, ex, t) + randf_range(-8, 8)
		var py: float = lerpf(sy, ey, t) + randf_range(-6, 6)
		pts.append(Vector2(px + w, py))
	# Random color between electric blue and purple
	var hue: float = randf_range(0.6, 0.8)
	arc.color = Color.from_hsv(hue, randf_range(0.4, 0.8), 1.0, randf_range(0.5, 0.9))
	arc.polygon = pts
	arc.set_meta("life", 0.15)
	_corruption_arcs.add_child(arc)

func _spawn_afterimage() -> void:
	if not is_instance_valid(sprite) or get_parent() == null:
		return
	var ghost := Polygon2D.new()
	ghost.z_index = -1
	# Very faint silhouette — no glow, just a light shape
	ghost.color = Color(0.15, 0.15, 0.18, 0.06)
	ghost.global_position = global_position
	ghost.polygon = PackedVector2Array([
		Vector2(-16, -42), Vector2(16, -42),
		Vector2(12, 48), Vector2(-12, 48)
	])
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

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
	if _anim != null:
		var is_landing_crouch: bool = _landing_crouch_timer > 0.0 and is_on_floor()
		_anim.update(_facing, _dying, max_hp, hp, _has_spawned, _hurt_timer,
				_crouch_finishing, _crouching or is_landing_crouch, _attacking, _attack_anim,
				is_on_floor(), velocity.x)


func _on_sprite_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.animation == "spawning":
		_has_spawned = true
		sprite.play("idle")
	elif sprite.animation == "attack-1-ing" or sprite.animation == "attack-2-ing":
		_attacking = false
		# If player buffered another attack, fire it immediately for combo flow
		if _mouse_attack_queued and _attack_timer <= 0.0:
			_mouse_attack_queued = false
			_attack_buffer_timer = 0.0
			_do_attack(_mouse_attack_anim)
	elif sprite.animation == "crouching" and _crouch_finishing:
		_crouch_finishing = false
		_update_animation()

func _respawn() -> void:
	_dying = false
	_death_timer = 0.0
	if _death_tween != null:
		_death_tween.kill()
		_death_tween = null
	modulate = Color(1, 1, 1, 1)
	hp = max_hp
	velocity = Vector2.ZERO
	_attack_timer = 0.0
	_hurt_timer = 0.0
	_attacking = false
	global_position = _spawn_position
	_has_spawned = false
	if is_instance_valid(sprite):
		sprite.play("spawning")

func take_damage(damage: int, dir: int) -> void:
	if max_hp <= 0:
		return
	if hp <= 0:
		return
	hp -= damage
	_hurt_timer = hurt_duration
	velocity.x = speed * -float(dir) * 0.5
	# Hit flash
	if is_instance_valid(sprite):
		var hit_tw := create_tween()
		hit_tw.tween_property(sprite, "modulate", Color(3.0, 0.5, 0.4, 1.0), 0.04)
		hit_tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.12)
	if hp < 0:
		hp = 0
	if hp <= 0:
		_dying = true
		_death_timer = death_duration
		if _death_tween != null:
			_death_tween.kill()
		_death_tween = create_tween()
		_death_tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 1), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_death_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), maxf(0.0, death_duration - 0.1)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		velocity = Vector2.ZERO
		_attack_timer = 0.0
		_hurt_timer = 0.0
		_attacking = false
		if is_instance_valid(sprite):
			sprite.play("dying")
