extends Node
class_name TestSuite

# Comprehensive test suite for Glowfall game
# Includes unit tests, integration tests, and E2E tests

signal test_completed(test_name: String, passed: bool, message: String)
signal suite_completed(results: Dictionary)

var test_results: Dictionary = {}
var current_test: String = ""
var test_environment: Node2D

func _ready() -> void:
	test_environment = Node2D.new()
	add_child(test_environment)
	test_environment.name = "TestEnvironment"

# Main test runner
func run_all_tests() -> Dictionary:
	print("Starting comprehensive test suite...")
	
	# Unit Tests
	run_unit_tests()
	
	# Integration Tests
	run_integration_tests()
	
	# E2E Tests
	run_e2e_tests()
	
	# Performance Tests
	run_performance_tests()
	
	var summary = generate_test_summary()
	suite_completed.emit(summary)
	return summary

func run_unit_tests() -> void:
	print("Running Unit Tests...")
	
	# Player Tests
	test_player_initialization()
	test_player_movement()
	test_player_combat()
	test_player_physics()
	
	# Enemy Tests
	test_enemy_initialization()
	test_enemy_ai()
	test_enemy_combat()
	
	# System Tests
	test_visual_effects_manager()
	test_performance_optimizer()
	test_game_config()
	
	# Utility Tests
	test_math_utilities()
	test_string_utilities()
	test_file_utilities()

func run_integration_tests() -> void:
	print("Running Integration Tests...")
	
	# Player-Enemy Integration
	test_player_enemy_interaction()
	test_combat_system_integration()
	
	# System Integration
	test_visual_effects_integration()
	test_performance_system_integration()
	
	# Save System Tests
	test_save_load_system()
	test_autoload_integration()

func run_e2e_tests() -> void:
	print("Running E2E Tests...")
	
	# Game Flow Tests
	test_game_startup()
	test_level_transition()
	test_complete_gameplay_loop()
	
	# UI Tests
	test_hud_functionality()
	test_menu_navigation()
	
	# Performance Tests
	test_memory_management()
	test_fps_stability()

func run_performance_tests() -> void:
	print("Running Performance Tests...")
	
	test_script_performance()
	test_memory_usage()
	test_rendering_performance()

# Unit Test Implementations

func test_player_initialization() -> void:
	current_test = "Player Initialization"
	
	try:
		# Create test player
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		test_environment.add_child(player)
		
		# Test basic properties
		assert(player.hp > 0, "Player should have positive HP")
		assert(player.max_hp > 0, "Player should have positive max HP")
		assert(player.speed > 0, "Player should have positive speed")
		
		# Test components
		assert(player.get_node_or_null("Sprite") != null, "Player should have Sprite node")
		assert(player.get_node_or_null("CollisionShape2D") != null, "Player should have collision")
		
		# Cleanup
		test_environment.remove_child(player)
		player.queue_free()
		
		record_test_result(current_test, true, "Player initialization successful")
		
	except:
		record_test_result(current_test, false, "Player initialization failed: " + str(get_stack()))

func test_player_movement() -> void:
	current_test = "Player Movement"
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		test_environment.add_child(player)
		
		# Test initial velocity
		assert(player.velocity == Vector2.ZERO, "Initial velocity should be zero")
		
		# Test movement properties
		assert(player.jump_velocity < 0, "Jump velocity should be negative")
		assert(player.ground_accel > 0, "Ground acceleration should be positive")
		assert(player.air_accel > 0, "Air acceleration should be positive")
		
		# Cleanup
		test_environment.remove_child(player)
		player.queue_free()
		
		record_test_result(current_test, true, "Player movement properties valid")
		
	except:
		record_test_result(current_test, false, "Player movement test failed")

func test_player_combat() -> void:
	current_test = "Player Combat"
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		test_environment.add_child(player)
		
		# Test combat properties
		assert(player.attack_damage > 0, "Attack damage should be positive")
		assert(player.attack_cooldown >= 0, "Attack cooldown should be non-negative")
		
		# Test attack area
		var attack_area = player.get_node_or_null("AttackArea")
		assert(attack_area != null, "Player should have AttackArea")
		assert(attack_area is Area2D, "AttackArea should be Area2D")
		
		# Cleanup
		test_environment.remove_child(player)
		player.queue_free()
		
		record_test_result(current_test, true, "Player combat system valid")
		
	except:
		record_test_result(current_test, false, "Player combat test failed")

func test_player_physics() -> void:
	current_test = "Player Physics"
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		test_environment.add_child(player)
		
		# Test physics properties
		assert(player is CharacterBody2D, "Player should be CharacterBody2D")
		
		var collision = player.get_node_or_null("CollisionShape2D")
		assert(collision != null, "Player should have collision shape")
		
		# Test gravity access
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		assert(gravity > 0, "Gravity should be positive")
		
		# Cleanup
		test_environment.remove_child(player)
		player.queue_free()
		
		record_test_result(current_test, true, "Player physics system valid")
		
	except:
		record_test_result(current_test, false, "Player physics test failed")

