extends RefCounted

## Manages charm definitions, equipping, unequipping, and slot costs.

const CHARM_DEFS := {
	&"quick_slash": {"cost": 1, "desc": "Faster attacks"},
	&"long_nail": {"cost": 1, "desc": "Longer reach"},
	&"soul_catcher": {"cost": 2, "desc": "Gain more soul"},
	&"sturdy_shell": {"cost": 2, "desc": "Reduce incoming damage"},
}

static func get_charm_cost(charm: StringName) -> int:
	if CHARM_DEFS.has(charm):
		var data: Variant = CHARM_DEFS[charm]
		if typeof(data) == TYPE_DICTIONARY:
			return int((data as Dictionary).get("cost", 1))
	return 1

static func get_charm_slots_used(equipped: Array[StringName]) -> int:
	var used := 0
	for c in equipped:
		used += get_charm_cost(c)
	return used

static func get_charm_slots_remaining(equipped: Array[StringName], max_slots: int) -> int:
	return maxi(0, max_slots - get_charm_slots_used(equipped))

static func equip_charm(charm: StringName, unlocked: Dictionary, equipped: Array[StringName], max_slots: int) -> bool:
	if not unlocked.has(charm) or unlocked[charm] != true:
		return false
	if equipped.has(charm):
		return true
	var cost := get_charm_cost(charm)
	if get_charm_slots_used(equipped) + cost > max_slots:
		return false
	equipped.append(charm)
	return true

static func unequip_charm(charm: StringName, equipped: Array[StringName]) -> void:
	if equipped.has(charm):
		equipped.erase(charm)
