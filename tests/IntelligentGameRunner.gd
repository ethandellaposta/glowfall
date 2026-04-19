extends Node
class_name IntelligentGameRunner

# Advanced AI that actually plays the game with strategy
# Uses machine learning-like behavior for optimal gameplay

@export var play_intelligently: bool = true
@export var learn_from_mistakes: bool = true
@export var explore_thoroughly: bool = true
@export var combat_optimization: bool = true

# AI State Management
enum AIState {
	EXPLORING,
	COMBAT,
	PUZZLE_SOLVING,
	ITEM_COLLECTING,
	BOSS_FIGHTING,
	SPEEDRUNNING
}

var current_state: AIState = AIState.EXPLORING
var ai_memory: Dictionary = {}
var learned_patterns: Array[Dictionary] = []
var current_objective: String = "explore_map"
var performance_metrics: Dictionary = {}
var level_flow: Array[Vector2] = []  # Speedrun path data

# Advanced Input System
var input_controller: AdvancedInputController
var pathfinding_system: PathfindingSystem
var combat_analyzer: CombatAnalyzer
var exploration_mapper: ExplorationMapper

func _ready() -> void:
	print("🤖 INTELLIGENT GAME RUNNER INITIALIZED")
	setup_ai_systems()
	start_intelligent_gameplay()

func setup_ai_systems() -> void:
	# Initialize AI components
	input_controller = AdvancedInputController.new()
	add_child(input_controller)

	pathfinding_system = PathfindingSystem.new()
	add_child(pathfinding_system)

	combat_analyzer = CombatAnalyzer.new()
	add_child(combat_analyzer)

	exploration_mapper = ExplorationMapper.new()
	add_child(exploration_mapper)

	print("✅ AI systems initialized")

func start_intelligent_gameplay() -> void:
	print("🎮 Starting intelligent gameplay...")

	# Analyze current game state
	analyze_game_state()

	# Set initial objective
	set_objective("explore_map")

	# Start AI loop
	var ai_timer = Timer.new()
	ai_timer.wait_time = 0.016  # 60 FPS decision making
	ai_timer.timeout.connect(_ai_think)
	add_child(ai_timer)
	ai_timer.start()

func _ai_think() -> void:
	# Main AI thinking loop
	match current_state:
		AIState.EXPLORING:
			execute_exploration_ai()
		AIState.COMBAT:
			execute_combat_ai()
		AIState.PUZZLE_SOLVING:
			execute_puzzle_ai()
		AIState.ITEM_COLLECTING:
			execute_item_collection_ai()
		AIState.BOSS_FIGHTING:
			execute_boss_fight_ai()
		AIState.SPEEDRUNNING:
			execute_speedrun_ai()

func execute_exploration_ai() -> void:
	# Intelligent exploration behavior
	var player = get_player_safe()
	if not player:
		return

	# Map unexplored areas
	var unexplored_areas = exploration_mapper.get_unexplored_areas()

	if unexplored_areas.size() > 0:
		# Navigate to nearest unexplored area
		var target_area = find_nearest_unexplored(unexplored_areas, player.global_position)
		navigate_to_position(target_area)

		# Record exploration patterns
		record_exploration_pattern(player.global_position)
	else:
		# Map fully explored, switch to item collection
		set_objective("collect_items")

# Missing helper functions for exploration AI
func find_nearest_unexplored(unexplored_areas: Array, player_position: Vector2) -> Vector2:
	# Find the nearest unexplored area
	var nearest_area = unexplored_areas[0]
	var min_distance = player_position.distance_to(nearest_area.position)

	for area in unexplored_areas:
		var distance = player_position.distance_to(area.position)
		if distance < min_distance:
			min_distance = distance
			nearest_area = area

	return nearest_area.position

func record_exploration_pattern(position: Vector2) -> void:
	# Record exploration for future optimization
	var exploration_data = {
		"position": position,
		"timestamp": Time.get_unix_time_from_system(),
		"objective": current_objective
	}

	ai_memory["exploration_history"] = ai_memory.get("exploration_history", [])
	ai_memory["exploration_history"].append(exploration_data)

func calculate_optimal_attack_position(player: Node, enemy: Node) -> Vector2:
	# Calculate optimal position for attacking
	var distance = 100.0  # Optimal attack distance
	var angle = (enemy.global_position - player.global_position).angle()

	# Position at optimal distance from enemy
	var target_pos = enemy.global_position - Vector2(cos(angle), sin(angle)) * distance

	return target_pos

