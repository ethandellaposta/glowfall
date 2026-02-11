extends CharacterBody2D

@export var speed: float = 90.0
@export var patrol_distance: float = 240.0
@export var max_hp: int = 3
@export var contact_damage: int = 1

var hp: int
var _dir: int = 1
var _start_x: float
var _damage_cooldown: float = 0.0

func _ready() -> void:
	hp = max_hp
	_start_x = global_position.x
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
	velocity.y += gravity * delta

	if global_position.x > _start_x + patrol_distance:
		_dir = -1
	elif global_position.x < _start_x - patrol_distance:
		_dir = 1

	velocity.x = float(_dir) * speed
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
				break

func take_hit(damage: int, knockback: Vector2) -> void:
	hp -= damage
	velocity += knockback
	if hp <= 0:
		queue_free()
