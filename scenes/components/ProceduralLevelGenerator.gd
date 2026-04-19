extends Node
class_name ProceduralLevelGenerator

# Advanced procedural generation system for metroidvania-style levels
# Includes room generation, connectivity, enemy placement, and item distribution

@export var room_width: int = 20
@export var room_height: int = 12
@export var grid_size: Vector2i = Vector2i(50, 30)
@export var max_rooms: int = 25
@export var min_rooms: int = 15
@export var room_density: float = 0.6

# Room types
enum RoomType {
	START,
	BASIC,
	ENEMY,
	BOSS,
	ITEM,
	SECRET,
	CONNECTOR,
	CHALLENGE
}

# Generation parameters
@export var enemy_density: float = 0.3
@export var item_density: float = 0.15
@export var treasure_density: float = 0.08
@export var trap_density: float = 0.1

# Connectivity parameters
@export var max_corridor_length: int = 8
@export var min_corridor_length: int = 3
@export var corridor_width: int = 2

# Visual themes
@export var visual_themes: Array[String] = ["industrial", "organic", "tech", "ancient"]
@export var theme_transition_smoothness: float = 0.7

# Performance optimization
@export var generation_chunk_size: int = 5
@export var async_generation: bool = true

# Internal data structures
var _grid: Array[RoomType] = []
var _rooms: Array[RoomData] = []
var _corridors: Array[CorridorData] = []
var _placed_enemies: Array[EnemyData] = []
var _placed_items: Array[ItemData] = []
var _current_theme: String = "industrial"
var _generation_progress: float = 0.0

# Room data structure
class RoomData:
	var position: Vector2i
	var size: Vector2i
	var type: RoomType
	var theme: String
	var connected_rooms: Array[int] = []
	var enemies: Array[EnemyData] = []
	var items: Array[ItemData] = []
	var visited: bool = false
	var difficulty: float = 1.0

class CorridorData:
	var start: Vector2i
	var end: Vector2i
	var width: int
	var rooms: Array[int] = []
	var theme: String

class EnemyData:
	var type: String
	var position: Vector2i
	var level: int
	var patrol_pattern: String
	var difficulty: float

class ItemData:
	var type: String
	var position: Vector2i
	var rarity: float
	var value: int

# Signals
signal generation_started
signal generation_progress(progress: float)
signal generation_completed(level_data: Dictionary)
signal room_generated(room_data: RoomData)

func _ready() -> void:
	_initialize_grid()

func _initialize_grid() -> void:
	_grid.clear()
	_rooms.clear()
	_corridors.clear()
	_placed_enemies.clear()
	_placed_items.clear()
	
	for x in range(grid_size.x):
		var column: Array[RoomType] = []
		for y in range(grid_size.y):
			column.append(RoomType.CONNECTOR)
		_grid.append(column)

# Main generation function
func generate_level() -> Dictionary:
	generation_started.emit()
	
	if async_generation:
		return await _generate_level_async()
	else:
		return _generate_level_sync()

func _generate_level_async() -> Dictionary:
	# Async generation with progress reporting
	await get_tree().process_frame
	
	_place_start_room()
	_generation_progress = 0.1
	generation_progress.emit(_generation_progress)
	
	await get_tree().process_frame
	_generate_main_rooms()
	_generation_progress = 0.4
	generation_progress.emit(_generation_progress)
	
	await get_tree().process_frame
	_connect_rooms()
	_generation_progress = 0.6
	generation_progress.emit(_generation_progress)
	
	await get_tree().process_frame
	_place_enemies_and_items()
	_generation_progress = 0.8
	generation_progress.emit(_generation_progress)
	
	await get_tree().process_frame
	_apply_themes()
	_generation_progress = 1.0
	generation_progress.emit(_generation_progress)
	
	var level_data := _compile_level_data()
	generation_completed.emit(level_data)
	return level_data

func _generate_level_sync() -> Dictionary:
	_place_start_room()
	_generate_main_rooms()
	_connect_rooms()
	_place_enemies_and_items()
	_apply_themes()
	return _compile_level_data()

func _place_start_room() -> void:
	var center := Vector2i(grid_size.x / 2, grid_size.y / 2)
	var start_room := RoomData.new()
	start_room.position = center
	start_room.size = Vector2i(room_width, room_height)
	start_room.type = RoomType.START
	start_room.theme = visual_themes[0]
	start_room.difficulty = 1.0
	
	_rooms.append(start_room)
	_mark_room_on_grid(start_room)

func _generate_main_rooms() -> void:
	var rooms_to_place := randi_range(min_rooms, max_rooms)
	var placed_count := 1  # Start room already placed
	
	while placed_count < rooms_to_place:
		var new_room := _generate_random_room()
		if _can_place_room(new_room):
			_rooms.append(new_room)
			_mark_room_on_grid(new_room)
			placed_count += 1
			
			room_generated.emit(new_room)

