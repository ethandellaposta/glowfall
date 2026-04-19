extends RefCounted
class_name PerformanceMonitor

# Performance monitoring system for automated testing

var fps_history: Array[float] = []
var memory_history: Array[int] = []
var monitoring_active: bool = false
var peak_memory: int = 0
var performance_issues: Array[String] = []

func start_monitoring() -> void:
	monitoring_active = true
	fps_history.clear()
	memory_history.clear()
	peak_memory = 0
	performance_issues.clear()

func stop_monitoring() -> void:
	monitoring_active = false

func update_stats(fps: float, delta: float) -> void:
	if not monitoring_active:
		return
	
	fps_history.append(fps)
	var current_memory = OS.get_static_memory_usage()
	memory_history.append(current_memory)
	
	if current_memory > peak_memory:
		peak_memory = current_memory
	
	# Check for performance issues
	if fps < 30:
		performance_issues.append("Low FPS detected: %.1f" % fps)
	
	if current_memory > 512 * 1024 * 1024:  # 512MB
		performance_issues.append("High memory usage: %d MB" % (current_memory / (1024 * 1024)))

func get_average_fps() -> float:
	if fps_history.is_empty():
		return 0.0
	
	var total = 0.0
	for fps in fps_history:
		total += fps
	
	return total / fps_history.size()

func get_peak_memory() -> int:
	return peak_memory

func get_performance_issues() -> Array[String]:
	return performance_issues
