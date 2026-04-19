extends Window
class_name GameMonitorWindow

# Dedicated window for monitoring automated game testing
# Shows real-time gameplay, performance metrics, and test progress

const AutomatedGameTester = preload("res://tests/AutomatedGameTester.gd")

@export var update_interval: float = 0.1  # Update every 100ms

var game_viewport: SubViewport
var game_texture: TextureRect
var stats_panel: Control
var control_panel: Control
var test_runner: AutomatedGameTester

# UI Elements
var fps_label: Label
var memory_label: Label
var frame_label: Label
var action_label: Label
var progress_bar: ProgressBar
var screenshot_label: Label
var log_text: RichTextLabel

func _ready() -> void:
	setup_window()
	create_ui_elements()
	start_monitoring()

func setup_window() -> void:
	title = "🎮 Glowfall - Automated Testing Monitor"
	size = Vector2i(1200, 800)
	position = Vector2i(50, 50)
	min_size = Vector2i(800, 600)

	# Make window always on top for testing
	always_on_top = true

func create_ui_elements() -> void:
	var main_container = HSplitContainer.new()
	add_child(main_container)
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Left panel - Game view
	var left_panel = create_game_view_panel()
	main_container.add_child(left_panel)

	# Right panel - Stats and controls
	var right_panel = create_stats_control_panel()
	main_container.add_child(right_panel)

func create_game_view_panel() -> Control:
	var panel = VBoxContainer.new()

	# Game title
	var title = Label.new()
	title.text = "🎮 Game View"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	# Game viewport
	game_viewport = SubViewport.new()
	game_viewport.size = Vector2i(640, 480)
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	panel.add_child(game_viewport)

	# Game texture display
	game_texture = TextureRect.new()
	game_texture.texture = game_viewport.get_texture()
	game_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	game_texture.custom_minimum_size = Vector2(640, 480)
	panel.add_child(game_texture)

	return panel

func create_stats_control_panel() -> Control:
	var panel = VBoxContainer.new()

	# Stats section
	stats_panel = create_stats_panel()
	panel.add_child(stats_panel)

	# Control section
	control_panel = create_control_panel()
	panel.add_child(control_panel)

	# Log section
	var log_panel = create_log_panel()
	panel.add_child(log_panel)

	return panel

func create_stats_panel() -> Control:
	var panel = VBoxContainer.new()

	# Stats title
	var title = Label.new()
	title.text = "📊 Performance Statistics"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	# FPS
	fps_label = Label.new()
	fps_label.text = "FPS: 0"
	panel.add_child(fps_label)

	# Memory
	memory_label = Label.new()
	memory_label.text = "Memory: 0 MB"
	panel.add_child(memory_label)

	# Frames
	frame_label = Label.new()
	frame_label.text = "Frames: 0"
	panel.add_child(frame_label)

	# Current action
	action_label = Label.new()
	action_label.text = "Action: Initializing"
	panel.add_child(action_label)

	# Progress
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100
	progress_bar.value = 0
	panel.add_child(progress_bar)

	# Screenshots
	screenshot_label = Label.new()
	screenshot_label.text = "Screenshots: 0"
	panel.add_child(screenshot_label)

	return panel

func create_control_panel() -> Control:
	var panel = VBoxContainer.new()

	# Controls title
	var title = Label.new()
	title.text = "🎛️ Test Controls"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	# Speed control
	var speed_container = HBoxContainer.new()
	panel.add_child(speed_container)

	var speed_label = Label.new()
	speed_label.text = "Speed:"
	speed_container.add_child(speed_label)

	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.5
	speed_slider.max_value = 5.0
	speed_slider.value = 1.0
	speed_slider.step = 0.5
	speed_container.add_child(speed_slider)

	var speed_value_label = Label.new()
	speed_value_label.text = "1.0x"
	speed_container.add_child(speed_value_label)

	# Connect speed slider
	speed_slider.value_changed.connect(func(value):
		speed_value_label.text = "%.1fx" % value
		if test_runner:
			Engine.time_scale = value
	)

	# Control buttons
	var button_container = HBoxContainer.new()
	panel.add_child(button_container)

	var pause_button = Button.new()
	pause_button.text = "⏸️ Pause"
	button_container.add_child(pause_button)

	var resume_button = Button.new()
	resume_button.text = "▶️ Resume"
	button_container.add_child(resume_button)

	var screenshot_button = Button.new()
	screenshot_button.text = "📸 Screenshot"
	button_container.add_child(screenshot_button)

	var stop_button = Button.new()
	stop_button.text = "⏹️ Stop"
	button_container.add_child(stop_button)

	# Connect button signals
	pause_button.pressed.connect(func():
		if test_runner: test_runner.get_tree().paused = true
	)

	resume_button.pressed.connect(func():
		if test_runner: test_runner.get_tree().paused = false
	)

	screenshot_button.pressed.connect(func():
		if test_runner: test_runner.capture_screenshot()
	)

	stop_button.pressed.connect(func():
		if test_runner: test_runner._end_test()
	)

	return panel

