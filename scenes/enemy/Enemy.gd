extends CharacterBody2D

const EnemySpriteSetupScript = preload("res://scenes/enemy/EnemySpriteSetup.gd")

@export var speed: float = 90.0
@export var patrol_distance: float = 240.0
@export var max_hp: int = 3
@export var contact_damage: int = 1

@export var walk_anim_speed: float = 18.0
@export var attack_anim_speed: float = 24.0
@export var sprite_scale: float = 0.35

# Enhanced AI behaviors
@export var detection_range: float = 120.0
@export var chase_speed_multiplier: float = 1.8
@export var attack_range: float = 60.0
@export var leap_cooldown: float = 2.5
@export var leap_force: float = 400.0
@export var group_behavior: bool = true  # Coordinate with nearby enemies

var hp: int
var _dir: int = 1
var _start_x: float
var _damage_cooldown: float = 0.0
var _state: EnemyState = EnemyState.PATROL
var _player_ref: CharacterBody2D
var _last_player_pos: Vector2
var _leap_timer: float = 0.0
var _aggression_timer: float = 0.0
var _stun_timer: float = 0.0

enum EnemyState {
	PATROL,
	CHASE,
	ATTACK,
	LEAP,
	STUNNED,
	RETREAT
}

@onready var sprite: AnimatedSprite2D = $Sprite

var _attacking: bool = false
var _dying: bool = false
var _bob_time: float = 0.0
const BOB_AMPLITUDE: float = 3.0
const BOB_FREQUENCY: float = 8.0

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	add_to_group("enemies")
	var sprite_setup := EnemySpriteSetupScript.new(sprite)
	sprite_setup.setup(walk_anim_speed, attack_anim_speed, sprite_scale)
	if is_instance_valid(sprite):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		if sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count("walk") > 0:
			sprite.play("walk")

func _find_player() -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game != null:
		_player_ref = game.get_node_or_null("Player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if hp <= 0 or _dying:
		return

	# Find player reference if we don't have one
	if not is_instance_valid(_player_ref):
		_find_player()

	# Update AI state machine
	_update_state(delta)

	# Tick timers
	if _leap_timer > 0.0:
		_leap_timer -= delta
	if _aggression_timer > 0.0:
		_aggression_timer -= delta
	if _stun_timer > 0.0:
		_stun_timer -= delta

	# Execute behavior based on current state
	match _state:
		EnemyState.PATROL:
			_execute_patrol(delta)
		EnemyState.CHASE:
			_execute_chase(delta)
		EnemyState.ATTACK:
			_execute_attack(delta)
		EnemyState.LEAP:
			_execute_leap(delta)
		EnemyState.STUNNED:
			_execute_stunned(delta)
		EnemyState.RETREAT:
			_execute_retreat(delta)

	# Apply gravity
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") as float * delta

	_update_animation()
	_update_bob(delta)
	move_and_slide()

	if _damage_cooldown > 0.0:
		_damage_cooldown = maxf(0.0, _damage_cooldown - delta)

	if _damage_cooldown <= 0.0:
		var slide_count := get_slide_collision_count()
		for i in range(slide_count):
			var col := get_slide_collision(i)
			var other := col.get_collider()
			if other != null and other.has_method("take_damage"):
				other.call("take_damage", contact_damage, _dir)
				_damage_cooldown = 0.5
				_play_attack()
func _update_state(delta: float) -> void:
	if _stun_timer > 0.0:
		_state = EnemyState.STUNNED
		return

	var player_dist := _get_player_distance()
	var can_see_player := player_dist <= detection_range and _has_line_of_sight()

	match _state:
		EnemyState.PATROL:
			if can_see_player:
				_state = EnemyState.CHASE
				_aggression_timer = 5.0  # Stay aggressive for 5 seconds
				if group_behavior:
					_alert_nearby_enemies()
		EnemyState.CHASE:
			if not can_see_player and _aggression_timer <= 0.0:
				_state = EnemyState.PATROL
			elif player_dist <= attack_range:
				_state = EnemyState.ATTACK
			elif player_dist > detection_range * 1.5 and _leap_timer <= 0.0:
				_state = EnemyState.LEAP
				_leap_timer = leap_cooldown
		EnemyState.ATTACK:
			if player_dist > attack_range * 1.5:
				if can_see_player:
					_state = EnemyState.CHASE
				else:
					_state = EnemyState.PATROL
		EnemyState.LEAP:
			if is_on_floor():
				if can_see_player:
					_state = EnemyState.CHASE
				else:
					_state = EnemyState.PATROL
		EnemyState.RETREAT:
			if hp > max_hp * 0.5:
				_state = EnemyState.PATROL
			elif can_see_player:
				_state = EnemyState.CHASE

func _get_player_distance() -> float:
	if not is_instance_valid(_player_ref):
		return INF
	return global_position.distance_to(_player_ref.global_position)

func _has_line_of_sight() -> bool:
	if not is_instance_valid(_player_ref):
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, _player_ref.global_position)
	query.collision_mask = 1  # Only check walls/obstacles
	var result := space_state.intersect_ray(query)
	return result.is_empty()

