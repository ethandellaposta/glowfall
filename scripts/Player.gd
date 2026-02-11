extends CharacterBody2D

@export var speed := 260.0
@export var jump_velocity := -420.0
@export var air_control := 0.85
@export var attack_cooldown := 0.25
@export var attack_damage := 1
@export var attack_knockback := Vector2(260.0, -120.0)
@export var wheel_radius := 12.0

@onready var attack_area: Area2D = $AttackArea
@onready var wheel: Node2D = $Wheel

var _jumps_used := 0
var _facing := 1
var _attack_timer := 0.0

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
	
	_update_wheel(delta)
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
