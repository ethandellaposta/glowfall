extends Node
class_name AutomatedGameTester

# Automated game testing system with visual monitoring
# Runs the game, plays it automatically, and provides real-time feedback

# Class imports
const PerformanceMonitor = preload("res://tests/PerformanceMonitor.gd")
const InputSimulator = preload("res://tests/InputSimulator.gd")
const GameAnalyzer = preload("res://tests/GameAnalyzer.gd")

@export var speed_multiplier: float = 2.0  # Speed up gameplay for testing
@export var show_debug_window: bool = true
@export var auto_play: bool = true
@export var test_duration: float = 30.0  # Test duration in seconds
@export var capture_screenshots: bool = true
@export var generate_video: bool = false

# Game state monitoring
var game_window: Window
var debug_panel: Control
var performance_monitor: PerformanceMonitor
var input_simulator: InputSimulator
var game_analyzer: GameAnalyzer

# Test state
var test_active: bool = false
var test_start_time: float = 0.0
var current_fps: float = 0.0
var frame_count: int = 0
var screenshots_taken: int = 0

# Automated gameplay state
var player_position: Vector2
var enemies_detected: Array[Node2D]
var objectives_completed: Array[String]
var current_action: String = "Initializing"
var action_timer: float = 0.0

func _ready() -> void:
	print("=== AUTOMATED GAME TESTER INITIALIZED ===")
	setup_test_environment()
	if auto_play:
		start_automated_test()

func setup_test_environment() -> void:
	# Create debug window
	if show_debug_window:
		create_debug_window()

	# Initialize monitoring systems
	performance_monitor = PerformanceMonitor.new()

	input_simulator = InputSimulator.new()

	game_analyzer = GameAnalyzer.new()

	# Connect to game signals
	_connect_to_game_signals()

func create_debug_window() -> void:
	# Create separate window for monitoring
	game_window = Window.new()
	game_window.title = "Glowfall - Automated Testing"
	game_window.size = Vector2i(800, 600)
	game_window.position = Vector2i(100, 100)
	add_child(game_window)

	# Create debug panel
	debug_panel = create_debug_panel()
	game_window.add_child(debug_panel)

func create_debug_panel() -> Control:
	var panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Create UI elements
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Title label
	var title = Label.new()
	title.text = "🎮 Glowfall Automated Testing"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Performance stats
	var perf_label = Label.new()
	perf_label.name = "PerformanceLabel"
	vbox.add_child(perf_label)

	# Game state
	var state_label = Label.new()
	state_label.name = "StateLabel"
	vbox.add_child(state_label)

	# Current action
	var action_label = Label.new()
	action_label.name = "ActionLabel"
	vbox.add_child(action_label)

	# Progress bar
	var progress = ProgressBar.new()
	progress.name = "ProgressBar"
	progress.max_value = test_duration
	vbox.add_child(progress)

	# Screenshot counter
	var screenshot_label = Label.new()
	screenshot_label.name = "ScreenshotLabel"
	vbox.add_child(screenshot_label)

	return panel

func _connect_to_game_signals() -> void:
	# Connect to game events if available
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node:
		if game_node.has_signal("player_died"):
			game_node.player_died.connect(_on_player_died)
		if game_node.has_signal("level_completed"):
			game_node.level_completed.connect(_on_level_completed)

func start_automated_test() -> void:
	print("🚀 Starting automated game test...")
	test_active = true
	test_start_time = Time.get_time_dict_from_system().second

	# Load the actual game
	load_game_scene()

	# Start monitoring
	performance_monitor.start_monitoring()

	# Start automated gameplay
	if auto_play:
		start_automated_gameplay()

func load_game_scene() -> void:
	# Load the main game scene
	var main_scene = preload("res://scenes/Main.tscn")
	if main_scene == null:
		# Fallback to simple main
		main_scene = preload("res://scenes/SimpleMain.tscn")

	var game_instance = main_scene.instantiate()
	get_tree().root.call_deferred("add_child", game_instance)

	print("✅ Game scene loaded for testing")

func start_automated_gameplay() -> void:
	print("🎮 Starting automated gameplay...")

	# Create gameplay timer
	var gameplay_timer = Timer.new()
	gameplay_timer.wait_time = test_duration
	gameplay_timer.timeout.connect(_end_test)
	add_child(gameplay_timer)
	gameplay_timer.start()

	# Start input simulation
	input_simulator.start_simulation()

func _process(delta: float) -> void:
	if not test_active:
		return

	# Update performance monitoring
	update_performance_stats(delta)

	# Update debug panel
	if debug_panel:
		update_debug_panel()

	# Execute automated gameplay
	if auto_play:
		execute_automated_gameplay(delta)

	# Capture screenshots
	if capture_screenshots and frame_count % 60 == 0:  # Every second at 60 FPS
		capture_screenshot()

func update_performance_stats(delta: float) -> void:
	frame_count += 1
	current_fps = Engine.get_frames_per_second()

	# Update performance monitor
	performance_monitor.update_stats(current_fps, delta)

