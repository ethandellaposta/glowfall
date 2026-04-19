extends Node
class_name TestRunner

# Automated test runner for Glowfall
# Runs tests and generates detailed reports

@export var auto_run_on_start: bool = false
@export var generate_html_report: bool = true
@export var run_performance_tests: bool = true
@export var run_e2e_tests: bool = true

var test_suite: TestSuite
var current_results: Dictionary
var test_report_path: String = "user://test_report.html"

func _ready() -> void:
	if auto_run_on_start:
		await get_tree().process_frame
		run_tests()

func run_tests() -> void:
	print("=== GLOWFALL TEST RUNNER ===")
	print("Starting comprehensive test suite...")
	
	# Initialize test suite
	test_suite = TestSuite.new()
	add_child(test_suite)
	
	# Connect to test signals
	test_suite.test_completed.connect(_on_test_completed)
	test_suite.suite_completed.connect(_on_suite_completed)
	
	# Run all tests
	current_results = test_suite.run_all_tests()

func _on_test_completed(test_name: String, passed: bool, message: String) -> void:
	# Individual test completed - could update UI here
	pass

func _on_suite_completed(results: Dictionary) -> void:
	current_results = results
	
	# Generate reports
	if generate_html_report:
		generate_html_report()
	
	# Print summary to console
	print_test_summary()
	
	# Exit with appropriate code (for CI/CD)
	var exit_code = 0 if results.failed == 0 else 1
	get_tree().quit(exit_code)

func print_test_summary() -> void:
	print("\n" + "=".repeat(50))
	print("FINAL TEST RESULTS")
	print("=".repeat(50))
	print("Total Tests: ", current_results.total)
	print("Passed: ", current_results.passed)
	print("Failed: ", current_results.failed)
	print("Success Rate: ", "%.1f%%" % current_results.success_rate)
	
	if current_results.failed > 0:
		print("\nFAILED TESTS:")
		for test_name in current_results.failed_tests:
			print("  ❌ ", test_name)
		print("\n⚠️  Some tests failed. Check the detailed report for more information.")
	else:
		print("\n✅ All tests passed!")
	
	print("=".repeat(50))

func generate_html_report() -> void:
	var html_content = generate_html_content()
	var file = FileAccess.open(test_report_path, FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		file.close()
		print("HTML report generated: ", test_report_path)
	else:
		print("Failed to generate HTML report")

func generate_html_content() -> String:
	var html = """
<!DOCTYPE html>
<html>
<head>
    <title>Glowfall Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; border-bottom: 3px solid #007acc; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 18px; }
        .summary-card .number { font-size: 36px; font-weight: bold; }
        .passed { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); }
        .failed { background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); }
        .test-list { margin: 20px 0; }
        .test-item { padding: 10px; margin: 5px 0; border-radius: 4px; border-left: 4px solid #ddd; }
        .test-passed { background-color: #d4edda; border-left-color: #28a745; }
        .test-failed { background-color: #f8d7da; border-left-color: #dc3545; }
        .test-name { font-weight: bold; }
        .test-message { color: #666; font-size: 14px; margin-top: 5px; }
        .timestamp { color: #999; font-size: 12px; }
        .progress-bar { width: 100%; height: 20px; background: #e9ecef; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #28a745, #20c997); transition: width 0.3s ease; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎮 Glowfall Test Report</h1>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Total Tests</h3>
                <div class="number">{total}</div>
            </div>
            <div class="summary-card passed">
                <h3>Passed</h3>
                <div class="number">{passed}</div>
            </div>
            <div class="summary-card failed">
                <h3>Failed</h3>
                <div class="number">{failed}</div>
            </div>
            <div class="summary-card">
                <h3>Success Rate</h3>
                <div class="number">{success_rate:.1f}%</div>
            </div>
        </div>
        
        <div class="progress-bar">
            <div class="progress-fill" style="width: {success_rate}%"></div>
        </div>
        
        <h2>Test Results</h2>
        <div class="test-list">
            {test_results}
        </div>
        
        <div class="timestamp">
            Report generated on: {timestamp}
        </div>
    </div>
</body>
</html>"""
	
	# Replace placeholders
	html = html.format({
		"total": current_results.total,
		"passed": current_results.passed,
		"failed": current_results.failed,
		"success_rate": current_results.success_rate,
		"test_results": generate_test_results_html(),
		"timestamp": Time.get_datetime_string_from_system()
	})
	
	return html

func generate_test_results_html() -> String:
	var html = ""
	
	# This would need access to individual test results
	# For now, generate a summary
	if current_results.failed > 0:
		html += "<div class='test-item test-failed'>"
		html += "<div class='test-name'>❌ Some Tests Failed</div>"
		html += "<div class='test-message'>" + str(current_results.failed) + " tests failed</div>"
		html += "</div>"
	else:
		html += "<div class='test-item test-passed'>"
		html += "<div class='test-name'>✅ All Tests Passed</div>"
		html += "<div class='test-message'>All " + str(current_results.total) + " tests passed successfully</div>"
		html += "</div>"
	
	return html

# Quick test methods for specific debugging
func quick_test_player() -> void:
	print("Running quick player test...")
	
	try:
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		add_child(player)
		
		print("✅ Player scene loaded successfully")
		
		# Test basic properties
		if player.hp > 0:
			print("✅ Player HP valid")
		else:
			print("❌ Player HP invalid")
		
		if player.get_node_or_null("Sprite"):
			print("✅ Player Sprite found")
		else:
			print("❌ Player Sprite not found")
		
		# Cleanup
		remove_child(player)
		player.queue_free()
		
		print("✅ Player test completed")
		
	except:
		print("❌ Player test failed: ", str(get_stack()))

func quick_test_enemy() -> void:
	print("Running quick enemy test...")
	
	try:
		var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		
		print("✅ Enemy scene loaded successfully")
		
		# Test basic properties
		if enemy.hp > 0:
			print("✅ Enemy HP valid")
		else:
			print("❌ Enemy HP invalid")
		
		if enemy.is_in_group("enemies"):
			print("✅ Enemy in correct group")
		else:
			print("❌ Enemy not in enemies group")
		
		# Cleanup
		remove_child(enemy)
		enemy.queue_free()
		
		print("✅ Enemy test completed")
		
	except:
		print("❌ Enemy test failed: ", str(get_stack()))

func quick_test_main_scene() -> void:
	print("Running quick main scene test...")
	
	try:
		var main_scene = preload("res://scenes/Main.tscn")
		print("✅ Main scene can be loaded")
		
		var simple_main = preload("res://scenes/SimpleMain.tscn")
		print("✅ Simple main scene can be loaded")
		
		print("✅ Main scene test completed")
		
	except:
		print("❌ Main scene test failed: ", str(get_stack()))

func debug_loading_issue() -> void:
	print("=== DEBUGGING LOADING ISSUE ===")
	
	# Test individual components
	quick_test_main_scene()
	quick_test_player()
	quick_test_enemy()
	
	# Test autoloads
	print("Testing autoloads...")
	if Engine.has_singleton("Global"):
		print("✅ Global autoload found")
	else:
		print("❌ Global autoload not found")
	
	if Engine.has_singleton("MetSys"):
		print("✅ MetSys autoload found")
	else:
		print("❌ MetSys autoload not found")
	
	# Test project settings
	print("Testing project settings...")
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene")
	print("Main scene path: ", main_scene_path)
	
	var autoloads = ProjectSettings.get_setting("autoload", {})
	print("Autoloads: ", autoloads.keys())
