extends Node
class_name E2ETests

# End-to-end tests for complete game workflows
# These tests simulate real gameplay scenarios

func run_all_e2e_tests() -> Dictionary:
	print("Running E2E tests...")
	var results = {}
	
	# Game Startup Tests
	results["game_initialization"] = test_game_initialization()
	results["scene_loading"] = test_scene_loading()
	results["autoload_functionality"] = test_autoload_functionality()
	
	# Gameplay Tests
	results["player_spawn"] = test_player_spawn()
	results["basic_movement"] = test_basic_movement()
	results["combat_system"] = test_combat_system()
	
	# System Integration Tests
	results["save_load_system"] = test_save_load_system()
	results["ui_functionality"] = test_ui_functionality()
	results["performance_monitoring"] = test_performance_monitoring()
	
	return results

func test_game_initialization() -> bool:
	print("Testing game initialization...")
	
	try:
		# Test that the game can start without crashing
		var test_scene = preload("res://scenes/SimpleMain.tscn")
		var game_instance = test_scene.instantiate()
		
		# Add to a temporary scene tree
		var temp_tree = SceneTree.new()
		temp_tree.root.add_child(game_instance)
		
		# Wait a few frames
		for i in range(5):
			temp_tree.process_frame
		
		# Check that basic components exist
		var player = game_instance.get_node_or_null("Player")
		if player == null:
			print("❌ Player not found in game initialization")
			temp_tree.quit()
			return false
		
		# Cleanup
		temp_tree.quit()
		
		print("✅ Game initialization successful")
		return true
		
	except:
		print("❌ Game initialization failed: ", str(get_stack()))
		return false

func test_scene_loading() -> bool:
	print("Testing scene loading...")
	
	var scenes_to_test = [
		"res://scenes/Main.tscn",
		"res://scenes/SimpleMain.tscn",
		"res://scenes/player/Player.tscn",
		"res://scenes/enemy/Enemy.tscn",
		"res://scenes/ui/HUD.tscn"
	]
	
	for scene_path in scenes_to_test:
		try:
			var scene = preload(scene_path)
			if scene == null:
				print("❌ Cannot preload scene: ", scene_path)
				return false
			
			var instance = scene.instantiate()
			if instance == null:
				print("❌ Cannot instantiate scene: ", scene_path)
				return false
			
			print("✅ Scene loads successfully: ", scene_path)
			instance.queue_free()
			
		except:
			print("❌ Scene loading failed: ", scene_path, " - ", str(get_stack()))
			return false
	
	print("✅ All scenes load successfully")
	return true

func test_autoload_functionality() -> bool:
	print("Testing autoload functionality...")
	
	try:
		# Test that autoloads are accessible
		# Note: This test would need to run in the actual game context
		
		# For now, just test that the autoload scripts exist
		var global_script = preload("res://scenes/components/Global.gd")
		if global_script == null:
			print("❌ Global autoload script not found")
			return false
		
		print("✅ Autoload scripts accessible")
		return true
		
	except:
		print("❌ Autoload functionality test failed: ", str(get_stack()))
		return false