func should_attack_now(player: Node, enemy: Node) -> bool:
	# Determine if should attack now
	var distance = player.global_position.distance_to(enemy.global_position)
	var in_range = distance < 150.0  # Attack range

	# Check if enemy is vulnerable
	var is_vulnerable = enemy.get("is_vulnerable") if enemy.has("is_vulnerable") else true

	return in_range and is_vulnerable

func learn_from_combat_result(player: Node, enemy: Node, analysis: Dictionary) -> void:
	# Machine learning-like pattern recognition
	var combat_pattern = {
		"player_position": player.global_position,
		"enemy_position": enemy.global_position,
		"attack_timing": Time.get_unix_time_from_system(),
		"success": enemy.hp <= 0,
		"damage_dealt": analysis.get("damage_dealt") if analysis.has("damage_dealt") else 0,
		"damage_taken": analysis.get("damage_taken") if analysis.has("damage_taken") else 0
	}

	learned_patterns.append(combat_pattern)

	# Optimize future combat based on learned patterns
	optimize_combat_strategy()

func optimize_combat_strategy() -> void:
	# Optimize combat strategy based on learned patterns
	if learned_patterns.size() < 5:
		return  # Need enough data to optimize

	# Analyze successful patterns
	var successful_patterns = []
	for pattern in learned_patterns:
		if pattern.success:
			successful_patterns.append(pattern)

	if successful_patterns.size() > 0:
		# Update strategy based on successful patterns
		update_combat_preferences(successful_patterns)

func update_combat_preferences(successful_patterns: Array) -> void:
	# Update combat preferences based on successful patterns
	var avg_distance = 0.0
	var avg_timing = 0.0

	for pattern in successful_patterns:
		var distance = pattern.player_position.distance_to(pattern.enemy_position)
		avg_distance += distance
		avg_timing += pattern.attack_timing

	avg_distance /= successful_patterns.size()
	avg_timing /= successful_patterns.size()

	# Store optimized preferences
	ai_memory["optimal_attack_distance"] = avg_distance
	ai_memory["optimal_attack_timing"] = avg_timing

func execute_direct_navigation(target_position: Vector2, player: Node) -> void:
	# Direct navigation when no path is available
	var direction = (target_position - player.global_position).normalized()

	# Execute movement
	input_controller.execute_movement(direction)

	# Add jump if needed for obstacles
	if should_jump_for_obstacle(player, direction):
		input_controller.execute_jump()

func should_jump_for_obstacle(player: Node, direction: Vector2) -> bool:
	# Check if should jump for obstacle
	# Simple check - can be enhanced with raycasting
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player.global_position, player.global_position + direction * 50)
	query.collision_mask = 1  # Environment layer

	var result = space_state.intersect_ray(query)
	return result.is_empty() == false

func should_attack_boss(player: Node, boss: Node) -> bool:
	# Determine if should attack boss
	var distance = player.global_position.distance_to(boss.global_position)
	var in_range = distance < 300.0  # Boss attack range

	# Check boss vulnerability window
	var is_vulnerable = boss.get("is_vulnerable") if boss.has("is_vulnerable") else true
	var attack_window = boss.get("attack_window") if boss.has("attack_window") else true

	return in_range and is_vulnerable and attack_window

func calculate_optimal_boss_angle(boss: Node) -> float:
	# Calculate optimal angle for boss engagement
	var player = get_player_safe()
	if not player:
		return 0.0

	# Calculate angle based on boss attack patterns
	var base_angle = (boss.global_position - player.global_position).angle()

	# Adjust angle based on boss attack type
	var attack_type = boss.get("attack_type") if boss.has("attack_type") else "melee"
	match attack_type:
		"melee":
			return base_angle + PI/4  # Side angle for melee
		"ranged":
			return base_angle + PI  # Behind for ranged
		"area":
			return base_angle + PI/2  # Perpendicular for area
		_:
			return base_angle

