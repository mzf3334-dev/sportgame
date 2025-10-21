extends Node
## InputController manages all input handling for mobile devices
## Handles touch events, multi-touch, gestures, and provides input signals

signal action_performed(action_type: String, strength: float, position: Vector2)
signal gesture_detected(gesture_type: String, data: Dictionary)
signal touch_started(touch_id: int, position: Vector2)
signal touch_ended(touch_id: int, position: Vector2)
signal touch_moved(touch_id: int, position: Vector2, relative: Vector2)

enum ActionType {
	MOVE,
	JUMP,
	SHOOT,
	PASS,
	TACKLE,
	SERVE,
	CUSTOM
}

enum GestureType {
	TAP,
	DOUBLE_TAP,
	LONG_PRESS,
	SWIPE,
	PINCH,
	ROTATE
}

# Touch tracking
var active_touches: Dictionary = {}
var touch_start_times: Dictionary = {}
var touch_start_positions: Dictionary = {}

# Gesture detection settings
@export var double_tap_time: float = 0.3
@export var long_press_time: float = 0.5
@export var swipe_threshold: float = 100.0
@export var tap_threshold: float = 20.0

# Input response settings
@export var input_response_time: float = 0.016  # 16ms requirement
@export var multi_touch_enabled: bool = true
@export var gesture_recognition_enabled: bool = true

# Gesture detection variables
var last_tap_time: float = 0.0
var last_tap_position: Vector2 = Vector2.ZERO
var gesture_timers: Dictionary = {}

func _ready() -> void:
	print("InputController initialized")
	# Enable input processing
	set_process_input(true)
	set_process_unhandled_input(true)

func _input(event: InputEvent) -> void:
	# Handle touch events with priority
	if event is InputEventScreenTouch:
		handle_touch_event(event)
	elif event is InputEventScreenDrag:
		handle_drag_event(event)
	elif event is InputEventMouseButton and OS.is_debug_build():
		# Mouse emulation for testing in editor
		handle_mouse_as_touch(event)
	elif event is InputEventMouseMotion and OS.is_debug_build():
		# Mouse drag emulation for testing
		handle_mouse_drag_as_touch(event)

func handle_touch_event(event: InputEventScreenTouch) -> void:
	var touch_id = event.index
	var position = event.position
	var current_time = Time.get_time_dict_from_system()
	var timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second + current_time.millisecond * 0.001
	
	if event.pressed:
		# Touch started
		active_touches[touch_id] = {
			"position": position,
			"start_position": position,
			"start_time": timestamp,
			"moved": false
		}
		touch_start_times[touch_id] = timestamp
		touch_start_positions[touch_id] = position
		
		touch_started.emit(touch_id, position)
		
		# Start long press detection
		if gesture_recognition_enabled:
			start_long_press_detection(touch_id, position)
		
	else:
		# Touch ended
		if touch_id in active_touches:
			var touch_data = active_touches[touch_id]
			var duration = timestamp - touch_data.start_time
			var distance = position.distance_to(touch_data.start_position)
			
			touch_ended.emit(touch_id, position)
			
			# Gesture detection
			if gesture_recognition_enabled:
				detect_gesture_on_release(touch_id, position, duration, distance)
			
			# Clean up
			active_touches.erase(touch_id)
			touch_start_times.erase(touch_id)
			touch_start_positions.erase(touch_id)
			stop_long_press_detection(touch_id)

func handle_drag_event(event: InputEventScreenDrag) -> void:
	var touch_id = event.index
	var position = event.position
	var relative = event.relative
	
	if touch_id in active_touches:
		active_touches[touch_id].position = position
		active_touches[touch_id].moved = true
		
		touch_moved.emit(touch_id, position, relative)
		
		# Cancel long press if moved too much
		var start_pos = active_touches[touch_id].start_position
		if position.distance_to(start_pos) > tap_threshold:
			stop_long_press_detection(touch_id)

