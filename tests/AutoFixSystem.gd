extends Node

# Automated Error Detection and Fixing System
class_name AutoFixSystem

var error_log: Array[Dictionary] = []
var fix_attempts: int = 0
var max_fix_attempts: int = 10
var current_file: String = ""
var is_running: bool = false

func _ready() -> void:
	print("🔧 AUTO-FIX SYSTEM INITIALIZED")
	print("📝 Automatically detecting and fixing errors...")

func start_auto_fix_process() -> void:
	if is_running:
		print("⚠️ Auto-fix already running...")
		return

	is_running = true
	fix_attempts = 0
	print("🚀 Starting automated error detection and fixing...")

	# Run the auto-fix cycle
	await run_auto_fix_cycle()

func run_auto_fix_cycle() -> void:
	while is_running and fix_attempts < max_fix_attempts:
		fix_attempts += 1
		print("\n🔄 Auto-Fix Cycle #", fix_attempts)

		# Step 1: Check for errors
		var errors = await detect_all_errors()

		if errors.size() == 0:
			print("✅ No errors detected! System is clean.")
			is_running = false
			return

		print("🔍 Detected ", errors.size(), " errors:")
		for error in errors:
			print("  - ", error.type, ": ", error.description)

		# Step 2: Fix errors automatically
		var fixes_applied = await auto_fix_errors(errors)

		print("🔧 Applied ", fixes_applied, " automatic fixes")

		# Step 3: Wait a moment before next cycle
		await get_tree().create_timer(1.0).timeout

	if fix_attempts >= max_fix_attempts:
		print("⚠️ Max fix attempts reached. Some errors may require manual intervention.")

	is_running = false
	print("🏁 Auto-fix process completed")

func detect_all_errors() -> Array[Dictionary]:
	var all_errors: Array[Dictionary] = []

	# Check all GD files in tests directory
	var test_files = get_all_gd_files("res://tests/")

	for file_path in test_files:
		var file_errors = await detect_file_errors(file_path)
		all_errors.append_array(file_errors)

	# Check main game files
	var game_files = get_all_gd_files("res://scenes/")
	for file_path in game_files:
		var file_errors = await detect_file_errors(file_path)
		all_errors.append_array(file_errors)

	# Check AutoFixSystem and AutoTestRunner specifically
	var auto_files = ["res://tests/AutoFixSystem.gd", "res://tests/AutoTestRunner.gd"]
	for file_path in auto_files:
		var file_errors = await detect_file_errors(file_path)
		all_errors.append_array(file_errors)

	return all_errors

func detect_file_errors(file_path: String) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	current_file = file_path

	# Try to load and parse the file
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
		var line_errors = await analyze_line_for_errors(line, line_num + 1, file_path)
		errors.append_array(line_errors)

	return errors