# Missing boss phase strategies
func execute_boss_phase2_strategy(player: Node, boss: Node) -> void:
	# Phase 2: More aggressive combat with dodging
	var safe_distance = 150.0
	var optimal_angle = calculate_optimal_boss_angle(boss)
	var target_pos = boss.global_position + Vector2(cos(optimal_angle), sin(optimal_angle)) * safe_distance

	navigate_to_position(target_pos)

	# Dodge boss attacks
	if boss.get("is_attacking") if boss.has("is_attacking") else false:
		execute_dodge_maneuver(player, boss)
	elif should_attack_boss(player, boss):
		input_controller.execute_attack(boss.global_position)

func execute_boss_phase3_strategy(player: Node, boss: Node) -> void:
	# Phase 3: Desperate combat with special moves
	var safe_distance = 100.0
	var optimal_angle = calculate_optimal_boss_angle(boss)
	var target_pos = boss.global_position + Vector2(cos(optimal_angle), sin(optimal_angle)) * safe_distance

	navigate_to_position(target_pos)

	# Use special abilities
	if should_use_special_ability(player, boss):
		execute_special_ability(player, boss)
	elif should_attack_boss(player, boss):
		input_controller.execute_attack(boss.global_position)

func execute_boss_enraged_strategy(player: Node, boss: Node) -> void:
	# Enraged phase: Defensive combat with survival focus
	var safe_distance = 250.0
	var optimal_angle = calculate_optimal_boss_angle(boss)
	var target_pos = boss.global_position + Vector2(cos(optimal_angle), sin(optimal_angle)) * safe_distance

	navigate_to_position(target_pos)

	# Focus on survival and counter-attacks
	if boss.get("is_attacking") if boss.has("is_attacking") else false:
		execute_dodge_maneuver(player, boss)
	elif is_safe_to_counter_attack(player, boss):
		input_controller.execute_attack(boss.global_position)

func execute_dodge_maneuver(player: Node, boss: Node) -> void:
	# Execute dodge maneuver
	var dodge_direction = calculate_dodge_direction(player, boss)
	input_controller.execute_movement(dodge_direction)
	input_controller.execute_jump()

func calculate_dodge_direction(player: Node, boss: Node) -> Vector2:
	# Calculate optimal dodge direction
	var attack_direction = (player.global_position - boss.global_position).normalized()

	# Dodge perpendicular to attack
	var dodge_direction = Vector2(-attack_direction.y, attack_direction.x)

	return dodge_direction

func should_use_special_ability(player: Node, boss: Node) -> bool:
	# Determine if should use special ability
	var player_health_percentage = float(player.hp) / float(player.max_hp)
	var boss_health_percentage = float(boss.hp) / float(boss.max_hp)

	# Use special ability when player is low health or boss is low health
	return player_health_percentage < 0.3 or boss_health_percentage < 0.2

func execute_special_ability(player: Node, boss: Node) -> void:
	# Execute special ability
	# This would depend on player's available abilities
	# For now, execute a powerful attack
	input_controller.execute_attack(boss.global_position)

func is_safe_to_counter_attack(player: Node, boss: Node) -> bool:
	# Check if safe to counter attack
	var is_attacking = boss.get("is_attacking") if boss.has("is_attacking") else false
	var attack_cooldown = boss.get("attack_cooldown") if boss.has("attack_cooldown") else 0.0

	return not is_attacking and attack_cooldown <= 0.0

func execute_combat_ai() -> void:
	# Advanced combat AI
	var player = get_player_safe()
	var enemies = get_nodes_in_group_safe("enemies")

	if enemies.size() == 0:
		set_objective("explore_map")
		return

	# Analyze combat situation
	var combat_analysis = combat_analyzer.analyze_situation(player, enemies)

	match combat_analysis.recommended_action:
		"attack":
			execute_optimal_attack(player, enemies, combat_analysis)
		"defend":
			execute_defensive_maneuver(player, enemies, combat_analysis)
		"retreat":
			execute_strategic_retreat(player, enemies, combat_analysis)
		"special":
			execute_special_ability(player, enemies[0] if enemies.size() > 0 else null)

func execute_optimal_attack(player: Node, enemies: Array, analysis: Dictionary) -> void:
	# Execute the most effective attack pattern
	var target = analysis.primary_target

	# Position for optimal attack
	var optimal_position = calculate_optimal_attack_position(player, target)
	navigate_to_position(optimal_position)

	# Time the attack perfectly
	if should_attack_now(player, target):
		input_controller.execute_attack(target.global_position)

		# Learn from combat outcome
		learn_from_combat_result(player, target, analysis)