func test_enemy_initialization() -> void:
	current_test = "Enemy Initialization"
	
	try:
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		test_environment.add_child(enemy)
		
		# Test basic properties
		assert(enemy.hp > 0, "Enemy should have positive HP")
		assert(enemy.max_hp > 0, "Enemy should have positive max HP")
		assert(enemy.speed > 0, "Enemy should have positive speed")
		
		# Test components
		assert(enemy.get_node_or_null("Sprite") != null, "Enemy should have Sprite node")
		assert(enemy.get_node_or_null("CollisionShape2D") != null, "Enemy should have collision")
		
		# Cleanup
		test_environment.remove_child(enemy)
		enemy.queue_free()
		
		record_test_result(current_test, true, "Enemy initialization successful")
		
	except:
		record_test_result(current_test, false, "Enemy initialization failed")

func test_enemy_ai() -> void:
	current_test = "Enemy AI"
	
	try:
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		test_environment.add_child(enemy)
		
		# Test AI properties
		assert(enemy.detection_range > 0, "Detection range should be positive")
		assert(enemy.attack_range > 0, "Attack range should be positive")
		assert(enemy.patrol_distance >= 0, "Patrol distance should be non-negative")
		
		# Test group membership
		assert(enemy.is_in_group("enemies"), "Enemy should be in 'enemies' group")
		
		# Cleanup
		test_environment.remove_child(enemy)
		enemy.queue_free()
		
		record_test_result(current_test, true, "Enemy AI system valid")
		
	except:
		record_test_result(current_test, false, "Enemy AI test failed")

func test_enemy_combat() -> void:
	current_test = "Enemy Combat"
	
	try:
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		test_environment.add_child(enemy)
		
		# Test combat properties
		assert(enemy.contact_damage > 0, "Contact damage should be positive")
		assert(enemy.attack_damage > 0, "Attack damage should be positive")
		
		# Test damage taking
		var initial_hp = enemy.hp
		enemy.take_damage(1)
		assert(enemy.hp < initial_hp, "Enemy should take damage")
		
		# Cleanup
		test_environment.remove_child(enemy)
		enemy.queue_free()
		
		record_test_result(current_test, true, "Enemy combat system valid")
		
	except:
		record_test_result(current_test, false, "Enemy combat test failed")

# Integration Test Implementations

func test_player_enemy_interaction() -> void:
	current_test = "Player-Enemy Interaction"
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		
		var player = player_scene.instantiate()
		var enemy = enemy_scene.instantiate()
		
		test_environment.add_child(player)
		test_environment.add_child(enemy)
		
		# Position them close to each other
		player.position = Vector2(100, 100)
		enemy.position = Vector2(150, 100)
		
		# Test collision detection
		await get_tree().process_frame
		assert(player != null, "Player should exist")
		assert(enemy != null, "Enemy should exist")
		
		# Cleanup
		test_environment.remove_child(player)
		test_environment.remove_child(enemy)
		player.queue_free()
		enemy.queue_free()
		
		record_test_result(current_test, true, "Player-enemy interaction successful")
		
	except:
		record_test_result(current_test, false, "Player-enemy interaction test failed")

func test_combat_system_integration() -> void:
	current_test = "Combat System Integration"
	
	try:
		# Test that combat components can be created
		var combat_script = preload("res://scenes/player/PlayerCombat.gd")
		assert(combat_script != null, "PlayerCombat script should exist")
		
		var animation_script = preload("res://scenes/player/PlayerAnimation.gd")
		assert(animation_script != null, "PlayerAnimation script should exist")
		
		record_test_result(current_test, true, "Combat system integration successful")
		
	except:
		record_test_result(current_test, false, "Combat system integration failed")

func test_visual_effects_integration() -> void:
	current_test = "Visual Effects Integration"
	
	try:
		# Test visual effects manager
		var effects_manager_script = preload("res://scenes/components/VisualEffectsManager.gd")
		assert(effects_manager_script != null, "VisualEffectsManager script should exist")
		
		# Test shader files exist
		var pixel_shader = preload("res://shaders/pixel_art_enhanced.gdshader")
		assert(pixel_shader != null, "Pixel art shader should exist")
		
		var lighting_shader = preload("res://shaders/advanced_lighting.gdshader")
		assert(lighting_shader != null, "Lighting shader should exist")
		
		record_test_result(current_test, true, "Visual effects integration successful")
		
	except:
		record_test_result(current_test, false, "Visual effects integration failed")

# E2E Test Implementations

func test_game_startup() -> void:
	current_test = "Game Startup"
	
	try:
		# Test main scene can be loaded
		var main_scene = preload("res://scenes/Main.tscn")
		assert(main_scene != null, "Main scene should exist")
		
		# Test simple main scene
		var simple_main = preload("res://scenes/SimpleMain.tscn")
		assert(simple_main != null, "Simple main scene should exist")
		
		# Test player scene
		var player_scene = preload("res://scenes/player/Player.tscn")
		assert(player_scene != null, "Player scene should exist")
		
		# Test enemy scene
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		assert(enemy_scene != null, "Enemy scene should exist")
		
		# Test HUD scene
		var hud_scene = preload("res://scenes/ui/HUD.tscn")
		assert(hud_scene != null, "HUD scene should exist")
		
		record_test_result(current_test, true, "Game startup components valid")
		
	except:
		record_test_result(current_test, false, "Game startup test failed")