func update_debug_panel() -> void:
	if not debug_panel:
		return

	var perf_label = debug_panel.get_node_or_null("PerformanceLabel")
	if perf_label:
		perf_label.text = "📊 Performance:\n  FPS: %d\n  Memory: %d MB\n  Frame: %d" % [
			current_fps,
			OS.get_static_memory_usage() / (1024 * 1024),
			frame_count
		]

	var state_label = debug_panel.get_node_or_null("StateLabel")
	if state_label:
		state_label.text = "🎮 Game State:\n  Position: %s\n  Enemies: %d\n  Objectives: %d" % [
			get_player_position_string(),
			enemies_detected.size(),
			objectives_completed.size()
		]

	var action_label = debug_panel.get_node_or_null("ActionLabel")
	if action_label:
		action_label.text = "🤖 Current Action: %s\n  Timer: %.1fs" % [current_action, action_timer]

	var progress_bar = debug_panel.get_node_or_null("ProgressBar")
	if progress_bar:
		var elapsed = Time.get_time_dict_from_system().second - test_start_time
		progress_bar.value = elapsed

	var screenshot_label = debug_panel.get_node_or_null("ScreenshotLabel")
	if screenshot_label:
		screenshot_label.text = "📸 Screenshots: %d" % screenshots_taken

func execute_automated_gameplay(delta: float) -> void:
	action_timer += delta

	# Get player reference
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Update player position
	player_position = player.global_position

	# Detect enemies
	detect_enemies()

	# Execute AI behavior based on game state
	execute_ai_behavior(player, delta)

func execute_ai_behavior(player: Node2D, delta: float) -> void:
	# Simple AI behavior for testing
	match current_action:
		"Initializing":
			if action_timer > 1.0:
				current_action = "Exploring"
				action_timer = 0.0

		"Exploring":
			# Move right and jump occasionally
			input_simulator.simulate_movement("right", true)
			if action_timer > 2.0:
				input_simulator.simulate_jump()
				action_timer = 0.0

			# Check for enemies
			if enemies_detected.size() > 0:
				current_action = "Combat"
				action_timer = 0.0

		"Combat":
			# Face nearest enemy and attack
			var nearest_enemy = get_nearest_enemy()
			if nearest_enemy:
				face_enemy(player, nearest_enemy)
				input_simulator.simulate_attack()

			if action_timer > 3.0:
				current_action = "Exploring"
				action_timer = 0.0

func detect_enemies() -> void:
	enemies_detected.clear()
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.global_position.distance_to(player_position) < 200:
			enemies_detected.append(enemy)

func get_nearest_enemy() -> Node2D:
	if enemies_detected.is_empty():
		return null

	var nearest = enemies_detected[0]
	var min_dist = player_position.distance_to(nearest.global_position)

	for enemy in enemies_detected:
		var dist = player_position.distance_to(enemy.global_position)
		if dist < min_dist:
			nearest = enemy
			min_dist = dist

	return nearest

func face_enemy(player: Node2D, enemy: Node2D) -> void:
	var direction = (enemy.global_position - player.global_position).normalized()
	if direction.x > 0:
		input_simulator.simulate_movement("right", true)
		input_simulator.simulate_movement("left", false)
	else:
		input_simulator.simulate_movement("left", true)
		input_simulator.simulate_movement("right", false)

func capture_screenshot() -> void:
	var screenshot_path = "user://screenshots/test_%d.png" % screenshots_taken
	var image = get_viewport().get_texture().get_image()
	image.save_png(screenshot_path)
	screenshots_taken += 1
	print("📸 Screenshot saved: ", screenshot_path)

func get_player_position_string() -> String:
	return "(%.0f, %.0f)" % [player_position.x, player_position.y]

func _on_player_died() -> void:
	print("💀 Player died during test")
	objectives_completed.append("player_death_test")
	current_action = "Respawning"

func _on_level_completed() -> void:
	print("🎉 Level completed during test")
	objectives_completed.append("level_completion_test")
	current_action = "Celebrating"

func _end_test() -> void:
	print("🏁 Automated test completed!")
	test_active = false

	# Generate test report
	generate_test_report()

	# Cleanup
	cleanup_test()

func generate_test_report() -> void:
	var report = {
		"test_duration": test_duration,
		"frames_processed": frame_count,
		"average_fps": performance_monitor.get_average_fps(),
		"screenshots_taken": screenshots_taken,
		"objectives_completed": objectives_completed,
		"enemies_encountered": enemies_detected.size(),
		"memory_peak": performance_monitor.get_peak_memory(),
		"performance_issues": performance_monitor.get_performance_issues()
	}

	print("\n" + "=".repeat(60))
	print("📊 AUTOMATED TEST REPORT")
	print("=".repeat(60))
	print("Test Duration: %.1f seconds" % report.test_duration)
	print("Frames Processed: %d" % report.frames_processed)
	print("Average FPS: %.1f" % report.average_fps)
	print("Screenshots Taken: %d" % report.screenshots_taken)
	print("Objectives Completed: %d" % report.objectives_completed.size())
	print("Enemies Encountered: %d" % report.enemies_encountered)
	print("Peak Memory: %d MB" % report.memory_peak)

	if report.performance_issues.size() > 0:
		print("\n⚠️ Performance Issues:")
		for issue in report.performance_issues:
			print("  - ", issue)
	else:
		print("\n✅ No performance issues detected!")

	print("=".repeat(60))

func cleanup_test() -> void:
	# Stop monitoring
	performance_monitor.stop_monitoring()
	input_simulator.stop_simulation()

	# Close debug window
	if game_window:
		game_window.queue_free()

	# Exit after short delay
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
