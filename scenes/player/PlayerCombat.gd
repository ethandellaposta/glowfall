extends RefCounted

## Handles player melee attack logic: hit detection via physics shape queries.

var player: CharacterBody2D
var attack_area: Area2D
var attack_shape: CollisionShape2D

func _init(p: CharacterBody2D, area: Area2D, shape: CollisionShape2D) -> void:
	player = p
	attack_area = area
	attack_shape = shape

func perform_attack(facing: int, damage: int, knockback: Vector2) -> int:
	if not is_instance_valid(attack_area):
		return 0
	var world := player.get_world_2d()
	if world == null:
		return 0
	var space_state := world.direct_space_state
	if space_state == null:
		return 0
	if not is_instance_valid(attack_shape) or attack_shape.shape == null:
		return 0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape.shape
	query.transform = attack_area.global_transform
	query.exclude = [player]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = attack_area.collision_mask
	var hits: Array = space_state.intersect_shape(query, 32)
	var hit_count: int = 0
	for h in hits:
		var b: Object = h.get("collider") as Object
		if b != null and is_instance_valid(b) and b.has_method("take_hit"):
			var dir := float(facing)
			var kb := Vector2(knockback.x * dir, knockback.y)
			if b is Node2D:
				_spawn_hit_marker((b as Node2D).global_position, facing)
			b.call("take_hit", damage, kb)
			hit_count += 1
	return hit_count

func _spawn_hit_marker(hit_pos: Vector2, facing: int) -> void:
	var scene_root := player.get_parent()
	if scene_root == null:
		return
	var dir := float(facing)
	# Slash lines — 3 angled streaks
	for i in range(3):
		var slash := Polygon2D.new()
		slash.z_index = 12
		var length: float = randf_range(18.0, 40.0)
		var width: float = randf_range(1.5, 3.5)
		slash.polygon = PackedVector2Array([
			Vector2(-width, -length * 0.5),
			Vector2(width, -length * 0.5),
			Vector2(width * 0.3, length * 0.5),
			Vector2(-width * 0.3, length * 0.5)
		])
		var angle: float = dir * randf_range(0.3, 1.2) + randf_range(-0.4, 0.4)
		slash.rotation = angle
		slash.global_position = hit_pos + Vector2(dir * randf_range(-5, 15), randf_range(-20, 20))
		var hue: float = randf_range(0.0, 0.12)
		slash.color = Color.from_hsv(hue, randf_range(0.1, 0.5), 1.0, randf_range(0.7, 1.0))
		scene_root.add_child(slash)
		var tw := player.get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(slash, "scale", Vector2(0.2, 1.4), randf_range(0.08, 0.14)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(slash, "modulate:a", 0.0, randf_range(0.1, 0.18)).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
		tw.tween_callback(slash.queue_free)
	# Impact sparks — small dots flying outward
	for i in range(randi_range(4, 8)):
		var spark := Polygon2D.new()
		spark.z_index = 12
		var sz: float = randf_range(1.5, 4.0)
		spark.polygon = PackedVector2Array([
			Vector2(-sz, -sz), Vector2(sz, -sz),
			Vector2(sz, sz), Vector2(-sz, sz)
		])
		var hue: float = randf_range(0.05, 0.15)
		spark.color = Color.from_hsv(hue, randf_range(0.3, 0.8), 1.0, randf_range(0.8, 1.0))
		spark.global_position = hit_pos + Vector2(randf_range(-8, 8), randf_range(-10, 10))
		scene_root.add_child(spark)
		var end_pos := spark.global_position + Vector2(dir * randf_range(20, 60), randf_range(-40, 40))
		var tw := player.get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "global_position", end_pos, randf_range(0.1, 0.2)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(spark, "modulate:a", 0.0, randf_range(0.12, 0.22)).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)