func _generate_random_room() -> RoomData:
	var room := RoomData.new()
	
	# Random position
	var max_attempts := 50
	var attempts := 0
	
	while attempts < max_attempts:
		room.position = Vector2i(
			randi_range(2, grid_size.x - room_width - 2),
			randi_range(2, grid_size.y - room_height - 2)
		)
		
		# Random size variation
		room.size = Vector2i(
			room_width + randi_range(-4, 4),
			room_height + randi_range(-2, 2)
		)
		
		# Random type
		var type_roll := randf()
		if type_roll < 0.1:
			room.type = RoomType.BOSS
		elif type_roll < 0.2:
			room.type = RoomType.ITEM
		elif type_roll < 0.3:
			room.type = RoomType.CHALLENGE
		elif type_roll < 0.4:
			room.type = RoomType.SECRET
		else:
			room.type = RoomType.BASIC
		
		# Calculate difficulty based on distance from start
		var start_room := _rooms[0]
		var distance := room.position.distance_to(start_room.position)
		room.difficulty = 1.0 + (distance / 100.0)
		
		attempts += 1
		if _can_place_room(room):
			break
	
	return room

func _can_place_room(room: RoomData) -> bool:
	# Check boundaries
	if room.position.x < 0 or room.position.y < 0:
		return false
	if room.position.x + room.size.x >= grid_size.x or room.position.y + room.size.y >= grid_size.y:
		return false
	
	# Check overlap with existing rooms
	for existing_room in _rooms:
		if _rooms_overlap(room, existing_room):
			return false
	
	return true

func _rooms_overlap(room1: RoomData, room2: RoomData) -> bool:
	var rect1 := Rect2(room1.position, room1.size)
	var rect2 := Rect2(room2.position, room2.size)
	return rect1.intersects(rect2)

func _mark_room_on_grid(room: RoomData) -> void:
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			if x < grid_size.x and y < grid_size.y:
				_grid[x][y] = room.type

func _connect_rooms() -> void:
	# Use minimum spanning tree algorithm for connectivity
	var connected := [0]  # Start with first room
	var unconnected := []
	
	for i in range(1, _rooms.size()):
		unconnected.append(i)
	
	while not unconnected.is_empty():
		var best_connection := _find_best_connection(connected, unconnected)
		if best_connection.room1 != -1:
			_create_corridor(best_connection.room1, best_connection.room2)
			connected.append(best_connection.room2)
			unconnected.erase(best_connection.room2)
		else:
			break

func _find_best_connection(connected: Array[int], unconnected: Array[int]) -> Dictionary:
	var best := {"room1": -1, "room2": -1, "distance": INF}
	
	for conn_room in connected:
		for unconn_room in unconnected:
			var room1 := _rooms[conn_room]
			var room2 := _rooms[unconn_room]
			var dist := _room_distance(room1, room2)
			
			if dist < best.distance:
				best = {"room1": conn_room, "room2": unconn_room, "distance": dist}
	
	return best

func _room_distance(room1: RoomData, room2: RoomData) -> float:
	var center1 := room1.position + room1.size / 2
	var center2 := room2.position + room2.size / 2
	return center1.distance_to(center2)

func _create_corridor(room1_idx: int, room2_idx: int) -> void:
	var room1 := _rooms[room1_idx]
	var room2 := _rooms[room2_idx]
	
	var start_pos := room1.position + room1.size / 2
	var end_pos := room2.position + room2.size / 2
	
	var corridor := CorridorData.new()
	corridor.start = start_pos
	corridor.end = end_pos
	corridor.width = corridor_width
	corridor.rooms = [room1_idx, room2_idx]
	corridor.theme = room1.theme
	
	_corridors.append(corridor)
	
	# Update room connections
	room1.connected_rooms.append(room2_idx)
	room2.connected_rooms.append(room1_idx)
	
	# Mark corridor on grid
	_mark_corridor_on_grid(corridor)