func analyze_line_for_errors(line: String, line_num: int, file_path: String) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []

	# Check for undefined function calls
	if "not found in base class" in line or "not declared in current scope" in line:
		errors.append({
			"type": "undefined_function",
			"description": "Undefined function call",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	# Check for invalid string methods (Python-style vs GDScript)
	if ".endswith(" in line or ".beginswith(" in line:
		errors.append({
			"type": "invalid_string_method",
			"description": "Invalid string method (use ends_with/begins_with instead of endswith/beginswith)",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	# Check for syntax errors
	if "Parser Error" in line or "Expected" in line:
		errors.append({
			"type": "syntax_error",
			"description": "Syntax error detected",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	# Check for invalid try-catch syntax (GDScript doesn't have try-except)
	if line.strip_edges().begins_with("try:") or line.strip_edges().begins_with("except:"):
		errors.append({
			"type": "invalid_try_catch",
			"description": "Invalid try-catch syntax (GDScript doesn't support try-except)",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	# Check for duplicate function names
	if line.begins_with("func ") and line.count("(") > 0:
		var func_name = line.split("(")[0].replace("func ", "").strip_edges()
		if await is_duplicate_function(func_name, file_path):
			errors.append({
				"type": "duplicate_function",
				"description": "Duplicate function: " + func_name,
				"file": file_path,
				"line": line_num,
				"content": line.strip_edges(),
				"fixable": true
			})

	# Check for missing variables
	if "identifier" in line and "not declared" in line:
		errors.append({
			"type": "missing_variable",
			"description": "Undeclared variable",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	# Check for invalid method calls
	if "not found in base" in line and "Color" in line:
		errors.append({
			"type": "invalid_method",
			"description": "Invalid method call on Color",
			"file": file_path,
			"line": line_num,
			"content": line.strip_edges(),
			"fixable": true
		})

	return errors

func auto_fix_errors(errors: Array[Dictionary]) -> int:
	var fixes_applied = 0

	for error in errors:
		if not error.fixable:
			print("  ⚠️ Cannot auto-fix: ", error.description)
			continue

		var success = await apply_auto_fix(error)
		if success:
			fixes_applied += 1
			print("  ✅ Fixed: ", error.description)
		else:
			print("  ❌ Failed to fix: ", error.description)

	return fixes_applied

func apply_auto_fix(error: Dictionary) -> bool:
	match error.type:
		"undefined_function":
			return await fix_undefined_function(error)
		"duplicate_function":
			return await fix_duplicate_function(error)
		"missing_variable":
			return await fix_missing_variable(error)
		"invalid_method":
			return await fix_invalid_method(error)
		"syntax_error":
			return await fix_syntax_error(error)
		"invalid_try_catch":
			return await fix_invalid_try_catch(error)
		"invalid_string_method":
			return await fix_invalid_string_method(error)
		_:
			return false

func fix_invalid_try_catch(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")
	var new_lines: Array[String] = []
	var i = 0

	while i < lines.size():
		var line = lines[i]

		# Remove try: and except: blocks
		if line.strip_edges().begins_with("try:"):
			# Skip the try: line and continue with the content
			i += 1
			continue
		elif line.strip_edges().begins_with("except:"):
			# Skip the except: line
			i += 1
			continue
		else:
			new_lines.append(line)
			i += 1

	# Write back to file
	var updated_content = "\n".join(new_lines)
	return write_file_content(error.file, updated_content)

func fix_invalid_string_method(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")

	# Fix Python-style string methods to GDScript style
	for i in range(lines.size()):
		var line = lines[i]
		line = line.replace(".endswith(", ".ends_with(")
		line = line.replace(".beginswith(", ".begins_with(")
		lines[i] = line

	# Write back to file
	var updated_content = "\n".join(lines)
	return write_file_content(error.file, updated_content)

func fix_undefined_function(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")
	var func_name = extract_function_name_from_error(error.content)

	# Generate appropriate function based on name patterns
	var function_code = generate_function_code(func_name)

	if function_code.is_empty():
		return false

	# Add the function to the end of the file
	lines.append(function_code)

	# Write back to file
	var updated_content = "\n".join(lines)
	return write_file_content(error.file, updated_content)

func fix_duplicate_function(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")
	var func_name = extract_function_name_from_error(error.content)

	# Remove the duplicate function (keep the first occurrence)
	var found_first = false
	var new_lines: Array[String] = []

	for line in lines:
		if line.begins_with("func ") and func_name in line:
			if not found_first:
				new_lines.append(line)
				found_first = true
			# Skip duplicate
		else:
			new_lines.append(line)

	# Write back to file
	var updated_content = "\n".join(new_lines)
	return write_file_content(error.file, updated_content)

func fix_missing_variable(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")
	var var_name = extract_variable_name_from_error(error.content)

	# Find class variable section and add the variable
	for i in range(lines.size()):
		if lines[i].begins_with("var ") and i < 10:  # Near the top
			lines.insert(i + 1, "var " + var_name + ": # Auto-added variable")
			break

	# Write back to file
	var updated_content = "\n".join(lines)
	return write_file_content(error.file, updated_content)

func fix_invalid_method(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")

	# Fix common Color method issues
	for i in range(lines.size()):
		if "distance_to" in lines[i] and "Color" in lines[i]:
			# Replace with manual Euclidean distance calculation
			var fixed_line = fix_color_distance_calculation(lines[i])
			lines[i] = fixed_line

	# Write back to file
	var updated_content = "\n".join(lines)
	return write_file_content(error.file, updated_content)

func fix_syntax_error(error: Dictionary) -> bool:
	var content = get_file_content(error.file)
	if content.is_empty():
		return false

	var lines = content.split("\n")

	# Fix common syntax issues
	for i in range(lines.size()):
		var line = lines[i]

		# Fix .get() syntax issues
		if ".get(" in line and line.count(",") > 1:
			lines[i] = fix_get_syntax(line)

		# Fix missing semicolons or colons
		if line.strip_edges().ends_with("func") and not line.strip_edges().ends_with(":"):
			lines[i] = line + ":"

	# Write back to file
	var updated_content = "\n".join(lines)
	return write_file_content(error.file, updated_content)

# Helper functions
func get_all_gd_files(directory: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(directory)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".gd"):
				files.append(directory.path_join(file_name))
			elif dir.current_is_dir():
				var sub_files = get_all_gd_files(directory.path_join(file_name))
				files.append_array(sub_files)

			file_name = dir.get_next()

	return files

func get_file_content(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""

	var content = file.get_as_text()
	file.close()
	return content

func write_file_content(file_path: String, content: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(content)
	file.close()
	return true

func extract_function_name_from_error(error_line: String) -> String:
	# Extract function name from error message
	var parts = error_line.split(" ")
	for part in parts:
		if not part in ["not", "found", "in", "base", "class", "scope"]:
			return part.replace(":", "")
	return ""

func extract_variable_name_from_error(error_line: String) -> String:
	# Extract variable name from error message
	var parts = error_line.split(" ")
	for part in parts:
		if "identifier" in part:
			return part.replace("identifier", "").strip_edges()
	return "auto_variable"

func generate_function_code(func_name: String) -> String:
	# Generate appropriate function code based on name patterns
	if "calculate" in func_name:
		return """
func %s() -> float:
	# Auto-generated calculation function
	return 0.0""" % func_name

	elif "get" in func_name:
		return """
func %s() -> Array:
	# Auto-generated getter function
	return []""" % func_name

	elif "is" in func_name:
		return """
func %s() -> bool:
	# Auto-generated check function
	return false""" % func_name

	elif "apply" in func_name or "execute" in func_name:
		return """
func %s() -> void:
	# Auto-generated action function
	pass""" % func_name

	else:
		return """
func %s() -> void:
	# Auto-generated function
	pass""" % func_name

func fix_color_distance_calculation(line: String) -> String:
	# Replace Color.distance_to() with manual calculation
	var fixed_line = line
	if "distance_to" in fixed_line:
		fixed_line = line.replace("pixel.distance_to(neighbor)", "sqrt(pow(pixel.r - neighbor.r, 2) + pow(pixel.g - neighbor.g, 2) + pow(pixel.b - neighbor.b, 2))")
	return fixed_line

func fix_get_syntax(line: String) -> String:
	# Fix .get() syntax with default values
	var fixed_line = line

	# Replace .get(key, default) with proper syntax
	var regex = RegEx.new()
	regex.compile(r"(.+)\.get\(([^,]+),\s*([^)]+)\)")
	var result = regex.search(fixed_line)

	if result:
		var obj = result.get_string(1)
		var key = result.get_string(2)
		var default = result.get_string(3)
		fixed_line = obj + ".get(" + key + ") if " + obj + ".has(" + key + ") else " + default

	return fixed_line

func is_duplicate_function(func_name: String, file_path: String) -> bool:
	var content = get_file_content(file_path)
	var count = 0

	for line in content.split("\n"):
		if line.begins_with("func ") and func_name in line:
			count += 1
			if count > 1:
				return true

	return false

func stop_auto_fix() -> void:
	is_running = false
	print("🛑 Auto-fix system stopped")

func get_error_summary() -> Dictionary:
	return {
		"total_errors": error_log.size(),
		"fix_attempts": fix_attempts,
		"is_running": is_running,
		"current_file": current_file
	}
