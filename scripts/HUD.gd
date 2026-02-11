extends Control

@onready var info_label: Label = $Margin/Info
@onready var msg_label: Label = $Margin/Message

var _msg_timer := 0.0

func _process(delta: float) -> void:
	if _msg_timer <= 0.0:
		return
	_msg_timer -= delta
	if _msg_timer <= 0.0:
		msg_label.text = ""

func update_ui() -> void:
	var room := Global.current_room_path.get_file()
	var dj := "yes" if Global.has_ability(&"double_jump") else "no"
	info_label.text = "Room: %s | Double Jump: %s" % [room, dj]

func show_message(text: String) -> void:
	msg_label.text = text
	_msg_timer = 1.75