func execute_puzzle_ai() -> void:
	# Intelligent puzzle-solving behavior
	var player = get_player_safe()
	if not player:
		return

	# Find active puzzles in the area
	var puzzles = find_nearby_puzzles(player.global_position)

	if puzzles.size() == 0:
		set_objective("explore_map")
		return

	# Analyze and solve puzzles
	for puzzle in puzzles:
		if not puzzle.get("completed") if puzzle.has("completed") else false:
			solve_puzzle_intelligently(puzzle, player)

func find_nearby_puzzles(player_position: Vector2) -> Array:
	# Find puzzles within detection range
	var puzzles = []
	var puzzle_nodes = get_nodes_in_group_safe("puzzles")

	for puzzle in puzzle_nodes:
		if puzzle.global_position.distance_to(player_position) < 300:
			puzzles.append(puzzle)

	return puzzles

func solve_puzzle_intelligently(puzzle: Node, player: Node) -> void:
	# Analyze puzzle type and solve accordingly
	var puzzle_type = determine_puzzle_type(puzzle)

	match puzzle_type:
		"switch_puzzle":
			solve_switch_puzzle(puzzle, player)
		"sequence_puzzle":
			solve_sequence_puzzle(puzzle, player)
		"timing_puzzle":
			solve_timing_puzzle(puzzle, player)
		"pattern_puzzle":
			solve_pattern_puzzle(puzzle, player)
		"physics_puzzle":
			solve_physics_puzzle(puzzle, player)

func determine_puzzle_type(puzzle: Node) -> String:
	# Determine puzzle type based on its properties
	if puzzle.has_method("activate_switch"):
		return "switch_puzzle"
	elif puzzle.has_method("check_sequence"):
		return "sequence_puzzle"
	elif puzzle.has_method("check_timing"):
		return "timing_puzzle"
	elif puzzle.has_method("check_pattern"):
		return "pattern_puzzle"
	else:
		return "physics_puzzle"

func solve_switch_puzzle(puzzle: Node, player: Node) -> void:
	# Solve switch-based puzzles
	var switches = get_puzzle_switches(puzzle)
	var solution_order = calculate_switch_solution(switches)

	for i in range(solution_order.size()):
		var switch = solution_order[i]
		navigate_to_position(switch.global_position)
		await get_tree().create_timer(0.5).timeout
		activate_switch(switch)

func solve_sequence_puzzle(puzzle: Node, player: Node) -> void:
	# Solve sequence-based puzzles
	var correct_sequence = analyze_puzzle_sequence(puzzle)

	for element in correct_sequence:
		navigate_to_position(element.global_position)
		await get_tree().create_timer(0.3).timeout
		interact_with_puzzle_element(element)

func solve_timing_puzzle(puzzle: Node, player: Node) -> void:
	# Solve timing-based puzzles
	var timing_pattern = analyze_timing_pattern(puzzle)

	for timing in timing_pattern:
		await get_tree().create_timer(timing.delay).timeout
		execute_timing_action(timing.action, player)

func solve_pattern_puzzle(puzzle: Node, player: Node) -> void:
	# Solve pattern-based puzzles
	var pattern = analyze_puzzle_pattern(puzzle)

	for step in pattern:
		execute_pattern_step(step, player)
		await get_tree().create_timer(step.duration).timeout

func solve_physics_puzzle(puzzle: Node, player: Node) -> void:
	# Solve physics-based puzzles
	var solution = calculate_physics_solution(puzzle)

	execute_physics_solution(solution, player)

func execute_item_collection_ai() -> void:
	# Intelligent item collection behavior
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Find nearby items
	var items = find_nearby_items(player.global_position)

	if items.size() == 0:
		set_objective("explore_map")
		return

	# Collect items with priority
	var target_item = calculate_best_item_to_collect(items, player)
	navigate_to_position(target_item.global_position)

	# Pick up item when close enough
	if player.global_position.distance_to(target_item.global_position) < 50:
		collect_item(target_item)

func execute_boss_fight_ai() -> void:
	# Advanced boss fighting AI
	var player = get_tree().get_first_node_in_group("player")
	var bosses = get_tree().get_nodes_in_group("bosses")

	if bosses.size() == 0:
		set_objective("explore_map")
		return

	# Execute boss-specific combat strategy
	var boss = bosses[0]
	execute_boss_combat_strategy(player, boss)

