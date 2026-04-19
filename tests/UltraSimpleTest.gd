extends Node

# Ultra-simple test - just check if basic Godot works

func _ready() -> void:
	print("=== ULTRA SIMPLE TEST ===")
	print("✅ Godot is working")
	print("✅ This script loads")
	print("✅ _ready() function called")

	# Test basic functionality
	test_basic_functionality()

	# Try to load just the player scene
	test_player_scene()

	# Try to load the main scene
	test_main_scene()

func test_basic_functionality() -> void:
	print("\n🔍 Testing basic functionality...")

	# Test basic Godot features
	print("✅ Engine.time_scale: ", Engine.time_scale)
	print("✅ Engine.fps: ", Engine.get_frames_per_second())
	print("✅ OS.get_static_memory_usage(): ", OS.get_static_memory_usage())

func test_player_scene() -> void:
	print("\n🔍 Testing player scene...")

	var player_scene = preload("res://scenes/player/Player.tscn")
	if player_scene == null:
		print("❌ Player scene preload failed")
		return

	print("✅ Player scene preloaded successfully")

	# Try to instantiate
	var player = player_scene.instantiate()
	if player == null:
		print("❌ Player instantiation failed")
		return

	print("✅ Player instantiated successfully")
	print("✅ Player type: ", player.get_class())

	# Clean up
	player.queue_free()

func test_main_scene() -> void:
	print("\n🔍 Testing main scene...")

	var main_scene = preload("res://scenes/Main.tscn")
	if main_scene == null:
		print("❌ Main scene preload failed")
		return

	print("✅ Main scene preloaded successfully")

	# Try to instantiate
	var main = main_scene.instantiate()
	if main == null:
		print("❌ Main scene instantiation failed")
		return

	print("✅ Main scene instantiated successfully")
	print("✅ Main scene type: ", main.get_class())

	# Check what nodes it has
	print("✅ Main scene children:")
	for child in main.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")

	# Clean up
	main.queue_free()

func _process(delta: float) -> void:
	# Show that we're still running
	if Engine.get_frames_drawn() % 60 == 0:  # Every second
		print("📊 Still running... Frame: ", Engine.get_frames_drawn())
