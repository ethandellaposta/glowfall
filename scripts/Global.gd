extends Node

const SAVE_PATH := "user://save.json"

var current_room_path: String = ""
var current_spawn: String = ""
var abilities: Dictionary = {}
var metsys_save_data: Dictionary = {}

func has_ability(ability: StringName) -> bool:
	return abilities.has(ability) and abilities[ability] == true

func grant_ability(ability: StringName) -> void:
	abilities[ability] = true
	save()

func get_max_jumps() -> int:
	return 2 if has_ability(&"double_jump") else 1

func save() -> void:
	var metsys_data_string := ""
	var metsys_node := get_node_or_null("/root/MetSys")
	if metsys_node != null and metsys_node.save_data != null:
		metsys_data_string = var_to_str(metsys_node.get_save_data())
	var data := {
		"room": current_room_path,
		"spawn": current_spawn,
		"abilities": abilities.keys(),
		"metsys": metsys_data_string,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	current_room_path = str(data.get("room", ""))
	current_spawn = str(data.get("spawn", ""))
	abilities.clear()
	for a in data.get("abilities", []):
		abilities[StringName(str(a))] = true
	var ms_string := str(data.get("metsys", ""))
	if ms_string.is_empty():
		metsys_save_data = {}
		return
	var ms: Variant = str_to_var(ms_string)
	if typeof(ms) == TYPE_DICTIONARY:
		metsys_save_data = ms
	else:
		metsys_save_data = {}
