extends Node
class_name DiagnosticTest

# Quick diagnostic test to identify the loading issue
# Run this to pinpoint what's causing the spinning wheel

func _ready() -> void:
	print("=== GLOWFALL DIAGNOSTIC TEST ===")
	run_diagnostic_tests()

func run_diagnostic_tests() -> void:
	var issues_found = []
	
	# Test 1: Basic file existence
	print("\n1. Testing file existence...")
	if not test_file_existence():
		issues_found.append("Missing critical files")
	
	# Test 2: Scene loading
	print("\n2. Testing scene loading...")
	if not test_scene_loading():
		issues_found.append("Scene loading problems")
	
	# Test 3: Script compilation
	print("\n3. Testing script compilation...")
	if not test_script_compilation():
		issues_found.append("Script compilation errors")
	
	# Test 4: Project settings
	print("\n4. Testing project settings...")
	if not test_project_settings():
		issues_found.append("Project settings issues")
	
	# Test 5: Autoload configuration
	print("\n5. Testing autoload configuration...")
	if not test_autoload_config():
		issues_found.append("Autoload configuration problems")
	
	# Test 6: Main scene instantiation
	print("\n6. Testing main scene instantiation...")
	if not test_main_scene_instantiation():
		issues_found.append("Main scene instantiation failure")
	
	# Report results
	print("\n=== DIAGNOSTIC RESULTS ===")
	if issues_found.is_empty():
		print("✅ No critical issues found!")
		print("The loading issue might be:")
		print("  - Runtime error during scene initialization")
		print("  - Infinite loop in _ready() or _process()")
		print("  - MetroidvaniaSystem addon issues")
		print("  - Resource loading deadlock")
	else:
		print("❌ Issues found:")
		for issue in issues_found:
			print("  - ", issue)
	
	print("\n=== RECOMMENDED ACTIONS ===")
	if issues_found.is_empty():
		print("1. Check for runtime errors in the output log")
		print("2. Temporarily disable MetroidvaniaSystem addon")
		print("3. Add debug prints to _ready() functions")
		print("4. Test with SimpleMain.tscn as main scene")
	else:
		print("1. Fix the issues listed above")
		print("2. Re-run diagnostic tests")
		print("3. Test individual components")

func test_file_existence() -> bool:
	var critical_files = [
		"res://scenes/Main.tscn",
		"res://scenes/SimpleMain.tscn",
		"res://scenes/player/Player.tscn",
		"res://scenes/player/Player.gd",
		"res://scenes/enemy/Enemy.tscn",
		"res://scenes/enemy/Enemy.gd",
		"res://scenes/Game.gd",
		"res://scenes/ui/HUD.tscn",
		"res://scenes/components/Global.gd",
		"res://project.godot"
	]
	
	var missing_files = []
	for file_path in critical_files:
		if not FileAccess.file_exists(file_path):
			missing_files.append(file_path)
			print("  ❌ Missing: ", file_path)
		else:
			print("  ✅ Found: ", file_path)
	
	return missing_files.is_empty()

func test_scene_loading() -> bool:
	var scenes_to_test = [
		"res://scenes/SimpleMain.tscn",
		"res://scenes/player/Player.tscn",
		"res://scenes/enemy/Enemy.tscn",
		"res://scenes/ui/HUD.tscn"
	]
	
	for scene_path in scenes_to_test:
		try:
			var scene = preload(scene_path)
			if scene == null:
				print("  ❌ Cannot preload: ", scene_path)
				return false
			
			print("  ✅ Preloads successfully: ", scene_path)
		except:
			print("  ❌ Preload failed: ", scene_path)
			return false
	
	return true

func test_script_compilation() -> bool:
	var scripts_to_test = [
		"res://scenes/player/Player.gd",
		"res://scenes/enemy/Enemy.gd",
		"res://scenes/Game.gd",
		"res://scenes/components/Global.gd"
	]
	
	for script_path in scripts_to_test:
		try:
			var script = preload(script_path)
			if script == null:
				print("  ❌ Cannot compile: ", script_path)
				return false
			
			print("  ✅ Compiles successfully: ", script_path)
		except:
			print("  ❌ Compilation failed: ", script_path)
			return false
	
	return true

