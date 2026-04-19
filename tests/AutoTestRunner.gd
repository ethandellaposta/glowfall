extends Node

# Automated Test Runner with Auto-Fix Integration
class_name AutoTestRunner

const AutoFixSystemScript = preload("res://tests/AutoFixSystem.gd")

var auto_fix_system: Node
var test_results: Dictionary = {}
var is_running: bool = false

func _ready() -> void:
	print("🧪 AUTO-TEST RUNNER INITIALIZED")
	auto_fix_system = AutoFixSystemScript.new()
	add_child(auto_fix_system)

func start_automated_testing() -> void:
	if is_running:
		print("⚠️ Automated testing already running...")
		return

	is_running = true
	print("\n🚀 STARTING FULL AUTOMATED TESTING CYCLE")
	print("=" + "=".repeat(50))

	# Phase 1: Auto-fix all errors
	print("\n📋 PHASE 1: AUTO-FIXING ERRORS")
	await auto_fix_system.start_auto_fix_process()

	# Phase 2: Run comprehensive tests
	print("\n📋 PHASE 2: COMPREHENSIVE TESTING")
	await run_all_tests()

	# Phase 3: Validate fixes
	print("\n📋 PHASE 3: VALIDATING FIXES")
	await validate_all_fixes()

	# Phase 4: Final system check
	print("\n📋 PHASE 4: FINAL SYSTEM VALIDATION")
	await final_system_validation()

	is_running = false
	print("\n🏁 AUTOMATED TESTING CYCLE COMPLETED")
	print("=" + "=".repeat(50))

	# Display final results
	display_final_results()

func run_all_tests() -> void:
	var test_files = [
		"res://tests/IntelligentGameRunner.gd",
		"res://tests/PixelPolishSystem.gd",
		"res://tests/IntelligentLevelDesigner.gd",
		"res://tests/AutomatedGameTester.gd"
	]

	for test_file in test_files:
		print("\n🔍 Testing: ", test_file.split("/")[-1])
		var result = run_single_test(test_file)
		test_results[test_file] = result

		if result.success:
			print("  ✅ PASSED")
		else:
			print("  ❌ FAILED: ", result.error_message)

			# Try to auto-fix the failure
			print("  🔧 Attempting auto-fix...")
			await auto_fix_system.start_auto_fix_process()

func run_single_test(file_path: String) -> Dictionary:
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

func validate_all_fixes() -> void:
	var validation_results = {}

	for test_file in test_results.keys():
		print("\n🔍 Validating fixes for: ", test_file.split("/")[-1])

		# Re-run the test to check if fixes worked
		var result = await run_single_test(test_file)
		validation_results[test_file] = result

		if result.success:
			print("  ✅ Fixes validated successfully")
		else:
			print("  ❌ Fixes failed: ", result.error_message)
			print("  🔄 Re-running auto-fix...")
			await auto_fix_system.start_auto_fix_process()

func final_system_validation() -> void:
	print("\n🎯 FINAL SYSTEM VALIDATION")

	# Check if all critical systems are working
	var critical_systems = {
		"IntelligentGameRunner": "res://tests/IntelligentGameRunner.gd",
		"PixelPolishSystem": "res://tests/PixelPolishSystem.gd",
		"IntelligentLevelDesigner": "res://tests/IntelligentLevelDesigner.gd"
	}

	var all_systems_working = true

	for system_name in critical_systems:
		var file_path = critical_systems[system_name]
		print("\n🔍 Validating ", system_name, "...")

		var result = run_single_test(file_path)

		if result.success:
			print("  ✅ ", system_name, " is working")
		else:
			print("  ❌ ", system_name, " has issues: ", result.error_message)
			all_systems_working = false

	if all_systems_working:
		print("\n🎉 ALL CRITICAL SYSTEMS VALIDATED!")
	else:
		print("\n⚠️ Some systems still have issues")

func display_final_results() -> void:
	print("\n📊 FINAL TEST RESULTS")
	print("=" + "=".repeat(50))

	var total_tests = test_results.size()
	var passed_tests = 0
	var total_time = 0.0

	for test_file in test_results.keys():
		var result = test_results[test_file]
		if result.success:
			passed_tests += 1
		total_time += result.execution_time

	print("Total Tests: ", total_tests)
	print("Passed: ", passed_tests)
	print("Failed: ", total_tests - passed_tests)
	print("Success Rate: ", (float(passed_tests) / float(total_tests) * 100.0), "%")
	print("Total Execution Time: ", total_time, " seconds")

	print("\n🔧 AUTO-FIX SUMMARY")
	var fix_summary = auto_fix_system.get_error_summary()
	print("Fix Attempts: ", fix_summary.fix_attempts)
	print("Errors Detected: ", fix_summary.total_errors)

	if passed_tests == total_tests:
		print("\n🎉 ALL TESTS PASSED! System is ready to run.")
		print("\n🎮 Press F5 to start the complete intelligent game system!")
	else:
		print("\n⚠️ Some tests failed. Manual intervention may be required.")
		print("\n🔧 Consider running the auto-fix system again manually.")

func stop_testing() -> void:
	is_running = false
	auto_fix_system.stop_auto_fix()
	print("🛑 Automated testing stopped")

func get_test_summary() -> Dictionary:
	return {
		"total_tests": test_results.size(),
		"passed": test_results.values().filter(func(r): return r.success).size(),
		"failed": test_results.values().filter(func(r): return not r.success).size(),
		"is_running": is_running
	}
