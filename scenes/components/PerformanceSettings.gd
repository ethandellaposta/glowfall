extends Resource
class_name PerformanceSettings

# Performance optimization settings for different hardware levels
# Automatically adjusts quality based on system capabilities

enum QualityLevel {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

@export var quality_level: QualityLevel = QualityLevel.HIGH
@export var auto_detect_quality: bool = true
@export var target_fps: int = 60
@export var vsync_enabled: bool = true

# Rendering settings
@export var anti_aliasing_quality: int = 2  # 0=off, 1=2x, 2=4x, 3=8x
@export var shadow_quality: int = 2
@export var texture_quality: int = 2
@export var particle_quality: int = 2
@export var post_processing_quality: int = 2

# Optimization settings
@export var object_pooling_enabled: bool = true
@export var culling_enabled: bool = true
@export var lod_enabled: bool = true
@export var async_loading: bool = true

# Memory management
@export var max_memory_usage: int = 512  # MB
@export var garbage_collection_interval: float = 5.0  # seconds
@export var texture_streaming: bool = true

# Debug and monitoring
@export var performance_monitoring: bool = false
@export var fps_display: bool = false
@export var memory_display: bool = false

var _last_gc_time: float = 0.0
var _performance_stats: Dictionary = {}

func _ready() -> void:
	if auto_detect_quality:
		_detect_optimal_quality()
	
	apply_to_engine()

func _detect_optimal_quality() -> void:
	# Simple hardware detection based on available information
	var total_memory := OS.get_static_memory_usage_by_type().get("total", 0)
	var processor_count := OS.get_processor_count()
	
	# Basic quality detection logic
	if processor_count >= 8 and total_memory > 8000000000:  # 8GB+ RAM
		quality_level = QualityLevel.ULTRA
	elif processor_count >= 4 and total_memory > 4000000000:  # 4GB+ RAM
		quality_level = QualityLevel.HIGH
	elif processor_count >= 2 and total_memory > 2000000000:  # 2GB+ RAM
		quality_level = QualityLevel.MEDIUM
	else:
		quality_level = QualityLevel.LOW
	
	_apply_quality_settings()

func _apply_quality_settings() -> void:
	match quality_level:
		QualityLevel.LOW:
			anti_aliasing_quality = 0
			shadow_quality = 0
			texture_quality = 0
			particle_quality = 0
			post_processing_quality = 0
			target_fps = 30
		QualityLevel.MEDIUM:
			anti_aliasing_quality = 1
			shadow_quality = 1
			texture_quality = 1
			particle_quality = 1
			post_processing_quality = 1
			target_fps = 45
		QualityLevel.HIGH:
			anti_aliasing_quality = 2
			shadow_quality = 2
			texture_quality = 2
			particle_quality = 2
			post_processing_quality = 2
			target_fps = 60
		QualityLevel.ULTRA:
			anti_aliasing_quality = 3
			shadow_quality = 3
			texture_quality = 3
			particle_quality = 3
			post_processing_quality = 3
			target_fps = 120

func apply_to_engine() -> void:
	# Apply rendering settings
	Engine.set_target_fps(target_fps)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
	
	# Apply anti-aliasing
	var rendering_method = RenderingServer.DEFAULT_RENDERING_METHOD
	match anti_aliasing_quality:
		0:
			RenderingServer.viewport_set_msaa_2d(rendering_method, RenderingServer.VIEWPORT_MSAA_DISABLED)
			RenderingServer.viewport_set_msaa_3d(rendering_method, RenderingServer.VIEWPORT_MSAA_DISABLED)
		1:
			RenderingServer.viewport_set_msaa_2d(rendering_method, RenderingServer.VIEWPORT_MSAA_2X)
			RenderingServer.viewport_set_msaa_3d(rendering_method, RenderingServer.VIEWPORT_MSAA_2X)
		2:
			RenderingServer.viewport_set_msaa_2d(rendering_method, RenderingServer.VIEWPORT_MSAA_4X)
			RenderingServer.viewport_set_msaa_3d(rendering_method, RenderingServer.VIEWPORT_MSAA_4X)
		3:
			RenderingServer.viewport_set_msaa_2d(rendering_method, RenderingServer.VIEWPORT_MSAA_8X)
			RenderingServer.viewport_set_msaa_3d(rendering_method, RenderingServer.VIEWPORT_MSAA_8X)
	