func _alert_nearby_enemies() -> void:
	if not group_behavior:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and enemy.has_method("_alert"):
			var dist := global_position.distance_to(enemy.global_position)
			if dist <= detection_range * 1.5:
				enemy.call("_alert", _player_ref.global_position)

func _alert(player_pos: Vector2) -> void:
	if _state == EnemyState.PATROL:
		_state = EnemyState.CHASE
		_aggression_timer = 3.0
		_last_player_pos = player_pos

func _execute_patrol(delta: float) -> void:
	if global_position.x > _start_x + patrol_distance:
		_dir = -1
	elif global_position.x < _start_x - patrol_distance:
		_dir = 1
	velocity.x = float(_dir) * speed

func _execute_chase(delta: float) -> void:
	if not is_instance_valid(_player_ref):
		_state = EnemyState.PATROL
		return

	var dir_to_player := (_player_ref.global_position - global_position).normalized()
	velocity.x = dir_to_player.x * speed * chase_speed_multiplier
	_dir = 1 if velocity.x > 0 else -1

func _execute_attack(delta: float) -> void:
	velocity.x = 0
	if not _attacking:
		_play_attack()

func _execute_leap(delta: float) -> void:
	if is_on_floor() and velocity.y == 0:
		# Perform leap towards player
		if is_instance_valid(_player_ref):
			var leap_dir := (_player_ref.global_position - global_position).normalized()
			velocity = leap_dir * leap_force
			velocity.y = -leap_force * 0.8  # Arc the jump

func _execute_stunned(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * 2.0 * delta)

func _execute_retreat(delta: float) -> void:
	if not is_instance_valid(_player_ref):
		_state = EnemyState.PATROL
		return

	var dir_away := (global_position - _player_ref.global_position).normalized()
	velocity.x = dir_away.x * speed * 1.5
	_dir = 1 if velocity.x > 0 else -1

func take_hit(damage: int, knockback: Vector2) -> void:
	if _dying:
		return
	hp -= damage
	velocity += knockback
	_flash_hit()
	# Brief stun on hit so enemies react to being struck
	_stun_timer = 0.3
	_state = EnemyState.STUNNED
	if hp <= 0:
		_dying = true
		velocity = Vector2.ZERO
		_play_death_effect()

func _flash_hit() -> void:
	if not is_instance_valid(sprite):
		return
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(4.0, 1.5, 1.5, 1.0), 0.04)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)

func _update_animation() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.sprite_frames == null:
		return
	if _dying:
		return
	sprite.flip_h = _dir < 0
	if _attacking:
		if sprite.sprite_frames.has_animation("attack") and sprite.animation != "attack":
			sprite.play("attack")
		return
	if absf(velocity.x) > 1.0:
		if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play("idle")

func _update_bob(delta: float) -> void:
	if not is_instance_valid(sprite):
		return
	if absf(velocity.x) > 1.0 and not _attacking:
		_bob_time += delta * BOB_FREQUENCY
		sprite.offset.y = sin(_bob_time) * BOB_AMPLITUDE
	else:
		_bob_time = 0.0
		sprite.offset.y = 0.0

func _play_death_effect() -> void:
	if is_instance_valid(sprite):
		sprite.stop()
	_spawn_death_particles()
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(3.0, 0.5, 0.3, 1), 0.06)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.06)
	tween.tween_property(self, "modulate", Color(2.0, 0.3, 0.2, 1), 0.06)
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.8, 1.2), 0.06)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _spawn_death_particles() -> void:
	if get_parent() == null:
		return
	for i in range(randi_range(6, 10)):
		var shard := Polygon2D.new()
		shard.z_index = 10
		var sw: float = randf_range(2, 6)
		var sh: float = randf_range(4, 12)
		shard.polygon = PackedVector2Array([
			Vector2(-sw, -sh), Vector2(sw, -sh * 0.6),
			Vector2(sw * 0.8, sh), Vector2(-sw * 0.5, sh * 0.7)
		])
		var hue: float = randf_range(0.0, 0.08)
		shard.color = Color.from_hsv(hue, randf_range(0.6, 0.9), randf_range(0.7, 1.0), randf_range(0.7, 1.0))
		shard.rotation = randf_range(-1.0, 1.0)
		shard.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-20, 10))
		get_parent().add_child(shard)
		var end_pos := shard.global_position + Vector2(randf_range(-60, 60), randf_range(-80, -20))
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "global_position", end_pos, randf_range(0.2, 0.4)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(shard, "modulate:a", 0.0, randf_range(0.25, 0.45)).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "rotation", shard.rotation + randf_range(-2.0, 2.0), 0.4)
		tw.set_parallel(false)
		tw.tween_callback(shard.queue_free)

func _play_attack() -> void:
	_attacking = true
	_update_animation()

func _on_sprite_animation_finished() -> void:
	if not is_instance_valid(sprite):
		return
	if sprite.animation == "attack":
		_attacking = false

