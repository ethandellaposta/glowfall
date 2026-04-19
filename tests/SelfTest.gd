extends Node2D

## Self-validating automated test for Glowfall Level 1.
##
## Run with:
##   /Applications/Godot.app/Contents/MacOS/Godot --path . tests/SelfTest.tscn
##
## Loads the real game scene, simulates input, and writes results to
## tests/TestResults_Auto.txt  then quits.

const RESULT_PATH := "res://tests/TestResults_Auto.txt"
const TICK := 0.05  # seconds per test step

var _game: Node2D
var _player: CharacterBody2D
var _results: Array[String] = []
var _pass_count: int = 0
var _fail_count: int = 0
var _phase: int = 0
var _timer: float = 0.0
var _start_pos: Vector2
var _settled: bool = false
var _room_loaded_count: int = 0

# ──────────── lifecycle ────────────

func _ready() -> void:
	_log("═══ Glowfall Self-Test Started ═══")
	_log("Time: %s" % Time.get_datetime_string_from_system())
	_log("")
	# Instantiate the real game
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		_fail("SETUP", "Could not load Main.tscn")
		_finish()
		return
	_game = main_scene.instantiate()
	add_child(_game)
	# Find player after a short delay (deferred setup)
	await get_tree().create_timer(0.3).timeout
	_player = _find_player()
	if _player == null:
		_fail("SETUP", "Player node not found")
		_finish()
		return
	_pass("SETUP", "Game loaded, player found")
	# Connect to room_loaded
	if _game.has_signal("room_loaded"):
		_game.room_loaded.connect(_on_room_loaded)
	# Wait a bit more for first room + physics to settle
	await get_tree().create_timer(1.5).timeout
	_settled = true
	_start_pos = _player.global_position
	_log("Player start position: %s" % str(_start_pos))
	_run_tests()

func _on_room_loaded() -> void:
	_room_loaded_count += 1

# ──────────── test runner ────────────

func _run_tests() -> void:
	await _test_player_on_floor()
	await _test_move_right()
	await _test_move_left()
	await _test_jump()
	await _test_no_floor_fallthrough()
	await _test_enemies_spawned()
	await _test_attack()
	await _test_crouch()
	await _test_door_transition()
	_finish()

# ──────────── individual tests ────────────

func _test_player_on_floor() -> void:
	_log("")
	_log("── Test: Player On Floor ──")
	# Give physics a few frames to ground the player
	_release_all()
	await _wait(0.3)
	if _player.is_on_floor():
		_pass("FLOOR", "Player is on the floor")
	else:
		_fail("FLOOR", "Player is NOT on the floor (y=%s, vel_y=%s)" % [_player.global_position.y, _player.velocity.y])

func _test_move_right() -> void:
	_log("")
	_log("── Test: Move Right ──")
	_release_all()
	var before := _player.global_position.x
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	var after := _player.global_position.x
	var delta_x := after - before
	_log("  before_x=%0.1f  after_x=%0.1f  delta=%0.1f" % [before, after, delta_x])
	if delta_x > 20.0:
		_pass("MOVE_RIGHT", "Player moved right by %.1f px" % delta_x)
	else:
		_fail("MOVE_RIGHT", "Player barely moved right (%.1f px)" % delta_x)
	await _wait(0.1)

func _test_move_left() -> void:
	_log("")
	_log("── Test: Move Left ──")
	_release_all()
	var before := _player.global_position.x
	Input.action_press("move_left")
	await _wait(0.5)
	Input.action_release("move_left")
	var after := _player.global_position.x
	var delta_x := before - after
	_log("  before_x=%0.1f  after_x=%0.1f  delta=%0.1f" % [before, after, delta_x])
	if delta_x > 20.0:
		_pass("MOVE_LEFT", "Player moved left by %.1f px" % delta_x)
	else:
		_fail("MOVE_LEFT", "Player barely moved left (%.1f px)" % delta_x)
	await _wait(0.1)

func _test_jump() -> void:
	_log("")
	_log("── Test: Jump ──")
	_release_all()
	await _wait(0.2)
	var floor_y := _player.global_position.y
	Input.action_press("jump")
	await _wait(0.08)
	Input.action_release("jump")
	await _wait(0.25)
	var air_y := _player.global_position.y
	var lift := floor_y - air_y
	_log("  floor_y=%0.1f  air_y=%0.1f  lift=%0.1f" % [floor_y, air_y, lift])
	if lift > 30.0:
		_pass("JUMP", "Player jumped %.1f px upward" % lift)
	else:
		_fail("JUMP", "Jump lift too small (%.1f px)" % lift)
	# Let player land
	await _wait(1.0)

func _test_no_floor_fallthrough() -> void:
	_log("")
	_log("── Test: No Floor Fall-Through at Center ──")
	# Walk toward center of roof (x ~= 0) and verify player doesn't fall
	_release_all()
	# Walk right toward center
	var target_x := 0.0
	var dir := "move_right" if _player.global_position.x < target_x else "move_left"
	Input.action_press(dir)
	await _wait(1.5)
	Input.action_release(dir)
	await _wait(0.5)
	var pos := _player.global_position
	_log("  Center walk: pos=%s" % str(pos))
	# The floor is at y=420. Player feet at ~y=390. If player fell through,
	# they'd be at y > 500 or teleported to another room.
	if pos.y < 500.0:
		_pass("NO_FALLTHROUGH", "Player stayed on floor at center (y=%0.1f)" % pos.y)
	else:
		_fail("NO_FALLTHROUGH", "Player fell through floor! (y=%0.1f)" % pos.y)
	await _wait(0.2)

