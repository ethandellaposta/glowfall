extends Node
class_name SpeedControlManager

# Manages game speed for automated testing and E2E scenarios
# Allows dynamic speed adjustment for faster testing

@export var default_speed: float = 1.0
@export var max_speed: float = 10.0
@export var min_speed: float = 0.1
@export var speed_step: float = 0.5

var current_speed: float = 1.0
var speed_profiles: Dictionary = {}

func _ready() -> void:
	setup_speed_profiles()
	apply_speed(default_speed)

func setup_speed_profiles() -> void:
	# Define different speed profiles for various testing scenarios
	speed_profiles = {
		"normal": {"speed": 1.0, "physics_fps": 60, "audio_pitch": 1.0},
		"fast": {"speed": 2.0, "physics_fps": 120, "audio_pitch": 1.2},
		"very_fast": {"speed": 5.0, "physics_fps": 300, "audio_pitch": 1.5},
		"ultra_fast": {"speed": 10.0, "physics_fps": 600, "audio_pitch": 2.0},
		"slow_motion": {"speed": 0.5, "physics_fps": 30, "audio_pitch": 0.8},
		"bullet_time": {"speed": 0.1, "physics_fps": 6, "audio_pitch": 0.3}
	}

func set_speed_profile(profile_name: String) -> void:
	if not speed_profiles.has(profile_name):
		print("⚠️ Speed profile not found: ", profile_name)
		return

	var profile = speed_profiles[profile_name]
	apply_speed(profile.speed)

	print("🚀 Applied speed profile: ", profile_name, " (", profile.speed, "x)")

func apply_speed(speed: float) -> void:
	current_speed = clamp(speed, min_speed, max_speed)

	# Apply time scale
	Engine.time_scale = current_speed

	# Adjust physics tick rate for consistent physics
	Engine.physics_ticks_per_second = int(60 * current_speed)

	print("⚡ Game speed set to: ", current_speed, "x")

func increase_speed() -> void:
	var new_speed = current_speed + speed_step
	apply_speed(new_speed)

func decrease_speed() -> void:
	var new_speed = current_speed - speed_step
	apply_speed(new_speed)

func toggle_speed() -> void:
	if current_speed == default_speed:
		set_speed_profile("fast")
	else:
		apply_speed(default_speed)

func get_current_speed() -> float:
	return current_speed

func is_speed_changed() -> bool:
	return current_speed != default_speed

func reset_speed() -> void:
	apply_speed(default_speed)

# Speed automation for testing scenarios
func automate_speed_for_scenario(scenario: String) -> void:
	match scenario:
		"e2e_testing":
			# Start fast for exploration, slow for combat
			set_speed_profile("very_fast")
			await get_tree().create_timer(5.0).timeout
			set_speed_profile("normal")

		"performance_testing":
			# Test various speed levels
			var speeds = [1.0, 2.0, 5.0, 10.0]
			for speed in speeds:
				apply_speed(speed)
				await get_tree().create_timer(2.0).timeout

		"visual_testing":
			# Slow motion for visual verification
			set_speed_profile("slow_motion")
			await get_tree().create_timer(3.0).timeout
			reset_speed()

func create_speed_control_ui() -> Control:
	var panel = VBoxContainer.new()

	# Title
	var title = Label.new()
	title.text = "⚡ Speed Control"
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	# Current speed display
	var speed_label = Label.new()
	speed_label.text = "Current Speed: %.1fx" % current_speed
	panel.add_child(speed_label)

	# Speed slider
	var speed_slider = HSlider.new()
	speed_slider.min_value = min_speed
	speed_slider.max_value = max_speed
	speed_slider.value = current_speed
	speed_slider.step = speed_step
	panel.add_child(speed_slider)

	# Connect slider
	speed_slider.value_changed.connect(func(value):
		apply_speed(value)
		speed_label.text = "Current Speed: %.1fx" % value
	)

	# Profile buttons
	var profile_container = HBoxContainer.new()
	panel.add_child(profile_container)

	for profile_name in speed_profiles.keys():
		var button = Button.new()
		button.text = profile_name.capitalize()
		button.pressed.connect(func(): set_speed_profile(profile_name))
		profile_container.add_child(button)

	# Control buttons
	var control_container = HBoxContainer.new()
	panel.add_child(control_container)

	var increase_btn = Button.new()
	increase_btn.text = "⏩ Faster"
	increase_btn.pressed.connect(increase_speed)
	control_container.add_child(increase_btn)

	var decrease_btn = Button.new()
	decrease_btn.text = "⏪ Slower"
	decrease_btn.pressed.connect(decrease_speed)
	control_container.add_child(decrease_btn)

	var reset_btn = Button.new()
	reset_btn.text = "🔄 Reset"
	reset_btn.pressed.connect(reset_speed)
	control_container.add_child(reset_btn)

	return panel