func _mark_corridor_on_grid(corridor: CorridorData) -> void:
	var path := _generate_corridor_path(corridor.start, corridor.end)
	
	for point in path:
		for dx in range(-corridor.width // 2, corridor.width // 2 + 1):
			for dy in range(-corridor.width // 2, corridor.width // 2 + 1):
				var grid_x := point.x + dx
				var grid_y := point.y + dy
				
				if grid_x >= 0 and grid_x < grid_size.x and grid_y >= 0 and grid_y < grid_size.y:
					if _grid[grid_x][grid_y] == RoomType.CONNECTOR:
						_grid[grid_x][grid_y] = RoomType.CONNECTOR

func _generate_corridor_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start
	
	# Simple L-shaped path
	while current.x != end.x:
		current.x += 1 if end.x > current.x else -1
		path.append(current)
	
	while current.y != end.y:
		current.y += 1 if end.y > current.y else -1
		path.append(current)
	
	return path

func _place_enemies_and_items() -> void:
	for room in _rooms:
		if room.type == RoomType.START or room.type == RoomType.BOSS:
			continue
		
		_place_room_enemies(room)
		_place_room_items(room)

func _place_room_enemies(room: RoomData) -> void:
	var enemy_count := int(room.size.x * room.size.y * enemy_density / 100.0)
	enemy_count = max(1, enemy_count)  # At least one enemy in non-start rooms
	
	for i in range(enemy_count):
		var enemy := _generate_enemy(room)
		room.enemies.append(enemy)
		_placed_enemies.append(enemy)

func _generate_enemy(room: RoomData) -> EnemyData:
	var enemy := EnemyData.new()
	
	# Random position within room
	enemy.position = Vector2i(
		room.position.x + randi_range(2, room.size.x - 2),
		room.position.y + randi_range(2, room.size.y - 2)
	)
	
	# Enemy type based on room theme and difficulty
	enemy.type = _select_enemy_type(room.theme, room.difficulty)
	enemy.level = int(room.difficulty)
	enemy.patrol_pattern = _select_patrol_pattern()
	enemy.difficulty = room.difficulty
	
	return enemy

func _select_enemy_type(theme: String, difficulty: float) -> String:
	var enemy_types := []
	
	match theme:
		"industrial":
			enemy_types = ["drone", "turret", "mech", "robot"]
		"organic":
			enemy_types = ["creature", "beast", "parasite", "mutant"]
		"tech":
			enemy_types = ["cyborg", "android", "security", "hacker"]
		"ancient":
			enemy_types = ["guardian", "spirit", "golem", "wraith"]
		_:
			enemy_types = ["basic"]
	
	var difficulty_index := min(int(difficulty) - 1, enemy_types.size() - 1)
	return enemy_types[difficulty_index]

func _select_patrol_pattern() -> String:
	var patterns = ["horizontal", "vertical", "circular", "random", "stationary"]
	return patterns[randi() % patterns.size()]

func _place_room_items(room: RoomData) -> void:
	var item_count := int(room.size.x * room.size.y * item_density / 100.0)
	
	for i in range(item_count):
		var item := _generate_item(room)
		room.items.append(item)
		_placed_items.append(item)

func _generate_item(room: RoomData) -> ItemData:
	var item := ItemData.new()
	
	# Random position within room
	item.position = Vector2i(
		room.position.x + randi_range(1, room.size.x - 1),
		room.position.y + randi_range(1, room.size.y - 1)
	)
	
	# Item type and rarity
	var item_types := ["health", "ammo", "powerup", "key", "treasure"]
	item.type = item_types[randi() % item_types.size()]
	item.rarity = randf()
	item.value = int(item.rarity * 100)
	
	return item

func _apply_themes() -> void:
	for room in _rooms:
		room.theme = _select_theme_for_room(room)
	
	for corridor in _corridors:
		corridor.theme = _blend_themes_for_corridor(corridor)

func _select_theme_for_room(room: RoomData) -> String:
	# Theme based on room type and position
	match room.type:
		RoomType.START:
			return visual_themes[0]
		RoomType.BOSS:
			return visual_themes[visual_themes.size() - 1]
		RoomType.ITEM:
			return visual_themes[randi() % visual_themes.size()]
		_:
			var theme_index := int(room.position.x / float(grid_size.x) * visual_themes.size())
			return visual_themes[clamp(theme_index, 0, visual_themes.size() - 1)]

func _blend_themes_for_corridor(corridor: CorridorData) -> String:
	if corridor.rooms.size() >= 2:
		var room1 := _rooms[corridor.rooms[0]]
		var room2 := _rooms[corridor.rooms[1]]
		return randf() < 0.5 ? room1.theme : room2.theme
	else:
		return visual_themes[0]

func _compile_level_data() -> Dictionary:
	return {
		"grid": _grid,
		"rooms": _rooms,
		"corridors": _corridors,
		"enemies": _placed_enemies,
		"items": _placed_items,
		"grid_size": grid_size,
		"themes": visual_themes,
		"generation_seed": Time.get_unix_time_from_system()
	}

# Utility functions
func get_room_at_position(pos: Vector2i) -> RoomData:
	for room in _rooms:
		var rect := Rect2(room.position, room.size)
		if rect.has_point(pos):
			return room
	return null

func get_neighbors(room_idx: int) -> Array[int]:
	if room_idx < 0 or room_idx >= _rooms.size():
		return []
	return _rooms[room_idx].connected_rooms

func get_path_between_rooms(room1_idx: int, room2_idx: int) -> Array[int:
	# Simple BFS pathfinding
	var queue := [room1_idx]
	var visited := {room1_idx: true}
	var parent := {room1_idx: -1}
	
	while not queue.is_empty():
		var current := queue.pop_front()
		
		if current == room2_idx:
			# Reconstruct path
			var path := []
			var node := room2_idx
			while node != -1:
				path.append(node)
				node = parent[node]
			path.reverse()
			return path
		
		for neighbor in get_neighbors(current):
			if not visited.has(neighbor):
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	
	return []

func save_level_to_file(filepath: String) -> void:
	var level_data := _compile_level_data()
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_var(level_data)
		file.close()

func load_level_from_file(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if file:
		var level_data := file.get_var()
		file.close()
		return level_data
	return {}
