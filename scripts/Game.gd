extends Node2D

@export var default_room_path: String = "res://scenes/rooms/RoomA.tscn"
@export var default_spawn: String = "SpawnDefault"

const METSYS_ORIGIN_OFFSET := Vector2(1000.0, 400.0)

@onready var room_root: Node2D = $RoomRoot
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $CanvasLayer

func _ready() -> void:
	add_to_group("game")
	Global.load_save()
	MetSys.reset_state()
	MetSys.set_save_data(Global.metsys_save_data)
	var room_path := Global.current_room_path
	if room_path.is_empty():
		room_path = default_room_path
	var spawn := Global.current_spawn
	if spawn.is_empty():
		spawn = default_spawn
	load_room(room_path, spawn)
	if is_instance_valid(player):
		player.get_tree().physics_frame.connect(_on_physics_frame, CONNECT_DEFERRED)
	_update_hud()

func _on_physics_frame() -> void:
	if not is_instance_valid(player):
		return
	var ri := MetSys.get_current_room_instance()
	if ri != null and not ri.cells.is_empty():
		MetSys.set_player_position(player.position + METSYS_ORIGIN_OFFSET)

func request_room_change(room_path: String, spawn_name: String) -> void:
	load_room(room_path, spawn_name)
	_update_hud()

func show_message(text: String) -> void:
	if hud == null:
		return
	var hud_node := hud.get_node_or_null("HUD")
	if hud_node != null and hud_node.has_method("show_message"):
		hud_node.call("show_message", text)

func load_room(room_path: String, spawn_name: String) -> void:
	for c in room_root.get_children():
		c.queue_free()
	var packed: Variant = load(room_path)
	if packed == null:
		return
	var room: Node = packed.instantiate()
	room_root.add_child(room)
	var spawn_node := room.get_node_or_null(spawn_name)
	if not is_instance_valid(player):
		return
	if spawn_node is Node2D:
		player.global_position = spawn_node.global_position
	else:
		player.global_position = Vector2.ZERO
	Global.current_room_path = room_path
	Global.current_spawn = spawn_name
	Global.save()

func _update_hud() -> void:
	if hud == null:
		return
	var hud_node := hud.get_node_or_null("HUD")
	if hud_node != null and hud_node.has_method("update_ui"):
		hud_node.call("update_ui")
