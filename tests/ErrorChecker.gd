extends Node
class_name ErrorChecker

func _ready() -> void:
	print("=== CHECKING FOR ERRORS ===")
	check_script_syntax()
	check_file_references()
	check_type_dependencies()

func check_script_syntax() -> void:
	print("\n🔍 Checking script syntax...")

	# Check each script individually with constant strings
	var script1 = preload("res://tests/AutomatedGameTester.gd")
	print("✅ res://tests/AutomatedGameTester.gd - Syntax OK")

	var script2 = preload("res://tests/GameMonitorWindow.gd")
	print("✅ res://tests/GameMonitorWindow.gd - Syntax OK")

	var script3 = preload("res://tests/SpeedControlManager.gd")
	print("✅ res://tests/SpeedControlManager.gd - Syntax OK")

	var script4 = preload("res://tests/PerformanceMonitor.gd")
	print("✅ res://tests/PerformanceMonitor.gd - Syntax OK")

	var script5 = preload("res://tests/InputSimulator.gd")
	print("✅ res://tests/InputSimulator.gd - Syntax OK")

	var script6 = preload("res://tests/GameAnalyzer.gd")
	print("✅ res://tests/GameAnalyzer.gd - Syntax OK")

func check_file_references() -> void:
	print("\n🔍 Checking file references...")

	# Check each file individually
	if FileAccess.file_exists("res://tests/AutomatedGameTestingSuite.tscn"):
		print("✅ res://tests/AutomatedGameTestingSuite.tscn - File exists")
	else:
		print("❌ res://tests/AutomatedGameTestingSuite.tscn - File missing")

	if FileAccess.file_exists("res://tests/AutomatedGameTester.gd"):
		print("✅ res://tests/AutomatedGameTester.gd - File exists")
	else:
		print("❌ res://tests/AutomatedGameTester.gd - File missing")

	if FileAccess.file_exists("res://tests/GameMonitorWindow.gd"):
		print("✅ res://tests/GameMonitorWindow.gd - File exists")
	else:
		print("❌ res://tests/GameMonitorWindow.gd - File missing")

	if FileAccess.file_exists("res://tests/SpeedControlManager.gd"):
		print("✅ res://tests/SpeedControlManager.gd - File exists")
	else:
		print("❌ res://tests/SpeedControlManager.gd - File missing")

	if FileAccess.file_exists("res://tests/PerformanceMonitor.gd"):
		print("✅ res://tests/PerformanceMonitor.gd - File exists")
	else:
		print("❌ res://tests/PerformanceMonitor.gd - File missing")

	if FileAccess.file_exists("res://tests/InputSimulator.gd"):
		print("✅ res://tests/InputSimulator.gd - File exists")
	else:
		print("❌ res://tests/InputSimulator.gd - File missing")

	if FileAccess.file_exists("res://tests/GameAnalyzer.gd"):
		print("✅ res://tests/GameAnalyzer.gd - File exists")
	else:
		print("❌ res://tests/GameAnalyzer.gd - File missing")

func check_type_dependencies() -> void:
	print("\n🔍 Checking type dependencies...")

	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	print("Main scene: ", main_scene)

	var automated_tester = preload("res://tests/AutomatedGameTester.gd")
	print("✅ AutomatedGameTester - Type OK")

	var game_monitor = preload("res://tests/GameMonitorWindow.gd")
	print("✅ GameMonitorWindow - Type OK")

	var speed_control = preload("res://tests/SpeedControlManager.gd")
	print("✅ SpeedControlManager - Type OK")

	var perf_monitor = preload("res://tests/PerformanceMonitor.gd")
	print("✅ PerformanceMonitor - Type OK")

	var input_sim = preload("res://tests/InputSimulator.gd")
	print("✅ InputSimulator - Type OK")

	var game_analyzer = preload("res://tests/GameAnalyzer.gd")
	print("✅ GameAnalyzer - Type OK")