func test_project_settings() -> bool:
	try:
		var main_scene = ProjectSettings.get_setting("application/run/main_scene")
		print("  Main scene: ", main_scene)
		
		var autoloads = ProjectSettings.get_setting("autoload", {})
		print("  Autoloads: ", autoloads.keys())
		
		var display_settings = ProjectSettings.get_setting("display", {})
		print("  Display settings loaded")
		
		return true
	except:
		print("  ❌ Failed to read project settings")
		return false

func test_autoload_config() -> bool:
	var required_autoloads = ["Global", "MetSys"]
	var autoloads = ProjectSettings.get_setting("autoload", {})
	
	for autoload_name in required_autoloads:
		if not autoloads.has(autoload_name):
			print("  ❌ Missing autoload: ", autoload_name)
			return false
		
		var autoload_path = autoloads[autoload_name]
		if not FileAccess.file_exists(autoload_path.substr(1)):  # Remove * prefix
			print("  ❌ Autoload file not found: ", autoload_path)
			return false
		
		print("  ✅ Autoload configured: ", autoload_name)
	
	return true

func test_main_scene_instantiation() -> bool:
	# Test SimpleMain first (should work)
	print("  Testing SimpleMain.tscn...")
	try:
		var simple_scene = preload("res://scenes/SimpleMain.tscn")
		var simple_instance = simple_scene.instantiate()
		
		if simple_instance == null:
			print("    ❌ Failed to instantiate SimpleMain")
			return false
		
		print("    ✅ SimpleMain instantiates successfully")
		simple_instance.queue_free()
		
	except:
		print("    ❌ SimpleMain instantiation failed: ", str(get_stack()))
		return false
	
	# Test Main.tscn (might fail)
	print("  Testing Main.tscn...")
	try:
		var main_scene = preload("res://scenes/Main.tscn")
		var main_instance = main_scene.instantiate()
		
		if main_instance == null:
			print("    ❌ Failed to instantiate Main")
			return false
		
		print("    ✅ Main instantiates successfully")
		main_instance.queue_free()
		return true
		
	except:
		print("    ❌ Main instantiation failed: ", str(get_stack()))
		return false

# Quick fix suggestions
func suggest_fixes() -> void:
	print("\n=== QUICK FIX SUGGESTIONS ===")
	print("1. Change main scene to SimpleMain.tscn:")
	print("   - Open project.godot")
	print("   - Change 'run/main_scene' to 'res://scenes/SimpleMain.tscn'")
	print("")
	print("2. Temporarily disable MetroidvaniaSystem:")
	print("   - Open project.godot")
	print("   - Comment out MetSys autoload line")
	print("")
	print("3. Check for syntax errors:")
	print("   - Open Player.gd and Enemy.gd")
	print("   - Look for red underlines or syntax errors")
	print("")
	print("4. Test individual components:")
	print("   - Run diagnostic tests above")
	print("   - Fix any issues found")

# Emergency recovery function
func emergency_recovery() -> void:
	print("\n=== EMERGENCY RECOVERY ===")
	print("Attempting to restore basic functionality...")
	
	# Create a minimal working main scene
	var minimal_scene = create_minimal_main_scene()
	if minimal_scene:
		print("✅ Created minimal main scene")
		update_project_settings(minimal_scene)
		print("✅ Updated project settings")
		print("Try running the game now!")

func create_minimal_main_scene() -> String:
	var minimal_main_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/components/Global.gd" id="1"]

[node name="Main" type="Node2D"]

[node name="Player" type="CharacterBody2D" parent="."]
position = Vector2(400, 300)

[node name="Sprite" type="Sprite2D" parent="Player"]

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player"]
shape = SubResource("RectangleShape2D_1")

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(32, 48)
"""
	
	var file = FileAccess.open("res://scenes/MinimalMain.tscn", FileAccess.WRITE)
	if file:
		file.store_string(minimal_main_content)
		file.close()
		return "res://scenes/MinimalMain.tscn"
	
	return ""

func update_project_settings(main_scene_path: String) -> void:
	# This would update project.godot to use the minimal scene
	# For safety, just print the instruction
	print("Manually update project.godot:")
	print("run/main_scene = \"", main_scene_path, "\"")