func execute_speedrun_ai() -> void:
	# Speedrun optimization AI
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Find fastest path to objective
	var speed_path = calculate_optimal_speedrun_path()

	if speed_path.size() > 0:
		# Execute speedrun movement
		execute_speedrun_movement(speed_path, player)
	else:
		# Fall back to exploration
		set_objective("explore_map")

# Helper functions for AI states
func find_nearby_items(player_position: Vector2) -> Array:
	# Find items within collection range
	var items = []
	var item_nodes = get_tree().get_nodes_in_group("items")

	for item in item_nodes:
		if item.global_position.distance_to(player_position) < 200:
			items.append(item)

	return items

func calculate_best_item_to_collect(items: Array, player: Node) -> Node:
	# Calculate which item is best to collect next
	var best_item = items[0]
	var best_score = calculate_item_value(best_item, player)

	for item in items:
		var score = calculate_item_value(item, player)
		if score > best_score:
			best_score = score
			best_item = item

	return best_item

func calculate_item_value(item: Node, player: Node) -> float:
	# Calculate item collection priority
	var distance = player.global_position.distance_to(item.global_position)
	var rarity = item.get("rarity") if item.has("rarity") else 1.0
	var urgency = item.get("urgency") if item.has("urgency") else 1.0

	return (rarity * urgency) / (distance + 1.0)

func collect_item(item: Node) -> void:
	# Collect an item
	if item.has_method("collect"):
		item.collect()
	elif item.has_method("pickup"):
		item.pickup()
	else:
		# Generic collection
		input_controller.execute_interaction(item.global_position)

func execute_boss_combat_strategy(player: Node, boss: Node) -> void:
	# Execute specialized boss combat strategy
	var combat_phase = determine_boss_phase(boss)

	match combat_phase:
		"phase1":
			execute_boss_phase1_strategy(player, boss)
		"phase2":
			execute_boss_phase2_strategy(player, boss)
		"phase3":
			execute_boss_phase3_strategy(player, boss)
		"enraged":
			execute_boss_enraged_strategy(player, boss)

func determine_boss_phase(boss: Node) -> String:
	# Determine current boss phase
	var health_percentage = float(boss.hp) / float(boss.max_hp)

	if health_percentage > 0.66:
		return "phase1"
	elif health_percentage > 0.33:
		return "phase2"
	elif health_percentage > 0.1:
		return "phase3"
	else:
		return "enraged"

func execute_boss_phase1_strategy(player: Node, boss: Node) -> void:
	# Phase 1: Basic combat with positioning
	var safe_distance = 200.0
	var optimal_angle = calculate_optimal_boss_angle(boss)
	var target_pos = boss.global_position + Vector2(cos(optimal_angle), sin(optimal_angle)) * safe_distance

	navigate_to_position(target_pos)

	# Attack when in position
	if should_attack_boss(player, boss):
		input_controller.execute_attack(boss.global_position)

func calculate_optimal_speedrun_path() -> Array:
	# Calculate optimal path for speedrun
	var speed_path = []

	# Use level flow data for optimal path
	if level_flow.size() > 0:
		speed_path = level_flow

	return speed_path

func execute_speedrun_movement(path: Array, player: Node) -> void:
	# Execute optimized speedrun movement
	if path.size() > 0:
		var target = path[0]
		var direction = (target - player.global_position).normalized()

		# Execute speedrun movement with jumps
		input_controller.execute_movement(direction)

		# Add jumps for speed
		if randf() < 0.3:  # 30% chance to jump
			input_controller.execute_jump()

		# Check if reached waypoint
		if player.global_position.distance_to(target) < 30:
			path.remove_at(0)

# Helper functions for puzzle solving
func get_puzzle_switches(puzzle: Node) -> Array:
	# Get all switches for a puzzle
	var switches = []
	for child in puzzle.get_children():
		if child.is_in_group("switches"):
			switches.append(child)
	return switches

func calculate_switch_solution(switches: Array) -> Array:
	# Calculate optimal switch activation order
	var solution = []

	# Sort switches by priority or position
	switches.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	return switches

func activate_switch(switch: Node) -> void:
	# Activate a switch
	if switch.has_method("activate"):
		switch.activate()
	elif switch.has_method("press"):
		switch.press()
	else:
		# Generic interaction
		input_controller.execute_interaction(switch.global_position)

