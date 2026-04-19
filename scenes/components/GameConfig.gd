extends Resource
class_name GameConfig

# Centralized game configuration for maintainability
# All game settings and parameters in one place

# Player configuration
@export var player_config: PlayerConfig = PlayerConfig.new()

# Enemy configuration
@export var enemy_config: EnemyConfig = EnemyConfig.new()

# Visual configuration
@export var visual_config: VisualConfig = VisualConfig.new()

# Audio configuration
@export var audio_config: AudioConfig = AudioConfig.new()

# Input configuration
@export var input_config: InputConfig = InputConfig.new()

# UI configuration
@export var ui_config: UIConfig = UIConfig.new()

# Level configuration
@export var level_config: LevelConfig = LevelConfig.new()

func get_save_data() -> Dictionary:
	return {
		"player": player_config.get_save_data(),
		"enemy": enemy_config.get_save_data(),
		"visual": visual_config.get_save_data(),
		"audio": audio_config.get_save_data(),
		"input": input_config.get_save_data(),
		"ui": ui_config.get_save_data(),
		"level": level_config.get_save_data()
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("player"):
		player_config.load_save_data(data.player)
	if data.has("enemy"):
		enemy_config.load_save_data(data.enemy)
	if data.has("visual"):
		visual_config.load_save_data(data.visual)
	if data.has("audio"):
		audio_config.load_save_data(data.audio)
	if data.has("input"):
		input_config.load_save_data(data.input)
	if data.has("ui"):
		ui_config.load_save_data(data.ui)
	if data.has("level"):
		level_config.load_save_data(data.level)

# Individual configuration classes
class PlayerConfig extends Resource:
	@export var max_hp: int = 5
	@export var max_soul: int = 99
	@export var speed: float = 260.0
	@export var jump_velocity: float = -700.0
	@export var ground_accel: float = 1800.0
	@export var ground_decel: float = 2200.0
	@export var air_control: float = 0.85
	@export var air_accel: float = 900.0
	@export var air_decel: float = 400.0
	@export var attack_damage: int = 1
	@export var attack_cooldown: float = 0.12
	@export var combo_window: float = 0.5
	
	func get_save_data() -> Dictionary:
		return {
			"max_hp": max_hp,
			"max_soul": max_soul,
			"speed": speed,
			"jump_velocity": jump_velocity
		}
	
	func load_save_data(data: Dictionary) -> void:
		max_hp = data.get("max_hp", max_hp)
		max_soul = data.get("max_soul", max_soul)
		speed = data.get("speed", speed)
		jump_velocity = data.get("jump_velocity", jump_velocity)

class EnemyConfig extends Resource:
	@export var default_speed: float = 90.0
	@export var default_hp: int = 3
	@export var detection_range: float = 120.0
	@export var chase_speed_multiplier: float = 1.8
	@export var attack_range: float = 60.0
	@export var group_behavior: bool = true
	@export var spawn_rate: float = 0.3
	
	func get_save_data() -> Dictionary:
		return {
			"default_speed": default_speed,
			"default_hp": default_hp,
			"detection_range": detection_range
		}
	
	func load_save_data(data: Dictionary) -> void:
		default_speed = data.get("default_speed", default_speed)
		default_hp = data.get("default_hp", default_hp)
		detection_range = data.get("detection_range", detection_range)

class VisualConfig extends Resource:
	@export var pixel_perfect: bool = true
	@export var screen_shake_enabled: bool = true
	@export var particle_quality: int = 2  # 0=low, 1=medium, 2=high
	@export var shader_quality: int = 2
	@export var post_processing_enabled: bool = true
	@export var chromatic_aberration: float = 0.0
	@export var vignette_strength: float = 0.3
	@export var film_grain_strength: float = 0.1
	
	func get_save_data() -> Dictionary:
		return {
			"pixel_perfect": pixel_perfect,
			"screen_shake_enabled": screen_shake_enabled,
			"particle_quality": particle_quality,
			"shader_quality": shader_quality
		}
	
	func load_save_data(data: Dictionary) -> void:
		pixel_perfect = data.get("pixel_perfect", pixel_perfect)
		screen_shake_enabled = data.get("screen_shake_enabled", screen_shake_enabled)
		particle_quality = data.get("particle_quality", particle_quality)
		shader_quality = data.get("shader_quality", shader_quality)

class AudioConfig extends Resource:
	@export var master_volume: float = 1.0
	@export var music_volume: float = 0.8
	@export var sfx_volume: float = 0.9
	@export var ui_volume: float = 0.7
	@export var audio_quality: int = 2  # 0=low, 1=medium, 2=high
	
	func get_save_data() -> Dictionary:
		return {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"ui_volume": ui_volume
		}
	
	func load_save_data(data: Dictionary) -> void:
		master_volume = data.get("master_volume", master_volume)
		music_volume = data.get("music_volume", music_volume)
		sfx_volume = data.get("sfx_volume", sfx_volume)
		ui_volume = data.get("ui_volume", ui_volume)

class InputConfig extends Resource:
	@export var input_sensitivity: float = 1.0
	@export var vibration_enabled: bool = true
	@export var vibration_intensity: float = 0.5
	@export var deadzone: float = 0.1
	@export var mouse_sensitivity: float = 1.0
	
	func get_save_data() -> Dictionary:
		return {
			"input_sensitivity": input_sensitivity,
			"vibration_enabled": vibration_enabled,
			"vibration_intensity": vibration_intensity
		}
	
	func load_save_data(data: Dictionary) -> void:
		input_sensitivity = data.get("input_sensitivity", input_sensitivity)
		vibration_enabled = data.get("vibration_enabled", vibration_enabled)
		vibration_intensity = data.get("vibration_intensity", vibration_intensity)

class UIConfig extends Resource:
	@export var ui_scale: float = 1.0
	@export var font_size: int = 12
	@export var animation_speed: float = 1.0
	@export var tooltips_enabled: bool = true
	@export var screen_borders: bool = true
	
	func get_save_data() -> Dictionary:
		return {
			"ui_scale": ui_scale,
			"font_size": font_size,
			"animation_speed": animation_speed,
			"tooltips_enabled": tooltips_enabled
		}
	
	func load_save_data(data: Dictionary) -> void:
		ui_scale = data.get("ui_scale", ui_scale)
		font_size = data.get("font_size", font_size)
		animation_speed = data.get("animation_speed", animation_speed)
		tooltips_enabled = data.get("tooltips_enabled", tooltips_enabled)

class LevelConfig extends Resource:
	@export var difficulty: float = 1.0
	@export var enemy_density: float = 0.3
	@export var item_density: float = 0.15
	@export var procedural_generation: bool = true
	@export var level_size: Vector2i = Vector2i(50, 30)
	@export var max_rooms: int = 25
	@export var min_rooms: int = 15
	
	func get_save_data() -> Dictionary:
		return {
			"difficulty": difficulty,
			"enemy_density": enemy_density,
			"item_density": item_density,
			"procedural_generation": procedural_generation
		}
	
	func load_save_data(data: Dictionary) -> void:
		difficulty = data.get("difficulty", difficulty)
		enemy_density = data.get("enemy_density", enemy_density)
		item_density = data.get("item_density", item_density)
		procedural_generation = data.get("procedural_generation", procedural_generation)