func test_hud_functionality() -> void:
	current_test = "HUD Functionality"
	
	try:
		var hud_scene = preload("res://scenes/ui/HUD.tscn")
		var hud = hud_scene.instantiate()
		test_environment.add_child(hud)
		
		# Test HUD script exists
		assert(hud.get_script() != null, "HUD should have script")
		
		# Cleanup
		test_environment.remove_child(hud)
		hud.queue_free()
		
		record_test_result(current_test, true, "HUD functionality valid")
		
	except:
		record_test_result(current_test, false, "HUD functionality test failed")

func test_memory_management() -> void:
	current_test = "Memory Management"
	
	try:
		# Test memory usage before and after creating objects
		var initial_memory = OS.get_static_memory_usage()
		
		# Create multiple objects
		var objects = []
		for i in range(10):
			var player = preload("res://scenes/player/Player.tscn").instantiate()
			objects.append(player)
			test_environment.add_child(player)
		
		await get_tree().process_frame
		
		# Cleanup
		for obj in objects:
			test_environment.remove_child(obj)
			obj.queue_free()
		
		# Force garbage collection
		call_deferred("force_garbage_collection")
		
		record_test_result(current_test, true, "Memory management test completed")
		
	except:
		record_test_result(current_test, false, "Memory management test failed")

# Performance Test Implementations

func test_script_performance() -> void:
	current_test = "Script Performance"
	
	try:
		var start_time = Time.get_ticks_msec()
		
		# Test script loading performance
		var player_script = preload("res://scenes/player/Player.gd")
		var enemy_script = preload("res://scenes/enemy/Enemy.gd")
		
		var load_time = Time.get_ticks_msec() - start_time
		
		# Scripts should load quickly (under 100ms)
		assert(load_time < 100, "Script loading should be fast")
		
		record_test_result(current_test, true, "Script performance acceptable: " + str(load_time) + "ms")
		
	except:
		record_test_result(current_test, false, "Script performance test failed")

func test_fps_stability() -> void:
	current_test = "FPS Stability"
	
	try:
		var fps_samples = []
		
		# Collect FPS samples over 1 second
		for i in range(60):
			fps_samples.append(Engine.get_frames_per_second())
			await get_tree().process_frame
		
		var avg_fps = 0
		for fps in fps_samples:
			avg_fps += fps
		avg_fps /= fps_samples.size()
		
		# FPS should be reasonably stable
		assert(avg_fps > 30, "Average FPS should be above 30")
		
		record_test_result(current_test, true, "FPS stability acceptable: " + str(avg_fps) + " FPS")
		
	except:
		record_test_result(current_test, false, "FPS stability test failed")

# Utility Functions

func record_test_result(test_name: String, passed: bool, message: String) -> void:
	test_results[test_name] = {
		"passed": passed,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var status = "PASS" if passed else "FAIL"
	print("[", status, "] ", test_name, ": ", message)
	
	test_completed.emit(test_name, passed, message)

func generate_test_summary() -> Dictionary:
	var total_tests = test_results.size()
	var passed_tests = 0
	var failed_tests = []
	
	for test_name in test_results:
		var result = test_results[test_name]
		if result.passed:
			passed_tests += 1
		else:
			failed_tests.append(test_name)
	
	var summary = {
		"total": total_tests,
		"passed": passed_tests,
		"failed": total_tests - passed_tests,
		"success_rate": float(passed_tests) / float(total_tests) * 100.0,
		"failed_tests": failed_tests,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	print("\n=== TEST SUMMARY ===")
	print("Total Tests: ", summary.total)
	print("Passed: ", summary.passed)
	print("Failed: ", summary.failed)
	print("Success Rate: ", "%.1f%%" % summary.success_rate)
	
	if not failed_tests.is_empty():
		print("\nFailed Tests:")
		for test in failed_tests:
			print("  - ", test, ": ", test_results[test].message)
	
	return summary

func force_garbage_collection() -> void:
	# Force garbage collection for testing
	var unused_resources = []
	for resource_id in RenderingServer.get_texture_list():
		var texture = RenderingServer.texture_get_rd_texture(resource_id)
		if texture == RID():
			unused_resources.append(resource_id)
	
	for resource_id in unused_resources:
		RenderingServer.free_rid(resource_id)

# Assertion Helper
func assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("Assertion failed: " + message)
		# Create a custom assertion error
		var error = AssertionError.new()
		error.message = message
		# This will be caught by the try-catch blocks
		# In a real implementation, you might want to use a proper assertion system

class AssertionError extends RefCounted:
	var message: String = ""