func analyze_puzzle_sequence(puzzle: Node) -> Array:
	# Analyze puzzle to determine correct sequence
	var elements = []

	# Get sequence elements from puzzle
	for child in puzzle.get_children():
		if child.is_in_group("sequence_elements"):
			elements.append(child)

	# Sort by sequence number if available
	elements.sort_custom(func(a, b):
		return a.get("sequence_number") if a.has("sequence_number") else 0 < b.get("sequence_number") if b.has("sequence_number") else 0
	)

	return elements

func interact_with_puzzle_element(element: Node) -> void:
	# Interact with puzzle element
	if element.has_method("interact"):
		element.interact()
	else:
		input_controller.execute_interaction(element.global_position)

func analyze_timing_pattern(puzzle: Node) -> Array:
	# Analyze timing requirements for puzzle
	var pattern = []

	# Get timing data from puzzle
	if puzzle.has_method("get_timing_pattern"):
		pattern = puzzle.get_timing_pattern()
	else:
		# Default timing pattern
		pattern = [
			{"delay": 0.5, "action": "jump"},
			{"delay": 1.0, "action": "attack"},
			{"delay": 0.3, "action": "move"}
		]

	return pattern

func execute_timing_action(action: String, player: Node) -> void:
	# Execute timing-based action
	match action:
		"jump":
			input_controller.execute_jump()
		"attack":
			input_controller.execute_attack(player.global_position)
		"move":
			input_controller.execute_movement(Vector2.RIGHT)
		"wait":
			pass  # Do nothing, just wait

func analyze_puzzle_pattern(puzzle: Node) -> Array:
	# Analyze pattern requirements for puzzle
	var pattern = []

	# Get pattern data from puzzle
	if puzzle.has_method("get_pattern"):
		pattern = puzzle.get_pattern()
	else:
		# Default pattern
		pattern = [
			{"action": "move_right", "duration": 0.5},
			{"action": "jump", "duration": 0.3},
			{"action": "move_left", "duration": 0.5}
		]

	return pattern

func execute_pattern_step(step: Dictionary, player: Node) -> void:
	# Execute a single pattern step
	match step.action:
		"move_right":
			input_controller.execute_movement(Vector2.RIGHT)
		"move_left":
			input_controller.execute_movement(Vector2.LEFT)
		"jump":
			input_controller.execute_jump()
		"attack":
			input_controller.execute_attack(player.global_position)

func calculate_physics_solution(puzzle: Node) -> Dictionary:
	# Calculate solution for physics-based puzzle
	var solution = {
		"approach_angle": 0.0,
		"force_amount": 1.0,
		"timing": 0.0
	}

	# Analyze puzzle physics requirements
	if puzzle.has_method("get_physics_requirements"):
		solution = puzzle.get_physics_requirements()

	return solution

func execute_physics_solution(solution: Dictionary, player: Node) -> void:
	# Execute physics-based solution
	var angle = solution.get("approach_angle") if solution.has("approach_angle") else 0.0
	var force = solution.get("force_amount") if solution.has("force_amount") else 1.0
	var timing = solution.get("timing") if solution.has("timing") else 0.0

	# Position player for optimal physics interaction
	var offset = Vector2(cos(angle), sin(angle)) * 100
	var target_pos = player.global_position + offset
	navigate_to_position(target_pos)

	# Execute physics action
	await get_tree().create_timer(timing).timeout

	if force > 0.5:
		input_controller.execute_attack(target_pos)
	else:
		input_controller.execute_jump()

func navigate_to_position(target_position: Vector2) -> void:
	# Advanced pathfinding navigation
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var path = pathfinding_system.find_path(player.global_position, target_position)

	if path.size() > 0:
		# Execute movement along path
		execute_path_movement(path, player)
	else:
		# No path found, try direct navigation
		execute_direct_navigation(target_position, player)

func execute_path_movement(path: PackedVector2Array, player: Node) -> void:
	# Move along calculated path
	if path.size() > 0:
		var next_point = path[0]
		var direction = (next_point - player.global_position).normalized()

		# Execute movement input
		input_controller.execute_movement(direction)

		# Check if reached next point
		if player.global_position.distance_to(next_point) < 10:
			path.remove_at(0)

