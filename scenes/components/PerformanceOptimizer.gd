extends Node
class_name PerformanceOptimizer

# Comprehensive performance optimization system
# Monitors and optimizes all game systems for maximum performance

# Performance monitoring
var _fps_history: Array[float] = []
var _frame_time_history: Array[float] = []
var _memory_history: Array[int] = []
var _draw_call_history: Array[int] = []

# Optimization settings
var _target_fps: int = 60
var _min_acceptable_fps: int = 45
var _max_frame_time: float = 1.0 / 45.0  # 45 FPS minimum
var _memory_limit_mb: int = 512

# Adaptive quality system
var _adaptive_quality_enabled: bool = true
var _quality_adjustment_cooldown: float = 5.0
var _last_quality_adjustment: float = 0.0

# System-specific optimizers
var _render_optimizer: RenderOptimizer
var _physics_optimizer: PhysicsOptimizer
var _audio_optimizer: AudioOptimizer
var _ui_optimizer: UIOptimizer

# Performance metrics
var _current_fps: float = 60.0
var _average_fps: float = 60.0
var _current_memory_mb: int = 0
var _current_draw_calls: int = 0

# Singleton instance
static var instance: PerformanceOptimizer

func _ready() -> void:
	if instance == null:
		instance = self
		_initialize_optimizers()
		_setup_monitoring()
	else:
		queue_free()

func _initialize_optimizers() -> void:
	_render_optimizer = RenderOptimizer.new()
	add_child(_render_optimizer)
	
	_physics_optimizer = PhysicsOptimizer.new()
	add_child(_physics_optimizer)
	
	_audio_optimizer = AudioOptimizer.new()
	add_child(_audio_optimizer)
	
	_ui_optimizer = UIOptimizer.new()
	add_child(_ui_optimizer)

func _setup_monitoring() -> void:
	# Start performance monitoring
	var timer := Timer.new()
	timer.wait_time = 0.1  # Monitor every 100ms
	timer.timeout.connect(_update_performance_metrics)
	add_child(timer)
	timer.start()

func _update_performance_metrics() -> void:
	# Collect current performance data
	_current_fps = Engine.get_frames_per_second()
	_current_memory_mb = OS.get_static_memory_usage() / (1024 * 1024)
	_current_draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	
	# Update history
	_fps_history.append(_current_fps)
	_frame_time_history.append(1.0 / _current_fps)
	_memory_history.append(_current_memory_mb)
	_draw_call_history.append(_current_draw_calls)
	
	# Keep history size manageable
	const MAX_HISTORY_SIZE = 100
	if _fps_history.size() > MAX_HISTORY_SIZE:
		_fps_history.pop_front()
		_frame_time_history.pop_front()
		_memory_history.pop_front()
		_draw_call_history.pop_front()
	
	# Calculate averages
	_average_fps = _calculate_average(_fps_history)
	
	# Trigger optimizations if needed
	_check_performance_triggers()

func _calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var total := 0.0
	for value in values:
		total += value
	
	return total / values.size()

func _check_performance_triggers() -> void:
	var current_time := Time.get_time_dict_from_system().second
	
	# FPS-based optimizations
	if _current_fps < _min_acceptable_fps:
		if current_time - _last_quality_adjustment >= _quality_adjustment_cooldown:
			_handle_low_fps()
			_last_quality_adjustment = current_time
	
	# Memory-based optimizations
	if _current_memory_mb > _memory_limit_mb:
		_handle_high_memory_usage()
	
	# Draw call optimizations
	if _current_draw_calls > 1000:  # High draw call count
		_handle_high_draw_calls()

func _handle_low_fps() -> void:
	print("Performance warning: Low FPS detected (", _current_fps, ")")
	
	# Apply optimizations in order of impact
	_render_optimizer.reduce_quality()
	_physics_optimizer.reduce_timestep()
	_audio_optimizer.optimize_channels()
	_ui_optimizer.reduce_animations()

func _handle_high_memory_usage() -> void:
	print("Performance warning: High memory usage (", _current_memory_mb, "MB)")
	
	# Force garbage collection
	call_deferred("force_garbage_collection")
	
	# Optimize texture usage
	_render_optimizer.optimize_textures()
	
	# Clean up unused objects
	_cleanup_unused_objects()

func _handle_high_draw_calls() -> void:
	print("Performance warning: High draw calls (", _current_draw_calls, ")")
	
	_render_optimizer.optimize_draw_calls()
	_ui_optimizer.batch_ui_elements()

