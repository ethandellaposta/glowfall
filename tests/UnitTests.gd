extends Node
class_name UnitTests

# Focused unit tests for individual components
# These tests run quickly and help isolate specific issues

func run_all_unit_tests() -> Dictionary:
	print("Running focused unit tests...")
	var results = {}
	
	# Core Component Tests
	results["player_scene"] = test_player_scene()
	results["enemy_scene"] = test_enemy_scene()
	results["hud_scene"] = test_hud_scene()
	results["main_scene"] = test_main_scene()
	
	# Script Tests
	results["player_script"] = test_player_script()
	results["enemy_script"] = test_enemy_script()
	results["game_script"] = test_game_script()
	
	# Resource Tests
	results["autoload_scripts"] = test_autoload_scripts()
	results["shader_resources"] = test_shader_resources()
	results["component_scripts"] = test_component_scripts()
	
	# Physics Tests
	results["physics_settings"] = test_physics_settings()
	results["collision_shapes"] = test_collision_shapes()
	
	return results

func test_player_scene() -> bool:
	print("Testing Player scene...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		if player_scene == null:
			print("❌ Player scene not found")
			return false
		
		var player = player_scene.instantiate()
		if player == null:
			print("❌ Failed to instantiate Player")
			return false
		
		# Test required nodes
		var sprite = player.get_node_or_null("Sprite")
		if sprite == null:
			print("❌ Player missing Sprite node")
			return false
		
		var collision = player.get_node_or_null("CollisionShape2D")
		if collision == null:
			print("❌ Player missing CollisionShape2D")
			return false
		
		var attack_area = player.get_node_or_null("AttackArea")
		if attack_area == null:
			print("❌ Player missing AttackArea")
			return false
		
		print("✅ Player scene valid")
		player.queue_free()
		return true
		
	except:
		print("❌ Player scene test failed: ", str(get_stack()))
		return false

func test_enemy_scene() -> bool:
	print("Testing Enemy scene...")
	
	try:
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		if enemy_scene == null:
			print("❌ Enemy scene not found")
			return false
		
		var enemy = enemy_scene.instantiate()
		if enemy == null:
			print("❌ Failed to instantiate Enemy")
			return false
		
		# Test required nodes
		var sprite = enemy.get_node_or_null("Sprite")
		if sprite == null:
			print("❌ Enemy missing Sprite node")
			return false
		
		var collision = enemy.get_node_or_null("CollisionShape2D")
		if collision == null:
			print("❌ Enemy missing CollisionShape2D")
			return false
		
		print("✅ Enemy scene valid")
		enemy.queue_free()
		return true
		
	except:
		print("❌ Enemy scene test failed: ", str(get_stack()))
		return false

func test_hud_scene() -> bool:
	print("Testing HUD scene...")
	
	try:
		var hud_scene = preload("res://scenes/ui/HUD.tscn")
		if hud_scene == null:
			print("❌ HUD scene not found")
			return false
		
		var hud = hud_scene.instantiate()
		if hud == null:
			print("❌ Failed to instantiate HUD")
			return false
		
		print("✅ HUD scene valid")
		hud.queue_free()
		return true
		
	except:
		print("❌ HUD scene test failed: ", str(get_stack()))
		return false

func test_main_scene() -> bool:
	print("Testing Main scene...")
	
	try:
		var main_scene = preload("res://scenes/Main.tscn")
		if main_scene == null:
			print("❌ Main scene not found")
			return false
		
		print("✅ Main scene valid")
		return true
		
	except:
		print("❌ Main scene test failed: ", str(get_stack()))
		return false

func test_player_script() -> bool:
	print("Testing Player script...")
	
	try:
		var player_script = preload("res://scenes/player/Player.gd")
		if player_script == null:
			print("❌ Player script not found")
			return false
		
		print("✅ Player script valid")
		return true
		
	except:
		print("❌ Player script test failed: ", str(get_stack()))
		return false

func test_enemy_script() -> bool:
	print("Testing Enemy script...")
	
	try:
		var enemy_script = preload("res://scenes/enemy/Enemy.gd")
		if enemy_script == null:
			print("❌ Enemy script not found")
			return false
		
		print("✅ Enemy script valid")
		return true
		
	except:
		print("❌ Enemy script test failed: ", str(get_stack()))
		return false

func test_game_script() -> bool:
	print("Testing Game script...")
	
	try:
		var game_script = preload("res://scenes/Game.gd")
		if game_script == null:
			print("❌ Game script not found")
			return false
		
		print("✅ Game script valid")
		return true
		
	except:
		print("❌ Game script test failed: ", str(get_stack()))
		return false

func test_autoload_scripts() -> bool:
	print("Testing autoload scripts...")
	
	try:
		var global_script = preload("res://scenes/components/Global.gd")
		if global_script == null:
			print("❌ Global script not found")
			return false
		
		print("✅ Autoload scripts valid")
		return true
		
	except:
		print("❌ Autoload scripts test failed: ", str(get_stack()))
		return false

func test_shader_resources() -> bool:
	print("Testing shader resources...")
	
	try:
		# Test if shader files exist (they might not be preloaded)
		var pixel_shader_path = "res://shaders/pixel_art_enhanced.gdshader"
		var lighting_shader_path = "res://shaders/advanced_lighting.gdshader"
		var effects_shader_path = "res://shaders/screen_effects.gdshader"
		
		if not FileAccess.file_exists(pixel_shader_path):
			print("❌ Pixel art shader not found")
			return false
		
		if not FileAccess.file_exists(lighting_shader_path):
			print("❌ Lighting shader not found")
			return false
		
		if not FileAccess.file_exists(effects_shader_path):
			print("❌ Screen effects shader not found")
			return false
		
		print("✅ Shader resources valid")
		return true
		
	except:
		print("❌ Shader resources test failed: ", str(get_stack()))
		return false

func test_component_scripts() -> bool:
	print("Testing component scripts...")
	
	var component_paths = [
		"res://scenes/components/VisualEffectsManager.gd",
		"res://scenes/components/PerformanceOptimizer.gd",
		"res://scenes/components/GameArchitectureManager.gd",
		"res://scenes/components/ProceduralLevelGenerator.gd",
		"res://scenes/components/GameConfig.gd",
		"res://scenes/components/PerformanceSettings.gd"
	]
	
	for path in component_paths:
		try:
			var script = preload(path)
			if script == null:
				print("❌ Component script not found: ", path)
				return false
		except:
			print("❌ Failed to load component script: ", path)
			return false
	
	print("✅ Component scripts valid")
	return true

func test_physics_settings() -> bool:
	print("Testing physics settings...")
	
	try:
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		if gravity == null:
			print("❌ Gravity setting not found")
			return false
		
		if gravity <= 0:
			print("❌ Invalid gravity value: ", gravity)
			return false
		
		print("✅ Physics settings valid")
		return true
		
	except:
		print("❌ Physics settings test failed: ", str(get_stack()))
		return false

func test_collision_shapes() -> bool:
	print("Testing collision shapes...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		
		var collision = player.get_node("CollisionShape2D")
		if collision == null:
			print("❌ Player collision shape not found")
			player.queue_free()
			return false
		
		if collision.shape == null:
			print("❌ Player collision shape has no shape")
			player.queue_free()
			return false
		
		print("✅ Collision shapes valid")
		player.queue_free()
		return true
		
	except:
		print("❌ Collision shapes test failed: ", str(get_stack()))
		return false

# Quick diagnostic tests
func diagnose_loading_issue() -> void:
	print("=== DIAGNOSTIC TESTS ===")
	
	var issues = []
	
	# Test main scene
	if not test_main_scene():
		issues.append("Main scene loading issue")
	
	# Test player scene
	if not test_player_scene():
		issues.append("Player scene loading issue")
	
	# Test enemy scene
	if not test_enemy_scene():
		issues.append("Enemy scene loading issue")
	
	# Test scripts
	if not test_player_script():
		issues.append("Player script issue")
	
	if not test_enemy_script():
		issues.append("Enemy script issue")
	
	if not test_game_script():
		issues.append("Game script issue")
	
	# Test autoloads
	if not test_autoload_scripts():
		issues.append("Autoload script issue")
	
	# Test physics
	if not test_physics_settings():
		issues.append("Physics settings issue")
	
	# Report findings
	if issues.is_empty():
		print("✅ No obvious issues found in diagnostic tests")
	else:
		print("❌ Potential issues found:")
		for issue in issues:
			print("  - ", issue)
	
	print("=== END DIAGNOSTIC ===")
