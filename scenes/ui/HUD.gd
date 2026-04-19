extends Control

# --- Node references (built in _ready) ---
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
var _hp_bar_glow: ColorRect
var _hp_label: Label
var _hp_icon: Label

var _soul_bar_bg: ColorRect
var _soul_bar_fill: ColorRect
var _soul_bar_glow: ColorRect
var _soul_label: Label
var _soul_icon: Label

var _room_label: Label
var _ability_label: Label
var _msg_label: Label

var _msg_timer := 0.0
var _pulse_time := 0.0
var _cached_player: CharacterBody2D
var _last_hp := -1
var _last_max_hp := -1
var _last_soul := -1
var _last_max_soul := -1

# Bar dimensions
const BAR_W := 180.0
const BAR_H := 14.0
const BAR_GLOW_H := 4.0
const MARGIN_X := 20.0
const MARGIN_Y := 16.0
const ROW_GAP := 6.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	update_ui()

func _build_hud() -> void:
	# --- Top-left panel background ---
	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.02, 0.02, 0.04, 0.65)
	panel_bg.position = Vector2(MARGIN_X - 6, MARGIN_Y - 6)
	panel_bg.size = Vector2(BAR_W + 80, 130)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_bg)

	# Panel border (thin line)
	var panel_border := ColorRect.new()
	panel_border.color = Color(0.15, 0.8, 0.5, 0.25)
	panel_border.position = Vector2(MARGIN_X - 6, MARGIN_Y - 6)
	panel_border.size = Vector2(BAR_W + 80, 1)
	panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_border)

	var panel_border_b := ColorRect.new()
	panel_border_b.color = Color(0.15, 0.8, 0.5, 0.15)
	panel_border_b.position = Vector2(MARGIN_X - 6, MARGIN_Y + 124)
	panel_border_b.size = Vector2(BAR_W + 80, 1)
	panel_border_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_border_b)

	var panel_border_l := ColorRect.new()
	panel_border_l.color = Color(0.15, 0.8, 0.5, 0.2)
	panel_border_l.position = Vector2(MARGIN_X - 6, MARGIN_Y - 6)
	panel_border_l.size = Vector2(1, 131)
	panel_border_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_border_l)

	var y_cursor := MARGIN_Y

	# === HP ROW ===
	_hp_icon = Label.new()
	_hp_icon.text = "HP"
	_hp_icon.add_theme_font_size_override("font_size", 11)
	_hp_icon.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3, 0.9))
	_hp_icon.position = Vector2(MARGIN_X, y_cursor - 1)
	_hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_icon)

	var bar_x := MARGIN_X + 32.0

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color = Color(0.08, 0.06, 0.06, 0.8)
	_hp_bar_bg.position = Vector2(bar_x, y_cursor)
	_hp_bar_bg.size = Vector2(BAR_W, BAR_H)
	_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.color = Color(0.85, 0.25, 0.2, 0.95)
	_hp_bar_fill.position = Vector2(bar_x, y_cursor)
	_hp_bar_fill.size = Vector2(BAR_W, BAR_H)
	_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_fill)

	_hp_bar_glow = ColorRect.new()
	_hp_bar_glow.color = Color(1.0, 0.5, 0.4, 0.4)
	_hp_bar_glow.position = Vector2(bar_x, y_cursor - BAR_GLOW_H)
	_hp_bar_glow.size = Vector2(BAR_W, BAR_GLOW_H)
	_hp_bar_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_glow)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 11)
	_hp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.9, 0.9))
	_hp_label.position = Vector2(bar_x + BAR_W + 6, y_cursor - 1)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_label)

	y_cursor += BAR_H + ROW_GAP + 4

	# === SOUL ROW ===
	_soul_icon = Label.new()
	_soul_icon.text = "SL"
	_soul_icon.add_theme_font_size_override("font_size", 11)
	_soul_icon.add_theme_color_override("font_color", Color(0.3, 0.7, 0.95, 0.9))
	_soul_icon.position = Vector2(MARGIN_X, y_cursor - 1)
	_soul_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soul_icon)

	_soul_bar_bg = ColorRect.new()
	_soul_bar_bg.color = Color(0.05, 0.06, 0.1, 0.8)
	_soul_bar_bg.position = Vector2(bar_x, y_cursor)
	_soul_bar_bg.size = Vector2(BAR_W, BAR_H)
	_soul_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soul_bar_bg)

	_soul_bar_fill = ColorRect.new()
	_soul_bar_fill.color = Color(0.2, 0.55, 0.95, 0.9)
	_soul_bar_fill.position = Vector2(bar_x, y_cursor)
	_soul_bar_fill.size = Vector2(0, BAR_H)
	_soul_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soul_bar_fill)

	_soul_bar_glow = ColorRect.new()
	_soul_bar_glow.color = Color(0.4, 0.7, 1.0, 0.3)
	_soul_bar_glow.position = Vector2(bar_x, y_cursor - BAR_GLOW_H)
	_soul_bar_glow.size = Vector2(0, BAR_GLOW_H)
	_soul_bar_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soul_bar_glow)

	_soul_label = Label.new()
	_soul_label.add_theme_font_size_override("font_size", 11)
	_soul_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.9))
	_soul_label.position = Vector2(bar_x + BAR_W + 6, y_cursor - 1)
	_soul_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_soul_label)

	y_cursor += BAR_H + ROW_GAP + 6

	# === ABILITIES / ROOM ROW ===
	_ability_label = Label.new()
	_ability_label.add_theme_font_size_override("font_size", 10)
	_ability_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7, 0.7))
	_ability_label.position = Vector2(MARGIN_X, y_cursor)
	_ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ability_label)

	y_cursor += 18

	_room_label = Label.new()
	_room_label.add_theme_font_size_override("font_size", 10)
	_room_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.6))
	_room_label.position = Vector2(MARGIN_X, y_cursor)
	_room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_room_label)

	y_cursor += 20

	# === MESSAGE (centered bottom) ===
	_msg_label = Label.new()
	_msg_label.add_theme_font_size_override("font_size", 14)
	_msg_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.8, 0.95))
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_msg_label.offset_top = -60.0
	_msg_label.offset_bottom = -30.0
	_msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_msg_label)

