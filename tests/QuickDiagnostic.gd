extends Node

# Quick test runner to execute diagnostic tests immediately

func _ready() -> void:
	print("=== RUNNING DIAGNOSTIC TESTS ===")
	
	# Import and run diagnostic test
	var diagnostic_test = preload("res://tests/DiagnosticTest.gd").new()
	add_child(diagnostic_test)
	
	# Wait for tests to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Print results
	print("\n=== DIAGNOSTIC COMPLETE ===")
	print("Check the console output above for results")
	
	# Exit after a short delay
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