func handle_mouse_as_touch(event: InputEventMouseButton) -> void:
	# Convert mouse events to touch events for testing
	var touch_event = InputEventScreenTouch.new()
	touch_event.index = 0
	touch_event.position = event.position
	touch_event.pressed = event.pressed
	handle_touch_event(touch_event)

func handle_mouse_drag_as_touch(event: InputEventMouseMotion) -> void:
	# Convert mouse motion to touch drag for testing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var drag_event = InputEventScreenDrag.new()
		drag_event.index = 0
		drag_event.position = event.position
		drag_event.relative = event.relative
		handle_drag_event(drag_event)

func detect_gesture_on_release(touch_id: int, position: Vector2, duration: float, distance: float) -> void:
	var start_position = touch_start_positions.get(touch_id, Vector2.ZERO)
	
	# Tap detection
	if distance < tap_threshold and duration < long_press_time:
		detect_tap_gesture(position)
	
	# Swipe detection
	elif distance > swipe_threshold:
		detect_swipe_gesture(start_position, position, duration)

func detect_tap_gesture(position: Vector2) -> void:
	var current_time = Time.get_time_dict_from_system()
	var timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second + current_time.millisecond * 0.001
	
	# Check for double tap
	if timestamp - last_tap_time < double_tap_time and position.distance_to(last_tap_position) < tap_threshold:
		gesture_detected.emit("double_tap", {"position": position})
	else:
		gesture_detected.emit("tap", {"position": position})
	
	last_tap_time = timestamp
	last_tap_position = position

func detect_swipe_gesture(start_pos: Vector2, end_pos: Vector2, duration: float) -> void:
	var direction = (end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(end_pos)
	var velocity = distance / duration if duration > 0 else 0
	
	var swipe_data = {
		"start_position": start_pos,
		"end_position": end_pos,
		"direction": direction,
		"distance": distance,
		"velocity": velocity,
		"duration": duration
	}
	
	gesture_detected.emit("swipe", swipe_data)

func start_long_press_detection(touch_id: int, position: Vector2) -> void:
	var timer = Timer.new()
	timer.wait_time = long_press_time
	timer.one_shot = true
	timer.timeout.connect(_on_long_press_timeout.bind(touch_id, position))
	add_child(timer)
	timer.start()
	gesture_timers[touch_id] = timer

func stop_long_press_detection(touch_id: int) -> void:
	if touch_id in gesture_timers:
		var timer = gesture_timers[touch_id]
		timer.queue_free()
		gesture_timers.erase(touch_id)

func _on_long_press_timeout(touch_id: int, position: Vector2) -> void:
	if touch_id in active_touches:
		gesture_detected.emit("long_press", {"position": position, "touch_id": touch_id})
	gesture_timers.erase(touch_id)

# Public API for game systems
func is_touch_active(touch_id: int = 0) -> bool:
	return touch_id in active_touches

func get_touch_position(touch_id: int = 0) -> Vector2:
	if touch_id in active_touches:
		return active_touches[touch_id].position
	return Vector2.ZERO

func get_active_touch_count() -> int:
	return active_touches.size()

func get_all_active_touches() -> Dictionary:
	return active_touches.duplicate()

# Action mapping system
func map_gesture_to_action(gesture_type: String, action_type: String, strength: float = 1.0) -> void:
	var position = Vector2.ZERO
	if active_touches.size() > 0:
		position = active_touches.values()[0].position
	
	action_performed.emit(action_type, strength, position)

# Custom control layout support
func setup_mobile_controls() -> void:
	print("Setting up mobile controls")
	# This will be called by UI components to register themselves

func customize_layout(layout_data: Dictionary) -> void:
	print("Customizing control layout: ", layout_data)
	# Store custom layout preferences
	# This will be implemented when UI components are created

# Performance monitoring
func get_input_response_time() -> float:
	return input_response_time

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Clear all active touches when app loses focus
			active_touches.clear()
			touch_start_times.clear()
			touch_start_positions.clear()
			for timer in gesture_timers.values():
				timer.queue_free()
			gesture_timers.clear()