func _process(delta: float) -> void:
	_pulse_time += delta

	# Animate HP bar glow pulse
	if is_instance_valid(_hp_bar_glow):
		var hp_pulse := 0.3 + sin(_pulse_time * 3.0) * 0.15
		_hp_bar_glow.color.a = hp_pulse

	# Animate soul bar glow pulse
	if is_instance_valid(_soul_bar_glow):
		var soul_pulse := 0.2 + sin(_pulse_time * 2.5 + 1.0) * 0.12
		_soul_bar_glow.color.a = soul_pulse

	# Message timer
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0 and is_instance_valid(_msg_label):
			_msg_label.text = ""

	# Live update bars every frame for smooth response
	_update_bars()

func _update_bars() -> void:
	if not is_instance_valid(_cached_player):
		_cached_player = _get_player()
	var player := _cached_player
	if player == null:
		return

	# HP bar — only update text when values change
	var hp_ratio := 0.0
	if player.max_hp > 0:
		hp_ratio = clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	var hp_w := BAR_W * hp_ratio
	if is_instance_valid(_hp_bar_fill):
		_hp_bar_fill.size.x = lerpf(_hp_bar_fill.size.x, hp_w, 0.15)
		if player.hp != _last_hp:
			if hp_ratio < 0.3:
				_hp_bar_fill.color = Color(0.95, 0.15, 0.1, 0.95)
			elif hp_ratio < 0.6:
				_hp_bar_fill.color = Color(0.9, 0.4, 0.15, 0.95)
			else:
				_hp_bar_fill.color = Color(0.85, 0.25, 0.2, 0.95)
	if is_instance_valid(_hp_bar_glow):
		_hp_bar_glow.size.x = lerpf(_hp_bar_glow.size.x, hp_w, 0.15)
	if player.hp != _last_hp or player.max_hp != _last_max_hp:
		_last_hp = player.hp
		_last_max_hp = player.max_hp
		if is_instance_valid(_hp_label):
			_hp_label.text = "%d/%d" % [player.hp, player.max_hp]

	# Soul bar — only update text when values change
	var soul_ratio := 0.0
	if player.max_soul > 0:
		soul_ratio = clampf(float(player.soul) / float(player.max_soul), 0.0, 1.0)
	var soul_w := BAR_W * soul_ratio
	if is_instance_valid(_soul_bar_fill):
		_soul_bar_fill.size.x = lerpf(_soul_bar_fill.size.x, soul_w, 0.15)
	if is_instance_valid(_soul_bar_glow):
		_soul_bar_glow.size.x = lerpf(_soul_bar_glow.size.x, soul_w, 0.15)
	if player.soul != _last_soul or player.max_soul != _last_max_soul:
		_last_soul = player.soul
		_last_max_soul = player.max_soul
		if is_instance_valid(_soul_label):
			_soul_label.text = "%d/%d" % [player.soul, player.max_soul]

func update_ui() -> void:
	# Room name
	var room_name := ""
	if not Global.current_room_path.is_empty():
		room_name = Global.current_room_path.get_file().get_basename()
	if is_instance_valid(_room_label):
		_room_label.text = room_name

	# Abilities
	var abilities: Array[String] = []
	if Global.has_ability(&"double_jump"):
		abilities.append("DOUBLE JUMP")
	if Global.has_ability(&"dash"):
		abilities.append("DASH")
	if Global.has_ability(&"wall_climb"):
		abilities.append("WALL CLIMB")
	var ability_text := " | ".join(abilities) if not abilities.is_empty() else "NO MODULES"
	if is_instance_valid(_ability_label):
		_ability_label.text = ability_text

	_update_bars()

func show_message(text: String) -> void:
	if is_instance_valid(_msg_label):
		_msg_label.text = text
	_msg_timer = 2.0

func _get_player() -> CharacterBody2D:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return null
	var p = game.get_node_or_null("Player")
	if p is CharacterBody2D:
		return p as CharacterBody2D
	return null
