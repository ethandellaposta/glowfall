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

var _jumps_used := 0
var _facing := 1
var _attack_timer := 0.0
var _hurt_timer := 0.0
var _has_spawned := false
var hp: int

func _ready() -> void:
	hp = max_hp
	_setup_sprite_frames()
	if is_instance_valid(sprite):
		sprite.animation = "spawning"
		sprite.play()
		sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
	velocity.y += gravity * delta

	var input_dir := Input.get_axis("ui_left", "ui_right")
	var target_x := input_dir * speed
	if input_dir != 0.0:
		_facing = 1 if input_dir > 0.0 else -1
	if is_instance_valid(attack_area):
		attack_area.position.x = 24.0 * float(_facing)
	if is_on_floor():
		velocity.x = target_x
		_jumps_used = 0
	else:
		velocity.x = lerp(velocity.x, target_x, air_control)

	var max_jumps := Global.get_max_jumps()
	if Input.is_action_just_pressed("ui_accept") and (_jumps_used < max_jumps):
		velocity.y = jump_velocity
		_jumps_used += 1

	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer < 0.0:
			_attack_timer = 0.0
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
		_do_attack()
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)

	_update_wheel(delta)
	_update_animation()
	move_and_slide()

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	if not is_instance_valid(attack_area):
		return
	var bodies := attack_area.get_overlapping_bodies()
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
	var vx := velocity.x
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
	if _attack_timer > 0.0:
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
	var frames := SpriteFrames.new()
	_add_animation_mode(frames, "idle", "idle", 5, 6.0, true)
	_add_animation_mode(frames, "walking", "walking", 5, 10.0, true)
	_add_animation_mode(frames, "attack-1-ing", "attack-1-ing", 5, 12.0, false)
	_add_animation_mode(frames, "jumping", "jumping", 5, 8.0, true)
	_add_animation_mode(frames, "hurting", "hurting", 5, 10.0, false)
	_add_animation_mode(frames, "spawning", "spawning", 5, 10.0, false)
	_add_animation_mode(frames, "dying", "dying", 5, 8.0, false)
	sprite.frames = frames

func _add_animation_mode(frames: SpriteFrames, anim_name: String, mode_name: String, frame_count: int, speed: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var path := "res://assets/textures/robot_%s_%02d.png" % [mode_name, i]
		var tex := load(path)
		if tex != null:
			frames.add_frame(anim_name, tex)

func _on_sprite_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.animation == "spawning":
		_has_spawned = true
		sprite.play("idle")

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
