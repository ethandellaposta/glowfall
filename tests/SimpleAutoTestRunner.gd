extends Node

# Simple Auto-Test Runner without await issues
class_name SimpleAutoTestRunner

func _ready() -> void:
	print("🧪 SIMPLE AUTO-TEST RUNNER INITIALIZED")
	start_automated_testing()

func start_automated_testing() -> void:
	print("\n🚀 STARTING AUTOMATED TESTING CYCLE")
	print("=" + "=".repeat(50))
	
	# Phase 1: Quick error check
	print("\n📋 PHASE 1: QUICK ERROR CHECK")
	var errors = detect_all_errors()
	
	if errors.size() > 0:
		print("🔍 Detected ", errors.size(), " errors:")
		for error in errors:
			print("  - ", error.description)
		print("\n⚠️ Manual fixing required for some errors")
	else:
		print("✅ No errors detected!")
	
	# Phase 2: Test critical systems
	print("\n📋 PHASE 2: TESTING CRITICAL SYSTEMS")
	test_critical_systems()
	
	print("\n🏁 AUTOMATED TESTING COMPLETED")
	print("=" + "=".repeat(50))

func detect_all_errors() -> Array[Dictionary]:
	var all_errors: Array[Dictionary] = []
	
	# Check critical files
	var critical_files = [
		"res://tests/IntelligentGameRunner.gd",
		"res://tests/PixelPolishSystem.gd",
		"res://tests/IntelligentLevelDesigner.gd"
	]
	
	for file_path in critical_files:
		var file_errors = detect_file_errors(file_path)
		all_errors.append_array(file_errors)
	
	return all_errors

func detect_file_errors(file_path: String) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		errors.append({
			"type": "file_access",
			"description": "Cannot access file: " + file_path,
			"file": file_path,
			"line": 0,
			"fixable": false
		})
		return errors
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	
	# Check for common error patterns
	for line_num in range(lines.size()):
		var line = lines[line_num]
		
		# Check for undefined function calls
		if "not found in base class" in line or "not declared in current scope" in line:
			errors.append({
				"type": "undefined_function",
				"description": "Undefined function call",
				"file": file_path,
				"line": line_num + 1,
				"content": line.strip_edges(),
				"fixable": false
			})
		
		# Check for syntax errors
		if "Parser Error" in line or "Expected" in line:
			errors.append({
				"type": "syntax_error",
				"description": "Syntax error detected",
				"file": file_path,
				"line": line_num + 1,
				"content": line.strip_edges(),
				"fixable": false
			})
	
	return errors

func test_critical_systems() -> void:
	var critical_systems = {
		"IntelligentGameRunner": "res://tests/IntelligentGameRunner.gd",
		"PixelPolishSystem": "res://tests/PixelPolishSystem.gd",
		"IntelligentLevelDesigner": "res://tests/IntelligentLevelDesigner.gd"
	}
	
	var all_systems_working = true
	
	for system_name in critical_systems:
		var file_path = critical_systems[system_name]
		print("\n🔍 Testing ", system_name, "...")
		
		var result = test_single_file(file_path)
		
		if result.success:
			print("  ✅ ", system_name, " is working")
		else:
			print("  ❌ ", system_name, " has issues: ", result.error_message)
			all_systems_working = false
	
	if all_systems_working:
		print("\n🎉 ALL CRITICAL SYSTEMS WORKING!")
		print("\n🎮 Press F5 to start the complete intelligent game system!")
	else:
		print("\n⚠️ Some systems have issues that need manual fixing")

func test_single_file(file_path: String) -> Dictionary:
	var result = {
		"success": false,
		"error_message": "",
		"execution_time": 0.0
	}
	
	var start_time = Time.get_unix_time_from_system()
	
	# Try to load and instantiate the script
	var script = load(file_path)
	if script == null:
		result.error_message = "Failed to load script"
		return result
	
	# Try to create instance
	var instance = script.new()
	if instance == null:
		result.error_message = "Failed to create instance"
		return result
	
	# Test basic functionality
	if instance.has_method("_ready"):
		instance._ready()
	
	if instance.has_method("setup_ai_systems"):
		instance.setup_ai_systems()
	
	# Clean up
	if instance.has_method("queue_free"):
		instance.queue_free()
	
	result.success = true
	result.execution_time = Time.get_unix_time_from_system() - start_time
	return result
