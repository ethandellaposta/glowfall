extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"

const RoomLoaderScript = preload("res://scenes/components/RoomLoader.gd")
const RoomAtmosphereScript = preload("res://scenes/components/RoomAtmosphere.gd")

@export var default_room_path: String = "res://scenes/rooms/Roof.tscn"
@export var default_spawn: String = "SpawnDefault"
@export var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")

const METSYS_ORIGIN_OFFSET := Vector2(1000.0, 400.0)
const MAIN_SCENE_PATH := "res://scenes/Main.tscn"

@onready var room_root: Node2D = $RoomRoot
@onready var player_node: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $CanvasLayer

var _room_loader: RefCounted
var _pending_room_path: String = ""
var _pending_spawn: String = ""
var _restart_combo_down: bool = false
var _preserve_velocity: Vector2 = Vector2.ZERO

func _should_apply_room_transition_offset() -> bool:
	return _pending_spawn.is_empty()

func _get_assigned_cells_for_scene(scene_path: String) -> Array[Vector3i]:
	var assigned := MetSys.map_data.get_cells_assigned_to(scene_path)
	if not assigned.is_empty():
		return assigned
	var uid := ResourceUID.path_to_uid(scene_path)
	if not uid.is_empty():
		assigned = MetSys.map_data.get_cells_assigned_to(uid)
	return assigned

func _ready() -> void:
	add_to_group("game")
	_room_loader = RoomLoaderScript.new(room_root)
	_room_loader.room_loaded.connect(_on_room_loaded_from_loader)
	Global.load_save()
	room_loaded.connect(_on_room_loaded, CONNECT_DEFERRED)
	set_player(player_node)
	MetSys.reset_state()
	MetSys.set_save_data(Global.metsys_save_data)
	# Room transitions are handled manually via the threaded RoomLoader
	# (the MetSys RoomTransitions module uses synchronous load() which hitches).
	var room_path := Global.current_room_path
	if room_path.is_empty():
		room_path = default_room_path
	var spawn := Global.current_spawn
	if spawn.is_empty():
		spawn = default_spawn
	request_room_change(room_path, spawn)
	_update_hud()

func _process(_delta: float) -> void:
	var combo_down := Input.is_key_pressed(KEY_META) and Input.is_key_pressed(KEY_G) and Input.is_key_pressed(KEY_D)
	if combo_down and not _restart_combo_down:
		_restart_combo_down = true
		_restart_main_scene()
	elif not combo_down:
		_restart_combo_down = false

func _restart_main_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.current_scene != null and tree.current_scene.scene_file_path == MAIN_SCENE_PATH:
		tree.reload_current_scene()
	else:
		tree.change_scene_to_file(MAIN_SCENE_PATH)

func _physics_tick():
	if is_inside_tree() and can_process() and is_instance_valid(player_node):
		MetSys.set_player_position(player_node.position + METSYS_ORIGIN_OFFSET)

func request_room_change(room_path: String, spawn_name: String) -> void:
	_pending_room_path = room_path
	_pending_spawn = spawn_name
	# Always use the threaded loader for smooth, non-blocking transitions.
	_load_room_via_loader(room_path)
	_update_hud()

func show_message(text: String) -> void:
	if hud == null:
		return
	var hud_node := hud.get_node_or_null("HUD")
	if hud_node != null and hud_node.has_method("show_message"):
		hud_node.call("show_message", text)
	if hud_node != null and hud_node.has_method("update_ui"):
		hud_node.call("update_ui")

func _load_room_via_loader(path: String) -> void:
	if _room_loader == null:
		return
	_room_loader.load_room(path)

func _on_room_loaded_from_loader() -> void:
	if _room_loader != null:
		map = _room_loader.current_map
	room_loaded.emit()

func _on_room_loaded() -> void:
	if map == null:
		return
	# Defer heavier setup by a frame to avoid hitching on the transition frame.
	# Room instantiation and player teleport happen right as we cross the ceiling hole;
	# spreading work over frames noticeably reduces a visible stutter.
	call_deferred("_finish_room_loaded_setup")
	return

func _finish_room_loaded_setup() -> void:
	if map == null:
		return
	_add_room_atmosphere(map)
	_spawn_room_enemies(map)
	var spawn_name := _pending_spawn
	if spawn_name.is_empty():
		spawn_name = default_spawn
	var spawn_node := map.get_node_or_null(spawn_name)
	if spawn_node == null and spawn_name != default_spawn:
		spawn_name = default_spawn
		spawn_node = map.get_node_or_null(spawn_name)
	if spawn_node == null:
		var spawn_markers := map.find_children("Spawn*", "Marker2D", true, false)
		if not spawn_markers.is_empty():
			spawn_node = spawn_markers[0]
			spawn_name = (spawn_node as Node).name
	if is_instance_valid(player_node):
		if spawn_node is Node2D:
			player_node.global_position = (spawn_node as Node2D).global_position
		else:
			player_node.global_position = Vector2.ZERO
		if _preserve_velocity == Vector2.ZERO:
			player_node.velocity = Vector2.ZERO
		else:
			player_node.velocity = _preserve_velocity
			_preserve_velocity = Vector2.ZERO
		if player_node.has_method("set_spawn_position"):
			player_node.call("set_spawn_position", player_node.global_position)
	if not _pending_room_path.is_empty():
		Global.current_room_path = _pending_room_path
		Global.current_room_id = -1
		Global.current_spawn = spawn_name
		# Update MetSys map tracking
		var assigned := _get_assigned_cells_for_scene(_pending_room_path)
		if not assigned.is_empty():
			MetSys.visit_cell(assigned[0])
		Global.save()
	_pending_room_path = ""
	_pending_spawn = ""
	_update_hud()

func _add_room_atmosphere(room: Node) -> void:
	if room == null:
		return
	# Don't add twice
	if room.has_node("RoomAtmosphere"):
		return
	var atmo := Node2D.new()
	atmo.set_script(RoomAtmosphereScript)
	atmo.name = "RoomAtmosphere"
	room.add_child(atmo)

func _spawn_room_enemies(room: Node) -> void:
	if room == null:
		return
	if enemy_scene == null:
		return
	var spawns := room.find_children("EnemySpawn*", "Marker2D", true, false)
	for s in spawns:
		if s is Marker2D:
			var e := enemy_scene.instantiate()
			room.add_child(e)
			if e is Node2D:
				(e as Node2D).global_position = (s as Marker2D).global_position

func _update_hud() -> void:
	if hud == null:
		return
	var hud_node := hud.get_node_or_null("HUD")
	if hud_node != null and hud_node.has_method("update_ui"):
		hud_node.call("update_ui")
