extends Node
class_name ErrorChecker

# Quick error checker for the automated testing system

func _ready() -> void:
	print("=== CHECKING FOR ERRORS ===")
	check_script_syntax()
	check_file_references()
	check_type_dependencies()

func check_script_syntax() -> void:
	print("\n🔍 Checking script syntax...")

	var scripts_to_check = [
		"res://tests/AutomatedGameTester.gd",
		"res://tests/GameMonitorWindow.gd",
		"res://tests/SpeedControlManager.gd",
		"res://tests/PerformanceMonitor.gd",
		"res://tests/InputSimulator.gd",
		"res://tests/GameAnalyzer.gd"
	]

	for script_path in scripts_to_check:
		try:
			var script = preload(script_path)
			print("✅ ", script_path, " - Syntax OK")
		except:
			print("❌ ", script_path, " - Syntax Error")

func check_file_references() -> void:
	print("\n🔍 Checking file references...")

	var files_to_check = [
		"res://tests/AutomatedGameTestingSuite.tscn",
		"res://tests/AutomatedGameTester.gd",
		"res://tests/GameMonitorWindow.gd",
		"res://tests/SpeedControlManager.gd",
		"res://tests/PerformanceMonitor.gd",
		"res://tests/InputSimulator.gd",
		"res://tests/GameAnalyzer.gd"
	]

	for file_path in files_to_check:
		if FileAccess.file_exists(file_path):
			print("✅ ", file_path, " - File exists")
		else:
			print("❌ ", file_path, " - File missing")

func check_type_dependencies() -> void:
	print("\n🔍 Checking type dependencies...")

	# Check if main scene is set correctly
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	print("Main scene: ", main_scene)

	# Check if all required classes can be loaded
	try:
		var automated_tester = preload("res://tests/AutomatedGameTester.gd")
		print("✅ AutomatedGameTester - Type OK")
	except:
		print("❌ AutomatedGameTester - Type Error")

	try:
		var game_monitor = preload("res://tests/GameMonitorWindow.gd")
		print("✅ GameMonitorWindow - Type OK")
	except:
		print("❌ GameMonitorWindow - Type Error")

	try:
		var speed_control = preload("res://tests/SpeedControlManager.gd")
		print("✅ SpeedControlManager - Type OK")
	except:
		print("❌ SpeedControlManager - Type Error")

	try:
		var perf_monitor = preload("res://tests/PerformanceMonitor.gd")
		print("✅ PerformanceMonitor - Type OK")
	except:
		print("❌ PerformanceMonitor - Type Error")

	try:
		var input_sim = preload("res://tests/InputSimulator.gd")
		print("✅ InputSimulator - Type OK")
	except:
		print("❌ InputSimulator - Type Error")

	try:
		var game_analyzer = preload("res://tests/GameAnalyzer.gd")
		print("✅ GameAnalyzer - Type OK")
	except:
		print("❌ GameAnalyzer - Type Error")