func create_log_panel() -> Control:
	var panel = VBoxContainer.new()

	# Log title
	var title = Label.new()
	title.text = "📝 Test Log"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	# Log text
	log_text = RichTextLabel.new()
	log_text.custom_minimum_size = Vector2(400, 200)
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	panel.add_child(log_text)

	# Clear button
	var clear_button = Button.new()
	clear_button.text = "🗑️ Clear Log"
	panel.add_child(clear_button)

	clear_button.pressed.connect(func(): log_text.clear())

	return panel

func start_monitoring() -> void:
	# Start update timer
	var timer = Timer.new()
	timer.wait_time = update_interval
	timer.timeout.connect(_update_monitoring)
	add_child(timer)
	timer.start()

	# Find test runner
	test_runner = get_tree().get_first_node_in_group("automated_tester")
	if test_runner:
		test_runner.test_completed.connect(_on_test_completed)

func _update_monitoring() -> void:
	if not test_runner:
		return

	# Update performance stats
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	memory_label.text = "Memory: %d MB" % (OS.get_static_memory_usage() / (1024 * 1024))
	frame_label.text = "Frames: %d" % test_runner.frame_count

	# Update game state
	action_label.text = "Action: %s" % test_runner.current_action

	# Update progress
	if test_runner.test_active:
		var elapsed = Time.get_time_dict_from_system().second - test_runner.test_start_time
		progress_bar.value = (elapsed / test_runner.test_duration) * 100

	# Update screenshots
	screenshot_label.text = "Screenshots: %d" % test_runner.screenshots_taken

	# Update game viewport
	if game_viewport and test_runner:
		# Copy main viewport to game viewport
		var main_viewport = get_viewport()
		game_viewport.world_2d = main_viewport.world_2d
		game_texture.texture = game_viewport.get_texture()

func _on_test_completed(results: Dictionary) -> void:
	# Add completion message to log
	log_text.append_text("[color=green]✅ Test completed![/color]\n")

	# Add results to log
	log_text.append_text("[b]Test Results:[/b]\n")
	log_text.append_text("Duration: %.1fs\n" % results.get("test_duration", 0))
	log_text.append_text("Average FPS: %.1f\n" % results.get("average_fps", 0))
	log_text.append_text("Screenshots: %d\n" % results.get("screenshots_taken", 0))

	# Show completion dialog
	show_completion_dialog(results)

func show_completion_dialog(results: Dictionary) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "🎉 Test Completed"
	dialog.dialog_text = "Automated test completed successfully!\n\n" + \
		"Duration: %.1f seconds\n" % results.get("test_duration", 0) + \
		"Average FPS: %.1f\n" % results.get("average_fps", 0) + \
		"Screenshots: %d" % results.get("screenshots_taken", 0)

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		dialog.queue_free()
	)

func add_log_entry(message: String, type: String = "info") -> void:
	var color = "white"
	match type:
		"info": color = "white"
		"success": color = "green"
		"warning": color = "yellow"
		"error": color = "red"

	log_text.append_text("[color=%s]%s[/color]\n" % [color, message])

func set_test_runner(runner: AutomatedGameTester) -> void:
	test_runner = runner
	test_runner.connect("test_event", add_log_entry)