func set_objective(new_objective: String) -> void:
	current_objective = new_objective
	print("🎯 New objective: ", new_objective)

	# Update AI state based on objective
	match new_objective:
		"explore_map":
			current_state = AIState.EXPLORING
		"fight_enemies":
			current_state = AIState.COMBAT
		"collect_items":
			current_state = AIState.ITEM_COLLECTING
		"defeat_boss":
			current_state = AIState.BOSS_FIGHTING
		"speedrun":
			current_state = AIState.SPEEDRUNNING

func analyze_game_state() -> void:
	# Comprehensive game state analysis
	var player = get_player_safe()
	var enemies = get_nodes_in_group_safe("enemies")
	var items = get_nodes_in_group_safe("items")

	performance_metrics = {
		"player_health": player.hp if player else 0,
		"enemy_count": enemies.size(),
		"items_collected": items.size(),
		"exploration_percentage": exploration_mapper.get_exploration_percentage() if exploration_mapper else 0.0,
		"combat_efficiency": calculate_combat_efficiency(),
		"movement_optimization": calculate_movement_optimization()
	}

	print("📊 Game state analyzed: ", performance_metrics)

# Helper function for safe get_tree() calls
func get_tree_safe() -> SceneTree:
	var tree = get_tree()
	if tree == null:
		print("⚠️ Not in scene tree yet")
		return null
	return tree

func get_player_safe() -> Node:
	var tree = get_tree_safe()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")

func get_nodes_in_group_safe(group_name: String) -> Array:
	var tree = get_tree_safe()
	if tree == null:
		return []
	return tree.get_nodes_in_group(group_name)

# Missing helper functions for game state analysis
func calculate_combat_efficiency() -> float:
	# Calculate combat efficiency based on learned patterns
	if learned_patterns.size() == 0:
		return 0.0

	var successful_combats = 0
	for pattern in learned_patterns:
		if pattern.get("success") if pattern.has("success") else false:
			successful_combats += 1

	return float(successful_combats) / float(learned_patterns.size())

func calculate_movement_optimization() -> float:
	# Calculate movement optimization based on exploration data
	var exploration_history = ai_memory.get("exploration_history", [])
	if exploration_history.size() == 0:
		return 0.0

	# Calculate efficiency based on redundant movements
	var efficiency = 1.0
	var redundant_moves = 0

	for i in range(1, exploration_history.size()):
		var prev_pos = exploration_history[i-1].position
		var curr_pos = exploration_history[i].position

		# Check if movement is redundant (back and forth)
		if prev_pos.distance_to(curr_pos) < 50:
			redundant_moves += 1

	efficiency -= float(redundant_moves) / float(exploration_history.size())
	return maxf(0.0, efficiency)

# Missing combat strategy functions
func execute_defensive_maneuver(player: Node, enemies: Array, analysis: Dictionary) -> void:
	# Execute defensive combat maneuver
	var retreat_direction = calculate_retreat_direction(player, enemies)
	var retreat_position = player.global_position + retreat_direction * 200

	navigate_to_position(retreat_position)

	# Block or dodge if needed
	if analysis.get("incoming_attack") if analysis.has("incoming_attack") else false:
		execute_dodge_maneuver(player, enemies[0])

func execute_strategic_retreat(player: Node, enemies: Array, analysis: Dictionary) -> void:
	# Execute strategic retreat to safe position
	var safe_position = find_safe_position(player, enemies)
	navigate_to_position(safe_position)

	# Use defensive abilities while retreating
	if should_use_defensive_ability(player):
		execute_defensive_ability(player)

func calculate_retreat_direction(player: Node, enemies: Array) -> Vector2:
	# Calculate optimal retreat direction
	var threat_center = Vector2.ZERO
	for enemy in enemies:
		threat_center += enemy.global_position

	threat_center /= enemies.size()
	var retreat_direction = (player.global_position - threat_center).normalized()
	return retreat_direction

func find_safe_position(player: Node, enemies: Array) -> Vector2:
	# Find safe position away from enemies
	var safe_distance = 300.0
	var threat_center = Vector2.ZERO

	for enemy in enemies:
		threat_center += enemy.global_position
	threat_center /= enemies.size()

	var retreat_direction = (player.global_position - threat_center).normalized()
	return player.global_position + retreat_direction * safe_distance

