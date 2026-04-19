extends Node2D
class_name VisualEffectsManager

# Performance-optimized visual effects system with object pooling
# Centralized management of all visual effects for better performance

# Effect pools for different types
var _polygon_pool: Array[Polygon2D] = []
var _light_pool: Array[PointLight2D] = []
var _particles_pool: Array[GPUParticles2D] = []

# Pool sizes
const POLYGON_POOL_SIZE := 100
const LIGHT_POOL_SIZE := 20
const PARTICLES_POOL_SIZE := 30

# Performance settings
var _max_effects_per_frame: int = 10
var _effects_this_frame: int = 0
var _frame_counter: int = 0

# Singleton instance
static var instance: VisualEffectsManager

func _ready() -> void:
	if instance == null:
		instance = self
	_initialize_pools()

func _initialize_pools() -> void:
	# Pre-create polygon effects
	for i in range(POLYGON_POOL_SIZE):
		var poly := Polygon2D.new()
		_polygon_pool.append(poly)
	
	# Pre-create lights
	for i in range(LIGHT_POOL_SIZE):
		var light := PointLight2D.new()
		light.shadow_enabled = false
		_light_pool.append(light)
	
	# Pre-create particle systems
	for i in range(PARTICLES_POOL_SIZE):
		var particles := GPUParticles2D.new()
		particles.one_shot = true
		particles.emitting = false
		_particles_pool.append(particles)

func _process(_delta: float) -> void:
	_frame_counter += 1
	_effects_this_frame = 0

# Get pooled effects
func get_polygon_effect() -> Polygon2D:
	for poly in _polygon_pool:
		if poly.get_parent() == null:
			return poly
	return null

func get_light_effect() -> PointLight2D:
	for light in _light_pool:
		if light.get_parent() == null:
			return light
	return null

func get_particles_effect() -> GPUParticles2D:
	for particles in _particles_pool:
		if particles.get_parent() == null:
			return particles
	return null

# Return effects to pool
func return_polygon_effect(poly: Polygon2D) -> void:
	if poly != null and poly.get_parent() != null:
		poly.get_parent().remove_child(poly)
		poly.modulate = Color.WHITE
		poly.scale = Vector2.ONE
		poly.rotation = 0.0

func return_light_effect(light: PointLight2D) -> void:
	if light != null and light.get_parent() != null:
		light.get_parent().remove_child(light)
		light.energy = 1.0
		light.color = Color.WHITE

func return_particles_effect(particles: GPUParticles2D) -> void:
	if particles != null and particles.get_parent() != null:
		particles.get_parent().remove_child(particles)
		particles.emitting = false

# Optimized effect creation with frame limiting
func create_effect(effect_type: String, parent: Node, position: Vector2 = Vector2.ZERO) -> Node:
	if _effects_this_frame >= _max_effects_per_frame:
		return null
	
	_effects_this_frame += 1
	
	match effect_type:
		"blade_shard":
			return _create_blade_shard(parent, position)
		"attack_sweep":
			return _create_attack_sweep(parent, position)
		"impact_spark":
			return _create_impact_spark(parent, position)
		"death_shard":
			return _create_death_shard(parent, position)
		_:
			return null

func _create_blade_shard(parent: Node, pos: Vector2) -> Polygon2D:
	var shard := get_polygon_effect()
	if shard == null:
		return null
	
	shard.z_index = 10
	var sw: float = randf_range(3, 8)
	var sh: float = randf_range(8, 20)
	shard.polygon = PackedVector2Array([
		Vector2(0, -sh * 0.5),
		Vector2(sw * 0.4, -sh * 0.2),
		Vector2(sw, sh * 0.1),
		Vector2(sw * 0.6, sh * 0.5),
		Vector2(-sw * 0.3, sh * 0.3),
		Vector2(-sw * 0.5, -sh * 0.1)
	])
	
	var hue: float = randf_range(0.48, 0.58)
	shard.color = Color.from_hsv(hue, randf_range(0.3, 0.7), 1.0, randf_range(0.6, 1.0))
	shard.rotation = randf_range(-0.8, 0.8)
	shard.global_position = pos + Vector2(randf_range(-20, 20), randf_range(-25, 25))
	
	parent.add_child(shard)
	return shard

func _create_attack_sweep(parent: Node, pos: Vector2) -> Polygon2D:
	var sweep := get_polygon_effect()
	if sweep == null:
		return null
	
	sweep.z_index = 11
	var w: float = randf_range(2.0, 5.0)
	var h: float = randf_range(1.0, 2.5)
	sweep.polygon = PackedVector2Array([
		Vector2(-w, -h), Vector2(w, -h),
		Vector2(w, h), Vector2(-w, h)
	])
	sweep.color = Color(0.4, 0.95, 0.9, randf_range(0.5, 0.9))
	sweep.global_position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	
	parent.add_child(sweep)
	return sweep

func _create_impact_spark(parent: Node, pos: Vector2) -> Polygon2D:
	var spark := get_polygon_effect()
	if spark == null:
		return null
	
	spark.z_index = 13
	var sz: float = randf_range(2.5, 6.0)
	spark.polygon = PackedVector2Array([
		Vector2(-sz, -sz * 0.5), Vector2(sz, -sz * 0.5),
		Vector2(sz, sz * 0.5), Vector2(-sz, sz * 0.5)
	])
	
	var hue: float = randf_range(0.05, 0.12)
	spark.color = Color.from_hsv(hue, randf_range(0.6, 1.0), 1.0, 1.0)
	spark.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-15, 15))
	spark.rotation = randf_range(-1.0, 1.0)
	
	parent.add_child(spark)
	return spark

func _create_death_shard(parent: Node, pos: Vector2) -> Polygon2D:
	var shard := get_polygon_effect()
	if shard == null:
		return null
	
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
	shard.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-20, 10))
	
	parent.add_child(shard)
	return shard

# Animate and auto-return effects
func animate_effect(effect: Node, end_pos: Vector2, duration: float, fade_out: bool = true) -> void:
	if effect == null:
		return
	
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	
	if effect is Polygon2D:
		tween.tween_property(effect, "global_position", end_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		if fade_out:
			tween.tween_property(effect, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.tween_property(effect, "rotation", effect.rotation + randf_range(-2.0, 2.0), duration)
		tween.tween_property(effect, "scale", Vector2(0.3, 0.3), duration).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	tween.tween_callback(func(): _return_effect_to_pool(effect))

func _return_effect_to_pool(effect: Node) -> void:
	if effect is Polygon2D:
		return_polygon_effect(effect)
	elif effect is PointLight2D:
		return_light_effect(effect)
	elif effect is GPUParticles2D:
		return_particles_effect(effect)

# Cleanup all effects
func cleanup_all_effects() -> void:
	for poly in _polygon_pool:
		if poly.get_parent() != null:
			poly.get_parent().remove_child(poly)
	
	for light in _light_pool:
		if light.get_parent() != null:
			light.get_parent().remove_child(light)
	
	for particles in _particles_pool:
		if particles.get_parent() != null:
			particles.get_parent().remove_child(particles)
