extends Node

# Test to identify the rendering issue

func _ready() -> void:
	print("=== RENDERING TEST ===")
	
	# Create a visible test element
	create_test_visual()
	
	# Load the game
	load_game_with_camera()

func create_test_visual() -> void:
	print("🎨 Creating test visual...")
	
	# Create a simple colored rectangle
	var rect = ColorRect.new()
	rect.size = Vector2(200, 200)
	rect.position = Vector2(100, 100)
	rect.color = Color.RED
	add_child(rect)
	
	print("✅ Red rectangle added at (100, 100)")
	
	# Create a label
	var label = Label.new()
	label.text = "RENDERING TEST"
	label.position = Vector2(50, 50)
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color.WHITE
	add_child(label)
	
	print("✅ Label added at (50, 50)")

func load_game_with_camera() -> void:
	print("🎮 Loading game with camera...")
	
	# Load main scene
	var main_scene = preload("res://scenes/Main.tscn")
	var game = main_scene.instantiate()
	add_child(game)
	
	print("✅ Game loaded")
	
	# Find or create camera
	var camera = find_camera()
	if camera:
		print("✅ Camera found: ", camera.name)
		camera.enabled = true
		camera.make_current()
	else:
		print("❌ No camera found - creating one")
		create_camera()

func find_camera() -> Camera2D:
	# Look for camera in the tree
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		return cameras[0]
	
	# Look for any Camera2D node
	var all_cameras = get_tree().get_nodes_in_group("Camera2D")
	if all_cameras.size() > 0:
		return all_cameras[0]
	
	return null

func create_camera() -> void:
	print("📷 Creating camera...")
	
	var camera = Camera2D.new()
	camera.name = "TestCamera"
	camera.position = Vector2(400, 300)
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	
	print("✅ Camera created and made current")

func _process(_delta: float) -> void:
	# Show we're still running
	if Engine.get_frames_drawn() % 120 == 0:  # Every 2 seconds
		print("📊 Rendering test running... Frame: ", Engine.get_frames_drawn())
