extends RefCounted
class_name InputSimulator

# Input simulation system for automated gameplay

var simulation_active: bool = false
var input_queue: Array[Dictionary] = []

func start_simulation() -> void:
	simulation_active = true
	print("🎮 Input simulation started")

func stop_simulation() -> void:
	simulation_active = false
	input_queue.clear()
	print("🛑 Input simulation stopped")

func simulate_movement(direction: String, pressed: bool) -> void:
	if not simulation_active:
		return
	
	var key_code = KEY_D if direction == "right" else KEY_A
	Input.action_press(direction) if pressed else Input.action_release(direction)

func simulate_jump() -> void:
	if not simulation_active:
		return
	
	Input.action_press("jump")
	await Engine.get_main_loop().process_frame
	Input.action_release("jump")

func simulate_attack() -> void:
	if not simulation_active:
		return
	
	Input.action_press("attack")
	await Engine.get_main_loop().process_frame
	Input.action_release("attack")
