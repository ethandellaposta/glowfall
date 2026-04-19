extends RefCounted

## Handles saving and loading game state to/from a JSON file.

const SAVE_PATH := "user://save.json"

static func save(global: Node) -> void:
	var metsys_data_string := ""
	var metsys_node := global.get_node_or_null("/root/MetSys")
	if metsys_node != null and metsys_node.save_data != null:
		metsys_data_string = var_to_str(metsys_node.get_save_data())
	var charm_keys: Array = global.charms_unlocked.keys()
	var equipped_keys: Array = []
	for c in global.charms_equipped:
		equipped_keys.append(String(c))
	var data := {
		"room": global.current_room_path,
		"room_id": global.current_room_id,
		"spawn": global.current_spawn,
		"abilities": global.abilities.keys(),
		"charm_slots": global.charm_slots,
		"charms_unlocked": charm_keys,
		"charms_equipped": equipped_keys,
		"metsys": metsys_data_string,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))

static func load_save(global: Node) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	global.current_room_path = str(data.get("room", ""))
	global.current_room_id = int(data.get("room_id", -1))
	if global.current_room_id < 0 and global.current_room_path.is_valid_int():
		global.current_room_id = int(global.current_room_path)
	global.current_spawn = str(data.get("spawn", ""))
	global.abilities.clear()
	for a in data.get("abilities", []):
		global.abilities[StringName(str(a))] = true
	global.charm_slots = int(data.get("charm_slots", global.charm_slots))
	global.charms_unlocked.clear()
	for c in data.get("charms_unlocked", []):
		global.charms_unlocked[StringName(str(c))] = true
	global.charms_equipped.clear()
	for c in data.get("charms_equipped", []):
		var charm_id := StringName(str(c))
		if global.charms_unlocked.has(charm_id):
			global.charms_equipped.append(charm_id)
	var ms_string := str(data.get("metsys", ""))
	if ms_string.is_empty():
		global.metsys_save_data = {}
		return
	var ms: Variant = str_to_var(ms_string)
	if typeof(ms) == TYPE_DICTIONARY:
		global.metsys_save_data = ms
	else:
		global.metsys_save_data = {}
