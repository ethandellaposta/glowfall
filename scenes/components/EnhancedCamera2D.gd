extends Camera2D
class_name EnhancedCamera2D

# Advanced camera system with smooth following, screen effects, and performance optimizations
@export var follow_target: Node2D
@export var follow_speed: float = 8.0
@export var look_ahead_factor: float = 0.2
@export var deadzone_size: Vector2 = Vector2(50, 30)
@export var smoothing_enabled: bool = true
@export var pixel_perfect: bool = true

# Screen shake parameters
@export var shake_enabled: bool = true
@export var shake_strength: float = 5.0
@export var shake_duration: float = 0.3
@export var shake_decay: float = 2.0

# Zoom parameters
@export var zoom_enabled: bool = true
@export var zoom_speed: float = 4.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var default_zoom: float = 0.75

# Screen effects
@export var screen_effects_enabled: bool = true
@export var chromatic_aberration_strength: float = 0.0
@export var vignette_strength: float = 0.3
@export var film_grain_strength: float = 0.1

# Performance optimization
@export var update_rate: float = 60.0  # Target update rate
var _accumulated_time: float = 0.0

# Internal state
var _target_position: Vector2
var _current_shake: Vector2
var _shake_timer: float = 0.0
var _target_zoom: float
var _velocity: Vector2
var _last_target_position: Vector2
var _look_ahead_offset: Vector2

# Screen effect materials
var _screen_effect_material: ShaderMaterial

func _ready() -> void:
	_target_position = global_position
	_target_zoom = default_zoom
	zoom = Vector2(default_zoom, default_zoom)
	
	# Setup screen effects
	if screen_effects_enabled:
		_setup_screen_effects()
	
	# Enable pixel perfect if needed
	if pixel_perfect:
		position = position.round()

func _setup_screen_effects() -> void:
	var shader := preload("res://shaders/screen_effects.gdshader")
	if shader != null:
		_screen_effect_material = ShaderMaterial.new()
		_screen_effect_material.shader = shader
		# Apply to viewport or camera overlay
		# This would need to be implemented based on your specific setup

func _process(delta: float) -> void:
	_accumulated_time += delta
	
	# Rate limiting for performance
	if _accumulated_time < (1.0 / update_rate):
		return
	
	_accumulated_time = 0.0
	
	_update_following(delta)
	_update_screen_shake(delta)
	_update_zoom(delta)
	_update_screen_effects(delta)
	
	if pixel_perfect:
		position = position.round()

func _update_following(delta: float) -> void:
	if follow_target == null:
		return
	
	var target_pos := follow_target.global_position
	
	# Calculate look-ahead based on target velocity
	if follow_target.has_method("get_velocity"):
		var target_vel := follow_target.call("get_velocity") as Vector2
		_look_ahead_offset = target_vel * look_ahead_factor
	else:
		# Fallback to manual velocity calculation
		_look_ahead_offset = (target_pos - _last_target_position) / delta * look_ahead_factor
		_last_target_position = target_pos
	
	# Apply deadzone
	var offset := target_pos + _look_ahead_offset - global_position
	if absf(offset.x) < deadzone_size.x:
		offset.x = 0.0
	if absf(offset.y) < deadzone_size.y:
		offset.y = 0.0
	
	_target_position = global_position + offset
	
	# Smooth following
	if smoothing_enabled:
		global_position = global_position.lerp(_target_position, follow_speed * delta)
	else:
		global_position = _target_position

func _update_screen_shake(delta: float) -> void:
	if not shake_enabled:
		return
	
	if _shake_timer > 0.0:
		_shake_timer -= delta * shake_decay
		
		if _shake_timer > 0.0:
			var shake_intensity := shake_strength * _shake_timer
			_current_shake = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
		else:
			_current_shake = Vector2.ZERO
			_shake_timer = 0.0
	
	offset = _current_shake

func _update_zoom(delta: float) -> void:
	if not zoom_enabled:
		return
	
	var current_zoom := zoom.x
	var new_zoom := move_toward(current_zoom, _target_zoom, zoom_speed * delta)
	zoom = Vector2(new_zoom, new_zoom)

func _update_screen_effects(delta: float) -> void:
	if not screen_effects_enabled or _screen_effect_material == null:
		return
	
	# Update shader parameters
	_screen_effect_material.set_shader_parameter("chromatic_aberration", chromatic_aberration_strength)
	_screen_effect_material.set_shader_parameter("vignette_strength", vignette_strength)
	_screen_effect_material.set_shader_parameter("film_grain_strength", film_grain_strength)
	_screen_effect_material.set_shader_parameter("time", Time.get_time_dict_from_system().second)

# Public methods for camera control
func set_follow_target(target: Node2D) -> void:
	follow_target = target
	if target != null:
		_target_position = target.global_position

func add_screen_shake(strength: float = -1.0, duration: float = -1.0) -> void:
	if not shake_enabled:
		return
	
	if strength > 0.0:
		shake_strength = strength
	if duration > 0.0:
		shake_duration = duration
	
	_shake_timer = shake_duration

func set_zoom_level(level: float) -> void:
	if not zoom_enabled:
		return
	
	_target_zoom = clampf(level, min_zoom, max_zoom)

func zoom_to_target(duration: float = 1.0) -> void:
	if not zoom_enabled or follow_target == null:
		return
	
	# Calculate zoom based on target velocity or other factors
	var target_speed := 0.0
	if follow_target.has_method("get_velocity"):
		var vel := follow_target.call("get_velocity") as Vector2
		target_speed = vel.length()
	
	# Dynamic zoom based on speed
	var speed_factor := clampf(target_speed / 500.0, 0.0, 1.0)
	var dynamic_zoom := lerpf(default_zoom, max_zoom, speed_factor * 0.3)
	
	set_zoom_level(dynamic_zoom)

func instant_look_at(position: Vector2) -> void:
	global_position = position
	_target_position = position

func smooth_look_at(position: Vector2, duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(_smooth_look_at_update, global_position, position, duration)

func _smooth_look_at_update(pos: Vector2) -> void:
	_target_position = pos

# Performance optimization methods
func set_update_rate(rate: float) -> void:
	update_rate = maxf(rate, 1.0)

func enable_pixel_perfect(enabled: bool) -> void:
	pixel_perfect = enabled
	if enabled:
		position = position.round()

# Screen effect controls
func set_chromatic_aberration(strength: float) -> void:
	chromatic_aberration_strength = clampf(strength, 0.0, 1.0)

func set_vignette(strength: float) -> void:
	vignette_strength = clampf(strength, 0.0, 1.0)

func set_film_grain(strength: float) -> void:
	film_grain_strength = clampf(strength, 0.0, 1.0)

# Utility methods
func get_camera_bounds() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_size := viewport_size * 0.5 / zoom.x
	return Rect2(global_position - half_size, viewport_size / zoom.x)

func is_position_visible(pos: Vector2) -> void:
	var bounds := get_camera_bounds()
	return bounds.has_point(pos)

func get_screen_position(world_pos: Vector2) -> Vector2:
	return world_pos - global_position + get_viewport().get_visible_rect().size * 0.5 / zoom.x
