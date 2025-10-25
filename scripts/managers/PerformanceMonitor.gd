extends Node
## PerformanceMonitor singleton for monitoring game performance
## Tracks FPS, memory usage, and triggers optimizations

signal performance_warning(metric: String, value: float)
signal optimization_triggered(reason: String)

# Performance thresholds
var target_fps: float = 60.0
var min_fps_threshold: float = 50.0
var max_cpu_usage: float = 70.0
var max_memory_mb: float = 400.0

# Monitoring variables
var fps_samples: Array[float] = []
var memory_samples: Array[float] = []
var cpu_samples: Array[float] = []
var sample_size: int = 60  # 1 second of samples at 60fps

# Performance stats
var current_fps: float = 60.0
var average_fps: float = 60.0
var current_memory_mb: float = 0.0
var current_cpu_usage: float = 0.0
var frame_time_ms: float = 16.67  # Target 16.67ms for 60fps

# Optimization flags
var auto_optimization_enabled: bool = true
var performance_warnings_enabled: bool = true

func _ready() -> void:
	print("PerformanceMonitor initialized")
	# Start monitoring
	set_process(true)
	
	# Initialize sample arrays
	fps_samples.resize(sample_size)
	memory_samples.resize(sample_size)
	cpu_samples.resize(sample_size)
	
	fps_samples.fill(60.0)
	memory_samples.fill(0.0)
	cpu_samples.fill(0.0)

func _process(_delta: float) -> void:
	update_performance_metrics()
	check_performance_thresholds()

func update_performance_metrics() -> void:
	"""Update all performance metrics"""
	# Update FPS
	current_fps = Engine.get_frames_per_second()
	frame_time_ms = 1000.0 / max(current_fps, 1.0)
	
	# Update memory usage
	current_memory_mb = get_memory_usage_mb()
	
	# Update CPU usage (approximated from frame time)
	current_cpu_usage = min((frame_time_ms / 16.67) * 100.0, 100.0)
	
	# Add to sample arrays
	add_sample(fps_samples, current_fps)
	add_sample(memory_samples, current_memory_mb)
	add_sample(cpu_samples, current_cpu_usage)
	
	# Calculate averages
	average_fps = calculate_average(fps_samples)

func add_sample(samples: Array[float], value: float) -> void:
	"""Add a new sample to the array, removing oldest"""
	samples.pop_front()
	samples.push_back(value)

func calculate_average(samples: Array[float]) -> float:
	"""Calculate average of samples"""
	var sum = 0.0
	for sample in samples:
		sum += sample
	return sum / samples.size()

func check_performance_thresholds() -> void:
	"""Check if performance metrics exceed thresholds"""
	if not performance_warnings_enabled:
		return
	
	# Check FPS
	if current_fps < min_fps_threshold:
		performance_warning.emit("fps", current_fps)
		if auto_optimization_enabled:
			trigger_fps_optimization()
	
	# Check memory usage
	if current_memory_mb > max_memory_mb:
		performance_warning.emit("memory", current_memory_mb)
		if auto_optimization_enabled:
			trigger_memory_optimization()
	
	# Check CPU usage
	if current_cpu_usage > max_cpu_usage:
		performance_warning.emit("cpu", current_cpu_usage)
		if auto_optimization_enabled:
			trigger_cpu_optimization()

func trigger_fps_optimization() -> void:
	"""Trigger optimizations to improve FPS"""
	print("Triggering FPS optimization - Current FPS: ", current_fps)
	optimization_triggered.emit("fps")
	
	# Reduce visual quality
	reduce_visual_quality()
	
	# Request asset cleanup
	if AssetManager:
		AssetManager.unload_unused_assets()

func trigger_memory_optimization() -> void:
	"""Trigger optimizations to reduce memory usage"""
	print("Triggering memory optimization - Current usage: ", current_memory_mb, "MB")
	optimization_triggered.emit("memory")
	
	# Force asset cleanup
	if AssetManager:
		AssetManager.unload_unused_assets()
	
	# Reduce cache sizes
	reduce_cache_sizes()

func trigger_cpu_optimization() -> void:
	"""Trigger optimizations to reduce CPU usage"""
	print("Triggering CPU optimization - Current usage: ", current_cpu_usage, "%")
	optimization_triggered.emit("cpu")
	
	# Reduce update frequencies
	reduce_update_frequencies()

func reduce_visual_quality() -> void:
	"""Reduce visual quality to improve performance"""
	# This would typically adjust rendering settings
	# For now, just log the action
	print("Reducing visual quality for better performance")

func reduce_cache_sizes() -> void:
	"""Reduce cache sizes to free memory"""
	if AssetManager:
		AssetManager.max_cache_size = max(AssetManager.max_cache_size - 10, 10)
		print("Reduced cache size to: ", AssetManager.max_cache_size)

func reduce_update_frequencies() -> void:
	"""Reduce update frequencies to save CPU"""
	# This would typically reduce physics update rates or other expensive operations
	print("Reducing update frequencies for better CPU performance")

func get_memory_usage_mb() -> float:
	"""Get current memory usage in MB"""
	# In Godot 4.x, use OS.get_static_memory_usage() instead
	var memory_usage = OS.get_static_memory_usage()
	return float(memory_usage) / (1024.0 * 1024.0)

func get_performance_stats() -> Dictionary:
	"""Get current performance statistics"""
	return {
		"current_fps": current_fps,
		"average_fps": average_fps,
		"frame_time_ms": frame_time_ms,
		"memory_usage_mb": current_memory_mb,
		"cpu_usage_percent": current_cpu_usage,
		"is_performing_well": is_performing_well()
	}

func is_performing_well() -> bool:
	"""Check if the game is performing within acceptable parameters"""
	return (current_fps >= min_fps_threshold and 
			current_memory_mb <= max_memory_mb and 
			current_cpu_usage <= max_cpu_usage)

func set_auto_optimization(enabled: bool) -> void:
	"""Enable or disable automatic optimization"""
	auto_optimization_enabled = enabled
	print("Auto optimization ", "enabled" if enabled else "disabled")

func set_performance_warnings(enabled: bool) -> void:
	"""Enable or disable performance warnings"""
	performance_warnings_enabled = enabled
	print("Performance warnings ", "enabled" if enabled else "disabled")

func reset_performance_history() -> void:
	"""Reset performance history samples"""
	fps_samples.fill(60.0)
	memory_samples.fill(0.0)
	cpu_samples.fill(0.0)
	print("Performance history reset")

func log_performance_report() -> void:
	"""Log a detailed performance report"""
	var stats = get_performance_stats()
	print("=== Performance Report ===")
	print("Current FPS: ", stats.current_fps)
	print("Average FPS: ", stats.average_fps)
	print("Frame Time: ", stats.frame_time_ms, "ms")
	print("Memory Usage: ", stats.memory_usage_mb, "MB")
	print("CPU Usage: ", stats.cpu_usage_percent, "%")
	print("Performance Status: ", "Good" if stats.is_performing_well else "Poor")
	print("==========================")