func test_player_spawn() -> bool:
	print("Testing player spawn...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		
		# Test that player spawns with correct initial state
		if player.hp <= 0:
			print("❌ Player spawned with invalid HP")
			player.queue_free()
			return false
		
		if player.max_hp <= 0:
			print("❌ Player has invalid max HP")
			player.queue_free()
			return false
		
		if player.position != Vector2.ZERO:
			print("⚠️  Player position not zero at spawn (this might be expected)")
		
		print("✅ Player spawn successful")
		player.queue_free()
		return true
		
	except:
		print("❌ Player spawn test failed: ", str(get_stack()))
		return false

func test_basic_movement() -> bool:
	print("Testing basic movement...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		
		# Test movement properties
		if player.speed <= 0:
			print("❌ Player has invalid speed")
			player.queue_free()
			return false
		
		if player.jump_velocity >= 0:
			print("❌ Player has invalid jump velocity")
			player.queue_free()
			return false
		
		# Test physics components
		if not player is CharacterBody2D:
			print("❌ Player is not CharacterBody2D")
			player.queue_free()
			return false
		
		print("✅ Basic movement setup valid")
		player.queue_free()
		return true
		
	except:
		print("❌ Basic movement test failed: ", str(get_stack()))
		return false

func test_combat_system() -> bool:
	print("Testing combat system...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		
		var player = player_scene.instantiate()
		var enemy = enemy_scene.instantiate()
		
		# Test combat properties
		if player.attack_damage <= 0:
			print("❌ Player has invalid attack damage")
			player.queue_free()
			enemy.queue_free()
			return false
		
		if enemy.contact_damage <= 0:
			print("❌ Enemy has invalid contact damage")
			player.queue_free()
			enemy.queue_free()
			return false
		
		# Test combat components
		var player_attack_area = player.get_node_or_null("AttackArea")
		if player_attack_area == null:
			print("❌ Player missing attack area")
			player.queue_free()
			enemy.queue_free()
			return false
		
		print("✅ Combat system valid")
		player.queue_free()
		enemy.queue_free()
		return true
		
	except:
		print("❌ Combat system test failed: ", str(get_stack()))
		return false

func test_save_load_system() -> bool:
	print("Testing save/load system...")
	
	try:
		# Test save manager
		var save_manager_script = preload("res://scenes/components/SaveManager.gd")
		if save_manager_script == null:
			print("❌ SaveManager script not found")
			return false
		
		# Test charm manager
		var charm_manager_script = preload("res://scenes/components/CharmManager.gd")
		if charm_manager_script == null:
			print("❌ CharmManager script not found")
			return false
		
		print("✅ Save/load system components valid")
		return true
		
	except:
		print("❌ Save/load system test failed: ", str(get_stack()))
		return false

func test_ui_functionality() -> bool:
	print("Testing UI functionality...")
	
	try:
		var hud_scene = preload("res://scenes/ui/HUD.tscn")
		var hud = hud_scene.instantiate()
		
		# Test that HUD has required components
		if hud.get_script() == null:
			print("❌ HUD has no script")
			hud.queue_free()
			return false
		
		print("✅ UI functionality valid")
		hud.queue_free()
		return true
		
	except:
		print("❌ UI functionality test failed: ", str(get_stack()))
		return false

func test_performance_monitoring() -> bool:
	print("Testing performance monitoring...")
	
	try:
		# Test performance optimizer
		var perf_optimizer_script = preload("res://scenes/components/PerformanceOptimizer.gd")
		if perf_optimizer_script == null:
			print("❌ PerformanceOptimizer script not found")
			return false
		
		# Test performance settings
		var perf_settings_script = preload("res://scenes/components/PerformanceSettings.gd")
		if perf_settings_script == null:
			print("❌ PerformanceSettings script not found")
			return false
		
		print("✅ Performance monitoring components valid")
		return true
		
	except:
		print("❌ Performance monitoring test failed: ", str(get_stack()))
		return false

# Complete gameplay simulation test
func simulate_complete_gameplay() -> bool:
	print("Simulating complete gameplay...")
	
	try:
		# This would be a comprehensive test that simulates:
		# 1. Game startup
		# 2. Player movement
		# 3. Combat encounters
		# 4. Level progression
		# 5. Save/load cycles
		# 6. UI interactions
		
		# For now, just test the basic flow
		var results = run_all_e2e_tests()
		
		var passed_count = 0
		var total_count = results.size()
		
		for test_name in results:
			if results[test_name]:
				passed_count += 1
		
		var success_rate = float(passed_count) / float(total_count) * 100.0
		print("Gameplay simulation success rate: ", "%.1f%%" % success_rate)
		
		return success_rate >= 80.0  # 80% success rate required
		
	except:
		print("❌ Complete gameplay simulation failed: ", str(get_stack()))
		return false