func force_garbage_collection() -> void:
	# Force garbage collection
	var unused_resources := []
	
	# Find and free unused resources
	for resource_id in RenderingServer.get_texture_list():
		var texture := RenderingServer.texture_get_rd_texture(resource_id)
		if texture == RID():
			unused_resources.append(resource_id)
	
	for resource_id in unused_resources:
		RenderingServer.free_rid(resource_id)
	
	# Call JavaScript garbage collection if on web
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("GC()")

func _cleanup_unused_objects() -> void:
	# Find and clean up unused nodes
	var scene_root := get_tree().current_scene
	_cleanup_node_children(scene_root)

func _cleanup_node_children(node: Node) -> void:
	for child in node.get_children():
		if child is Node2D and child.get_child_count() == 0:
			# Check if this is an orphaned visual effect
			if child.name.contains("Effect") or child.name.contains("Particle"):
				child.queue_free()
		else:
			_cleanup_node_children(child)

# Public API for performance control
func get_performance_report() -> Dictionary:
	return {
		"current_fps": _current_fps,
		"average_fps": _average_fps,
		"current_memory_mb": _current_memory_mb,
		"current_draw_calls": _current_draw_calls,
		"target_fps": _target_fps,
		"memory_limit_mb": _memory_limit_mb,
		"adaptive_quality_enabled": _adaptive_quality_enabled,
		"render_quality": _render_optimizer.get_current_quality(),
		"physics_timestep": _physics_optimizer.get_current_timestep(),
		"audio_channels": _audio_optimizer.get_active_channels(),
		"ui_animations": _ui_optimizer.get_animation_count()
	}

func set_target_fps(fps: int) -> void:
	_target_fps = fps
	Engine.set_target_fps(fps)

func enable_adaptive_quality(enabled: bool) -> void:
	_adaptive_quality_enabled = enabled

func set_memory_limit(limit_mb: int) -> void:
	_memory_limit_mb = limit_mb

func optimize_now() -> void:
	_handle_low_fps()
	_handle_high_memory_usage()
	_handle_high_draw_calls()

# Individual optimizer classes
class RenderOptimizer extends Node:
	var _current_quality: int = 2  # 0=low, 1=medium, 2=high, 3=ultra
	var _shadow_quality: int = 2
	var _particle_quality: int = 2
	var _texture_quality: int = 2
	
	func reduce_quality() -> void:
		if _current_quality > 0:
			_current_quality -= 1
			_apply_quality_settings()
	
	func get_current_quality() -> int:
		return _current_quality
	
	func _apply_quality_settings() -> void:
		match _current_quality:
			0:  # Low
				RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
				RenderingServer.directional_soft_shadow_filter_set_quality(0)
				_particle_quality = 0
				_texture_quality = 0
			1:  # Medium
				RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
				RenderingServer.directional_soft_shadow_filter_set_quality(1)
				_particle_quality = 1
				_texture_quality = 1
			2:  # High
				RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X)
				RenderingServer.directional_soft_shadow_filter_set_quality(2)
				_particle_quality = 2
				_texture_quality = 2
			3:  # Ultra
				RenderingServer.viewport_set_msaa_2d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_8X)
				RenderingServer.directional_soft_shadow_filter_set_quality(3)
				_particle_quality = 3
				_texture_quality = 3
	
	func optimize_textures() -> void:
		# Reduce texture quality
		if _texture_quality > 0:
			_texture_quality -= 1
			_apply_quality_settings()
	
	func optimize_draw_calls() -> void:
		# Enable batching and reduce draw calls
		RenderingServer.canvas_item_set_use_parent_material(get_viewport().get_canvas_item(), true)

class PhysicsOptimizer extends Node:
	var _physics_timestep: float = 1.0 / 60.0
	var _max_physics_steps: int = 4
	
	func reduce_timestep() -> void:
		_physics_timestep = min(_physics_timestep * 1.5, 1.0 / 30.0)  # Don't go below 30 FPS physics
		Engine.set_physics_jitter_fix(0.5)
	
	func get_current_timestep() -> float:
		return _physics_timestep

class AudioOptimizer extends Node:
	var _max_concurrent_sounds: int = 16
	var _current_channels: int = 0
	
	func optimize_channels() -> void:
		_max_concurrent_sounds = max(_max_concurrent_sounds - 4, 4)
	
	func get_active_channels() -> int:
		return _current_channels

class UIOptimizer extends Node:
	var _animation_speed: float = 1.0
	var _max_animations: int = 10
	var _current_animations: int = 0
	
	func reduce_animations() -> void:
		_animation_speed = max(_animation_speed * 0.8, 0.3)
	
	func batch_ui_elements() -> void:
		# Enable UI batching
		var ui_root := get_tree().get_first_node_in_group("ui")
		if ui_root:
			ui_root.use_parent_material = true
	
	func get_animation_count() -> int:
		return _current_animations