	# Apply shadow settings
	RenderingServer.directional_soft_shadow_filter_set_quality(shadow_quality)
	
	# Apply texture streaming
	if texture_streaming:
		RenderingServer.texture_set_detect_3d_callback(texture_streaming_callback)
	
	# Apply culling settings
	if culling_enabled:
		RenderingServer.camera_set_cull_mask(rendering_method, 1)

func texture_streaming_callback(texture: RID) -> void:
	# Custom texture streaming logic based on quality
	pass

func update_performance_stats() -> void:
	_performance_stats = {
		"fps": Engine.get_frames_per_second(),
		"frame_time": Engine.get_physics_interpolation_fraction(),
		"memory_usage": OS.get_static_memory_usage_by_type(),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"objects": get_tree().get_node_count(),
		"quality_level": quality_level
	}

func manage_memory() -> void:
	var current_time := Time.get_time_dict_from_system().second
	
	if current_time - _last_gc_time >= garbage_collection_interval:
		# Force garbage collection
		call_deferred("force_garbage_collection")
		_last_gc_time = current_time

func force_garbage_collection() -> void:
	# Clean up unused resources
	var unused_resources := []
	
	# Find unused textures
	var used_textures := {}
	_traverse_scene_for_textures(get_tree().current_scene, used_textures)
	
	# This is a simplified version - in practice you'd want more sophisticated tracking
	for texture_id in RenderingServer.get_texture_list():
		if not used_textures.has(texture_id):
			unused_resources.append(texture_id)
	
	# Free unused resources
	for resource_id in unused_resources:
		RenderingServer.free_rid(resource_id)

func _traverse_scene_for_textures(node: Node, used_textures: Dictionary) -> void:
	# Recursively find all textures in use
	if node is Sprite2D or node is AnimatedSprite2D:
		if node.texture != null:
			used_textures[node.texture.get_rid()] = true
	
	for child in node.get_children():
		_traverse_scene_for_textures(child, used_textures)

func get_performance_stats() -> Dictionary:
	update_performance_stats()
	return _performance_stats

func set_quality_level(level: QualityLevel) -> void:
	quality_level = level
	_apply_quality_settings()
	apply_to_engine()

func optimize_for_mobile() -> void:
	quality_level = QualityLevel.MEDIUM
	target_fps = 30
	vsync_enabled = true
	anti_aliasing_quality = 1
	shadow_quality = 0
	particle_quality = 1
	post_processing_quality = 0
	apply_to_engine()

func optimize_for_desktop() -> void:
	quality_level = QualityLevel.HIGH
	target_fps = 60
	vsync_enabled = true
	anti_aliasing_quality = 2
	shadow_quality = 2
	particle_quality = 2
	post_processing_quality = 2
	apply_to_engine()

func get_memory_usage_mb() -> int:
	var memory_bytes := OS.get_static_memory_usage_by_type().get("total", 0)
	return memory_bytes / (1024 * 1024)

func is_memory_limit_exceeded() -> bool:
	return get_memory_usage_mb() > max_memory_usage

func should_reduce_quality() -> bool:
	var current_fps := Engine.get_frames_per_second()
	return current_fps < target_fps * 0.8  # 80% of target FPS

func auto_adjust_quality() -> void:
	if should_reduce_quality():
		if quality_level > QualityLevel.LOW:
			set_quality_level(quality_level - 1)
			print("Auto-reduced quality to: ", quality_level)
	elif Engine.get_frames_per_second() > target_fps * 1.2 and quality_level < QualityLevel.ULTRA:
		# Performance is good, try increasing quality
		set_quality_level(quality_level + 1)
		print("Auto-increased quality to: ", quality_level)
