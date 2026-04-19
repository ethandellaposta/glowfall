extends RefCounted

## Handles loading and unloading room scenes within a given root node.

var room_root: Node2D
var current_map: Node2D
var map_changing: bool = false

signal room_loaded

func _init(root: Node2D) -> void:
	room_root = root

func load_room(path: String) -> void:
	if map_changing:
		return
	map_changing = true
	if path.begins_with("uid://"):
		path = ResourceUID.uid_to_path(path)
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
		current_map = null
	# Use threaded loading so the main thread doesn't hitch
	ResourceLoader.load_threaded_request(path)
	var packed: Variant = null
	while true:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(path)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			map_changing = false
			return
		# Yield one frame while the background thread works
		await room_root.get_tree().process_frame
	if packed == null:
		map_changing = false
		return
	current_map = packed.instantiate()
	room_root.add_child(current_map)
	var room_instance := MetSys.get_current_room_instance()
	if room_instance != null:
		MetSys.current_layer = room_instance.get_layer()
	map_changing = false
	room_loaded.emit()
