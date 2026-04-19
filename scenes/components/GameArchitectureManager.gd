extends Node
class_name GameArchitectureManager

# Central architecture manager for clean code organization and maintainability
# Provides singleton access to core systems and enforces coding standards

# Singleton instance
static var instance: GameArchitectureManager

# Core system references
var player_manager: PlayerManager
var enemy_manager: EnemyManager
var visual_effects_manager: VisualEffectsManager
var camera_manager: EnhancedCamera2D
var level_generator: ProceduralLevelGenerator
var audio_manager: AudioManager
var input_manager: InputManager
var ui_manager: UIManager

# Configuration and settings
var game_config: GameConfig
var performance_settings: PerformanceSettings
var debug_settings: DebugSettings

# Event bus for decoupled communication
signal player_died
signal level_completed
signal enemy_spawned(enemy_data: EnemyData)
signal item_collected(item_data: ItemData)
signal game_paused
signal game_resumed
signal settings_changed

func _ready() -> void:
	if instance == null:
		instance = self
		_initialize_systems()
		_setup_event_connections()
	else:
		queue_free()

func _initialize_systems() -> void:
	# Load configuration
	game_config = GameConfig.new()
	performance_settings = PerformanceSettings.new()
	debug_settings = DebugSettings.new()
	
	# Initialize core systems
	_initialize_managers()
	_apply_settings()

func _initialize_managers() -> void:
	# Player management
	player_manager = PlayerManager.new()
	add_child(player_manager)
	
	# Enemy management
	enemy_manager = EnemyManager.new()
	add_child(enemy_manager)
	
	# Visual effects
	visual_effects_manager = VisualEffectsManager.new()
	add_child(visual_effects_manager)
	
	# Camera system
	camera_manager = EnhancedCamera2D.new()
	add_child(camera_manager)
	
	# Level generation
	level_generator = ProceduralLevelGenerator.new()
	add_child(level_generator)
	
	# Audio system
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	
	# Input management
	input_manager = InputManager.new()
	add_child(input_manager)
	
	# UI management
	ui_manager = UIManager.new()
	add_child(ui_manager)

func _setup_event_connections() -> void:
	# Connect core game events
	player_manager.player_died.connect(_on_player_died)
	enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	level_generator.generation_completed.connect(_on_level_generated)
	
	# Connect UI events
	ui_manager.pause_requested.connect(_on_pause_requested)
	ui_manager.resume_requested.connect(_on_resume_requested)

func _apply_settings() -> void:
	# Apply performance settings
	performance_settings.apply_to_engine()
	
	# Apply debug settings
	debug_settings.apply_to_engine()

# Event handlers
func _on_player_died() -> void:
	player_died.emit()
	ui_manager.show_death_screen()

func _on_all_enemies_defeated() -> void:
	level_completed.emit()
	ui_manager.show_victory_screen()

func _on_level_generated(level_data: Dictionary) -> void:
	enemy_manager.spawn_enemies_from_data(level_data.enemies)
	player_manager.respawn_at_start()

func _on_pause_requested() -> void:
	game_paused.emit()
	get_tree().paused = true

func _on_resume_requested() -> void:
	game_resumed.emit()
	get_tree().paused = false

# Public API for clean access to systems
func get_player() -> PlayerManager:
	return player_manager

func get_enemies() -> EnemyManager:
	return enemy_manager

func get_visual_effects() -> VisualEffectsManager:
	return visual_effects_manager

func get_camera() -> EnhancedCamera2D:
	return camera_manager

func get_level_generator() -> ProceduralLevelGenerator:
	return level_generator

func get_audio() -> AudioManager:
	return audio_manager

func get_input() -> InputManager:
	return input_manager

func get_ui() -> UIManager:
	return ui_manager

# Configuration management
func get_config() -> GameConfig:
	return game_config

func get_performance_settings() -> PerformanceSettings:
	return performance_settings

func get_debug_settings() -> DebugSettings:
	return debug_settings

# System health and monitoring
func get_system_health() -> Dictionary:
	return {
		"player": player_manager.is_healthy(),
		"enemies": enemy_manager.is_healthy(),
		"visual_effects": visual_effects_manager.is_healthy(),
		"camera": camera_manager.is_healthy(),
		"level_generator": level_generator.is_healthy(),
		"audio": audio_manager.is_healthy(),
		"input": input_manager.is_healthy(),
		"ui": ui_manager.is_healthy()
	}

func cleanup_systems() -> void:
	# Clean up all systems in reverse order
	ui_manager.cleanup()
	input_manager.cleanup()
	audio_manager.cleanup()
	level_generator.cleanup()
	camera_manager.cleanup()
	visual_effects_manager.cleanup()
	enemy_manager.cleanup()
	player_manager.cleanup()

# Save/Load system
func save_game() -> void:
	var save_data := {
		"player": player_manager.get_save_data(),
		"enemies": enemy_manager.get_save_data(),
		"level": level_generator.get_save_data(),
		"config": game_config.get_save_data(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file := FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_game() -> bool:
	var file := FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file:
		var save_data := file.get_var()
		file.close()
		
		player_manager.load_save_data(save_data.player)
		enemy_manager.load_save_data(save_data.enemies)
		level_generator.load_save_data(save_data.level)
		game_config.load_save_data(save_data.config)
		
		return true
	return false

# Debug and development tools
func enable_debug_mode() -> void:
	debug_settings.debug_enabled = true
	debug_settings.apply_to_engine()

func disable_debug_mode() -> void:
	debug_settings.debug_enabled = false
	debug_settings.apply_to_engine()

func get_performance_stats() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"memory_usage": OS.get_static_memory_usage_by_type(),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"objects": get_tree().get_node_count(),
		"visual_effects_count": visual_effects_manager.get_active_effects_count(),
		"enemy_count": enemy_manager.get_active_enemy_count()
	}