func should_use_defensive_ability(player: Node) -> bool:
	# Determine if should use defensive ability
	var health_percentage = float(player.hp) / float(player.max_hp)
	return health_percentage < 0.4  # Use defensive ability when low health

func execute_defensive_ability(player: Node) -> void:
	# Execute defensive ability (block, parry, etc.)
	# This would depend on player's available defensive abilities
	# For now, execute a dodge
	input_controller.execute_jump()

# Advanced AI Components
class AdvancedInputController extends Node:
	var input_queue: Array[Dictionary] = []

	func execute_movement(direction: Vector2) -> void:
		# Execute precise movement input
		if direction.x > 0:
			Input.action_press("right")
		elif direction.x < 0:
			Input.action_press("left")

		if direction.y < 0:
			Input.action_press("jump")

	func execute_attack(target_position: Vector2) -> void:
		# Execute attack with timing
		Input.action_press("attack")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("attack")

	func execute_jump() -> void:
		# Execute jump
		Input.action_press("jump")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("jump")

	func execute_interaction(target_position: Vector2) -> void:
		# Execute interaction (use, activate, etc.)
		Input.action_press("interact")
		await get_tree().create_timer(0.1).timeout
		Input.action_release("interact")

class PathfindingSystem extends Node:
	func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
		# Advanced A* pathfinding
		var path = PackedVector2Array()

		# Simple direct path for now (can be enhanced with A*)
		var steps = int(from.distance_to(to) / 50)
		for i in range(steps):
			var t = float(i) / float(steps)
			path.append(from.lerp(to, t))

		return path

class CombatAnalyzer extends Node:
	func analyze_situation(player: Node, enemies: Array) -> Dictionary:
		# Analyze combat situation and recommend action
		var analysis = {
			"recommended_action": "attack",
			"primary_target": null,
			"damage_dealt": 0,
			"damage_taken": 0
		}

		if enemies.size() > 0:
			analysis.primary_target = find_optimal_target(player, enemies)
			analysis.recommended_action = determine_optimal_action(player, enemies)

		return analysis

	func find_optimal_target(player: Node, enemies: Array) -> Node:
		# Find the best target to attack
		var best_target = enemies[0]
		var best_score = calculate_target_score(player, best_target)

		for enemy in enemies:
			var score = calculate_target_score(player, enemy)
			if score > best_score:
				best_score = score
				best_target = enemy

		return best_target

	func calculate_target_score(player: Node, enemy: Node) -> float:
		# Calculate how good a target this enemy is
		var distance = player.global_position.distance_to(enemy.global_position)
		var health_factor = 1.0 - (enemy.hp / enemy.max_hp)
		var threat_factor = enemy.get("damage") or 10

		return health_factor * threat_factor / (distance + 1)

	func determine_optimal_action(player: Node, enemies: Array) -> String:
		# Determine optimal combat action
		var player_health_percentage = float(player.hp) / float(player.max_hp)

		if player_health_percentage < 0.3:
			return "defend"  # Low health, defend
		elif enemies.size() > 3:
			return "retreat"  # Outnumbered, retreat
		elif enemies.size() == 1 and enemies[0].hp < enemies[0].max_hp * 0.5:
			return "special"  # Finish weakened enemy with special
		else:
			return "attack"  # Normal circumstances, attack

class ExplorationMapper extends Node:
	var explored_areas: Array[Rect2] = []
	var total_map_size: Rect2 = Rect2(-1000, -1000, 2000, 2000)

	func get_unexplored_areas() -> Array[Rect2]:
		# Return areas that haven't been explored yet
		var unexplored = []

		# Simple grid-based exploration
		var grid_size = 200
		for x in range(int(total_map_size.position.x), int(total_map_size.end.x), grid_size):
			for y in range(int(total_map_size.position.y), int(total_map_size.end.y), grid_size):
				var area = Rect2(x, y, grid_size, grid_size)
				if not is_area_explored(area):
					unexplored.append(area)

		return unexplored

	func is_area_explored(area: Rect2) -> bool:
		# Check if area has been explored
		for explored in explored_areas:
			if explored.intersects(area):
				return true
		return false

	func get_exploration_percentage() -> float:
		# Calculate how much of the map has been explored
		var explored_area = 0.0
		for area in explored_areas:
			explored_area += area.get_area()

		return (explored_area / total_map_size.get_area()) * 100.0