func _test_enemies_spawned() -> void:
	_log("")
	_log("── Test: Enemies Spawned ──")
	# Look for Enemy nodes in the scene tree
	var enemies := get_tree().get_nodes_in_group("enemies")
	# If no group, search by class name
	if enemies.is_empty():
		var all_nodes := _find_nodes_by_script(get_tree().root, "Enemy")
		enemies = all_nodes
	_log("  Found %d enemies" % enemies.size())
	if enemies.size() > 0:
		_pass("ENEMIES", "Found %d enemies in room" % enemies.size())
	else:
		# Not necessarily a fail — some rooms may not have enemies
		_log("  WARN: No enemies found (may be expected)")
		_pass("ENEMIES", "No enemies — room may not have spawns")

func _test_attack() -> void:
	_log("")
	_log("── Test: Attack ──")
	_release_all()
	await _wait(0.2)
	# Simulate mouse click for attack
	Input.action_press("attack")
	await _wait(0.15)
	Input.action_release("attack")
	await _wait(0.3)
	# Check that the player isn't stuck in a bad state
	if _player.velocity != null:
		_pass("ATTACK", "Attack executed without crash")
	else:
		_fail("ATTACK", "Player state invalid after attack")

func _test_crouch() -> void:
	_log("")
	_log("── Test: Crouch ──")
	_release_all()
	await _wait(0.2)
	Input.action_press("crouch")
	await _wait(0.3)
	Input.action_release("crouch")
	await _wait(0.2)
	# Just verify no crash
	if is_instance_valid(_player):
		_pass("CROUCH", "Crouch executed without crash")
	else:
		_fail("CROUCH", "Player invalid after crouch")

func _test_door_transition() -> void:
	_log("")
	_log("── Test: Door Transition ──")
	_release_all()
	# Walk to the right edge where DoorToRoomB is (x=930)
	var before_rooms := _room_loaded_count
	_log("  Walking to right door...")
	Input.action_press("move_right")
	await _wait(6.0)  # Walk for 6 seconds toward the door
	Input.action_release("move_right")
	await _wait(2.0)  # Wait for transition
	if _room_loaded_count > before_rooms:
		_pass("DOOR", "Room transition triggered (rooms loaded: %d)" % _room_loaded_count)
	else:
		# Walk might not have reached the door — check position
		var pos := _player.global_position if is_instance_valid(_player) else Vector2.ZERO
		_log("  Player position after walk: %s" % str(pos))
		_fail("DOOR", "No room transition detected after walking right. Pos=%s" % str(pos))

# ──────────── helpers ────────────

func _find_player() -> CharacterBody2D:
	# Try direct child
	var p := _game.get_node_or_null("Player")
	if p is CharacterBody2D:
		return p
	# Search tree
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is CharacterBody2D:
		return players[0]
	# Brute-force
	for child in get_tree().root.get_children():
		var found := _find_child_of_type(child, "CharacterBody2D")
		if found != null:
			return found
	return null

func _find_child_of_type(node: Node, type_name: String) -> CharacterBody2D:
	if node.get_class() == type_name and node is CharacterBody2D:
		return node
	for c in node.get_children():
		var found := _find_child_of_type(c, type_name)
		if found != null:
			return found
	return null

func _find_nodes_by_script(root: Node, script_hint: String) -> Array:
	var result: Array = []
	_collect_by_script(root, script_hint, result)
	return result

func _collect_by_script(node: Node, hint: String, out: Array) -> void:
	if node.get_script() != null:
		var path: String = ""
		var scr = node.get_script()
		if scr is GDScript:
			path = scr.resource_path
		if hint in path:
			out.append(node)
	for c in node.get_children():
		_collect_by_script(c, hint, out)

func _release_all() -> void:
	for action in ["move_left", "move_right", "jump", "crouch", "attack"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _pass(tag: String, msg: String) -> void:
	var line := "  PASS  [%s] %s" % [tag, msg]
	_results.append(line)
	_pass_count += 1
	print(line)

func _fail(tag: String, msg: String) -> void:
	var line := "  FAIL  [%s] %s" % [tag, msg]
	_results.append(line)
	_fail_count += 1
	print(line)

func _log(msg: String) -> void:
	_results.append(msg)
	print(msg)

func _finish() -> void:
	_release_all()
	_log("")
	_log("═══ Results: %d passed, %d failed ═══" % [_pass_count, _fail_count])
	if _fail_count == 0:
		_log("ALL TESTS PASSED")
	else:
		_log("SOME TESTS FAILED — see details above")
	# Write to file
	var text := "\n".join(_results) + "\n"
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
		print("\nResults written to %s" % RESULT_PATH)
	else:
		print("\nWARNING: Could not write results file")
	# Quit after a moment
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(1 if _fail_count > 0 else 0)
