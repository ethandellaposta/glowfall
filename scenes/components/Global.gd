extends Node

const SM = preload("res://scenes/components/SaveManager.gd")
const CM = preload("res://scenes/components/CharmManager.gd")

var current_room_path: String = ""
var current_room_id: int = -1
var current_spawn: String = ""
var abilities: Dictionary = {}
var metsys_save_data: Dictionary = {}

var charm_slots: int = 3
var charms_unlocked: Dictionary = {}
var charms_equipped: Array[StringName] = []

func has_ability(ability: StringName) -> bool:
	return abilities.has(ability) and abilities[ability] == true

func grant_ability(ability: StringName) -> void:
	abilities[ability] = true
	save()

func get_max_jumps() -> int:
	return 2 if has_ability(&"double_jump") else 1

func has_charm(charm: StringName) -> bool:
	return charms_unlocked.has(charm) and charms_unlocked[charm] == true

func unlock_charm(charm: StringName) -> void:
	charms_unlocked[charm] = true
	save()

func get_charm_cost(charm: StringName) -> int:
	return CM.get_charm_cost(charm)

func get_charm_slots_used() -> int:
	return CM.get_charm_slots_used(charms_equipped)

func get_charm_slots_remaining() -> int:
	return CM.get_charm_slots_remaining(charms_equipped, charm_slots)

func get_equipped_charms() -> Array[StringName]:
	return charms_equipped.duplicate()

func is_charm_equipped(charm: StringName) -> bool:
	return charms_equipped.has(charm)

func equip_charm(charm: StringName) -> bool:
	var result := CM.equip_charm(charm, charms_unlocked, charms_equipped, charm_slots)
	if result:
		save()
	return result

func unequip_charm(charm: StringName) -> void:
	CM.unequip_charm(charm, charms_equipped)
	save()

func save() -> void:
	SM.save(self)

func load_save() -> void:
	SM.load_save(self)
