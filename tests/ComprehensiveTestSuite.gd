extends Node
class_name ComprehensiveTestSuite

# Complete testing package - Unit, Integration, E2E, Performance

func _ready() -> void:
	print("=== RUNNING COMPREHENSIVE TEST SUITE ===")
	run_all_tests()

func run_all_tests() -> void:
	var results = {}
	
	# Unit Tests
	print("\n🧪 RUNNING UNIT TESTS...")
	results["unit"] = run_unit_tests()
	
	# Integration Tests
	print("\n🔗 RUNNING INTEGRATION TESTS...")
	results["integration"] = run_integration_tests()
	
	# E2E Tests
	print("\n🎮 RUNNING E2E TESTS...")
	results["e2e"] = run_e2e_tests()
	
	# Performance Tests
	print("\n⚡ RUNNING PERFORMANCE TESTS...")
	results["performance"] = run_performance_tests()
	
	# Generate Report
	generate_comprehensive_report(results)
	
	print("\n✅ ALL TESTS COMPLETED!")

func run_unit_tests() -> Dictionary:
	var unit_tests = preload("res://tests/UnitTests.gd").new()
	return unit_tests.run_all_unit_tests()

func run_integration_tests() -> Dictionary:
	var test_suite = preload("res://tests/TestSuite.gd").new()
	add_child(test_suite)
	var results = test_suite.run_all_tests()
	test_suite.queue_free()
	return results

func run_e2e_tests() -> Dictionary:
	var e2e_tests = preload("res://tests/E2ETests.gd").new()
	return e2e_tests.run_all_e2e_tests()

func run_performance_tests() -> Dictionary:
	var performance_results = {}
	
	# Script loading performance
	var start_time = Time.get_ticks_msec()
	preload("res://scenes/player/Player.gd")
	preload("res://scenes/enemy/Enemy.gd")
	var load_time = Time.get_ticks_msec() - start_time
	performance_results["script_loading"] = load_time < 100
	
	# Memory usage test
	var initial_memory = OS.get_static_memory_usage()
	var player = preload("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	await get_tree().process_frame
	var memory_increase = OS.get_static_memory_usage() - initial_memory
	player.queue_free()
	performance_results["memory_efficient"] = memory_increase < 1000000  # Less than 1MB
	
	return performance_results

func generate_comprehensive_report(results: Dictionary) -> void:
	print("\n" + "="*60)
	print("📊 COMPREHENSIVE TEST REPORT")
	print("="*60)
	
	var total_tests = 0
	var passed_tests = 0
	
	for test_category in results:
		var category_results = results[test_category]
		print("\n📋 ", test_category.to_upper(), " TESTS:")
		
		if test_category == "unit":
			for test_name in category_results:
				total_tests += 1
				if category_results[test_name]:
					passed_tests += 1
					print("  ✅ ", test_name)
				else:
					print("  ❌ ", test_name)
		
		elif test_category == "performance":
			for test_name in category_results:
				total_tests += 1
				if category_results[test_name]:
					passed_tests += 1
					print("  ✅ ", test_name)
				else:
					print("  ❌ ", test_name)
	
	var success_rate = float(passed_tests) / float(total_tests) * 100.0
	print("\n📈 SUMMARY:")
	print("  Total Tests: ", total_tests)
	print("  Passed: ", passed_tests)
	print("  Failed: ", total_tests - passed_tests)
	print("  Success Rate: ", "%.1f%%" % success_rate)
	
	if success_rate >= 90:
		print("🎉 EXCELLENT - Game is ready for deployment!")
	elif success_rate >= 75:
		print("✅ GOOD - Game is mostly ready, minor fixes needed")
	else:
		print("⚠️  NEEDS WORK - Significant issues to address")
	
	print("="*60)
