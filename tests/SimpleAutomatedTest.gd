extends Node
class_name SimpleAutomatedTest

# Simple automated test that just loads and runs the game

func _ready() -> void:
	print("=== SIMPLE AUTOMATED TEST ===")
	print("✅ Test system loaded successfully")
	
	# Load the main game scene
	load_game()
	
	# Start simple monitoring
	start_monitoring()

func load_game() -> void:
	print("🎮 Loading game scene...")
	
	var main_scene = preload("res://scenes/Main.tscn")
	if main_scene == null:
		print("❌ Main scene not found")
		return
	
	var game_instance = main_scene.instantiate()
	add_child(game_instance)
	
	print("✅ Game loaded successfully!")
	print("🎮 Game is now running...")
	print("📊 Monitoring performance...")

func start_monitoring() -> void:
	# Simple performance monitoring
	var timer = Timer.new()
	timer.wait_time = 1.0  # Update every second
	timer.timeout.connect(_update_stats)
	add_child(timer)
	timer.start()

func _update_stats() -> void:
	var fps = Engine.get_frames_per_second()
	var memory = OS.get_static_memory_usage() / (1024 * 1024)
	
	print("📊 FPS: ", fps, " | Memory: ", memory, " MB")
	
	# Check if game is running properly
	if fps > 0:
		print("✅ Game running normally")
	else:
		print("⚠️ Game may have issues")
