extends Area2D

@export var ability: StringName = &"double_jump"

var _glow: Polygon2D
var _inner: Polygon2D

func _ready() -> void:
	if Global.has_ability(ability):
		queue_free()
		return
	if _can_use_metsys_markers():
		if MetSys.register_storable_object_with_marker(self):
			queue_free()
			return
	body_entered.connect(_on_body_entered)
	_setup_visuals()

func _setup_visuals() -> void:
	# Outer pulsing glow
	_glow = Polygon2D.new()
	_glow.z_index = 4
	_glow.color = Color(0.9, 0.3, 0.7, 0.15)
	_glow.polygon = PackedVector2Array([
		Vector2(-22, -22), Vector2(22, -22),
		Vector2(22, 22), Vector2(-22, 22)
	])
	add_child(_glow)

	# Inner bright core
	_inner = Polygon2D.new()
	_inner.z_index = 5
	_inner.color = Color(0.95, 0.35, 0.75, 0.8)
	_inner.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, -4),
		Vector2(8, 8), Vector2(-8, 8),
		Vector2(-10, -4)
	])
	add_child(_inner)

	# Animate with looping tweens instead of _process
	var tw := create_tween().set_loops()
	tw.tween_property(_glow, "modulate:a", 0.6, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_glow, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var tw2 := create_tween().set_loops()
	tw2.tween_property(_inner, "rotation", TAU, 6.0)

func _can_use_metsys_markers() -> bool:
	if MetSys == null:
		return false
	if owner == null:
		return false
	var scene_path := owner.scene_file_path
	if scene_path.is_empty():
		return false
	var assigned := MetSys.map_data.get_cells_assigned_to(scene_path)
	if not assigned.is_empty():
		return true
	var uid := ResourceUID.path_to_uid(scene_path)
	if uid.is_empty():
		return false
	return not MetSys.map_data.get_cells_assigned_to(uid).is_empty()

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	Global.grant_ability(ability)
	if _can_use_metsys_markers():
		MetSys.store_object(self)
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("show_message"):
		game.call("show_message", "Picked up: %s" % String(ability))
	queue_free()
