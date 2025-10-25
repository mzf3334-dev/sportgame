extends Control
## VirtualJoystick provides touch-based directional input for mobile devices
## Emits movement signals and provides visual feedback

signal direction_changed(direction: Vector2)
signal joystick_pressed()
signal joystick_released()

@export_group("Joystick Settings")
@export var deadzone: float = 0.1
@export var max_distance: float = 100.0
@export var return_to_center: bool = true
@export var follow_touch: bool = false

@export_group("Visual Settings")
@export var base_color: Color = Color(1, 1, 1, 0.3)
@export var knob_color: Color = Color(1, 1, 1, 0.8)
@export var pressed_color: Color = Color(0.8, 0.8, 1, 0.9)
@export var base_size: float = 120.0
@export var knob_size: float = 40.0

@export_group("Feedback Settings")
@export var enable_haptic_feedback: bool = true
@export var haptic_strength: float = 0.5

# Internal variables
var is_pressed: bool = false
var touch_id: int = -1
var center_position: Vector2
var current_direction: Vector2 = Vector2.ZERO
var knob_position: Vector2

# Visual components
var base_circle: Control
var knob_circle: Control

func _ready() -> void:
	# Set up the joystick visual components
	setup_visual_components()
	
	# Connect to input events
	gui_input.connect(_on_gui_input)
	
	# Set initial position
	center_position = size / 2
	knob_position = center_position
	
	# Connect to InputController if available
	if InputController:
		InputController.touch_started.connect(_on_touch_started)
		InputController.touch_ended.connect(_on_touch_ended)
		InputController.touch_moved.connect(_on_touch_moved)

func setup_visual_components() -> void:
	# Create base circle
	base_circle = Control.new()
	base_circle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	base_circle.size = Vector2(base_size, base_size)
	base_circle.position = center_position - base_circle.size / 2
	add_child(base_circle)
	
	# Create knob circle
	knob_circle = Control.new()
	knob_circle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	knob_circle.size = Vector2(knob_size, knob_size)
	knob_circle.position = center_position - knob_circle.size / 2
	add_child(knob_circle)
	
	# Enable custom drawing
	set_process(true)

func _draw() -> void:
	# Draw base circle
	draw_circle(center_position, base_size / 2, base_color)
	draw_arc(center_position, base_size / 2, 0, TAU, 64, base_color * 1.5, 2.0)
	
	# Draw knob circle
	var knob_color_current = pressed_color if is_pressed else knob_color
	draw_circle(knob_position, knob_size / 2, knob_color_current)
	draw_arc(knob_position, knob_size / 2, 0, TAU, 32, knob_color_current * 1.2, 1.5)
	
	# Draw deadzone indicator
	if deadzone > 0:
		var deadzone_radius = (base_size / 2) * deadzone
		draw_arc(center_position, deadzone_radius, 0, TAU, 32, Color.WHITE * 0.2, 1.0)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventScreenDrag:
		handle_drag_input(event)
	elif event is InputEventMouseButton and OS.is_debug_build():
		# Mouse emulation for testing
		handle_mouse_input(event)
	elif event is InputEventMouseMotion and OS.is_debug_build():
		# Mouse drag emulation
		handle_mouse_drag(event)

func handle_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed and not is_pressed:
		start_joystick_input(event.index, event.position)
	elif not event.pressed and is_pressed and event.index == touch_id:
		end_joystick_input()

func handle_drag_input(event: InputEventScreenDrag) -> void:
	if is_pressed and event.index == touch_id:
		update_joystick_position(event.position)

func handle_mouse_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_pressed:
			start_joystick_input(0, event.position)
		elif not event.pressed and is_pressed:
			end_joystick_input()

func handle_mouse_drag(event: InputEventMouseMotion) -> void:
	if is_pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		update_joystick_position(event.position)

func _on_touch_started(id: int, position: Vector2) -> void:
	# Handle touch events from InputController
	var local_pos = global_position - position
	if get_rect().has_point(local_pos) and not is_pressed:
		start_joystick_input(id, local_pos)

func _on_touch_ended(id: int, position: Vector2) -> void:
	if is_pressed and id == touch_id:
		end_joystick_input()

func _on_touch_moved(id: int, position: Vector2, relative: Vector2) -> void:
	if is_pressed and id == touch_id:
		var local_pos = global_position - position
		update_joystick_position(local_pos)

func start_joystick_input(id: int, position: Vector2) -> void:
	is_pressed = true
	touch_id = id
	
	# Update center position if follow_touch is enabled
	if follow_touch:
		center_position = position
	
	update_joystick_position(position)
	joystick_pressed.emit()
	
	# Haptic feedback
	if enable_haptic_feedback and Input.get_connected_joypads().size() > 0:
		Input.start_joy_vibration(0, haptic_strength, haptic_strength, 0.1)

func end_joystick_input() -> void:
	is_pressed = false
	touch_id = -1
	
	# Return to center
	if return_to_center:
		knob_position = center_position
		current_direction = Vector2.ZERO
		direction_changed.emit(current_direction)
	
	joystick_released.emit()
	queue_redraw()

func update_joystick_position(position: Vector2) -> void:
	var offset = position - center_position
	var distance = offset.length()
	
	# Clamp to max distance
	if distance > max_distance:
		offset = offset.normalized() * max_distance
		distance = max_distance
	
	knob_position = center_position + offset
	
	# Calculate direction with deadzone
	if distance > max_distance * deadzone:
		var normalized_distance = (distance - max_distance * deadzone) / (max_distance - max_distance * deadzone)
		current_direction = offset.normalized() * normalized_distance
	else:
		current_direction = Vector2.ZERO
	
	direction_changed.emit(current_direction)
	queue_redraw()

# Public API
func get_direction() -> Vector2:
	return current_direction

func get_strength() -> float:
	return current_direction.length()

func is_active() -> bool:
	return is_pressed

func set_center_position(pos: Vector2) -> void:
	center_position = pos
	if not is_pressed:
		knob_position = center_position
	queue_redraw()

func reset() -> void:
	if is_pressed:
		end_joystick_input()

# Configuration methods
func set_deadzone(value: float) -> void:
	deadzone = clamp(value, 0.0, 1.0)

func set_max_distance(value: float) -> void:
	max_distance = max(value, 10.0)

func set_colors(base: Color, knob: Color, pressed: Color) -> void:
	base_color = base
	knob_color = knob
	pressed_color = pressed
	queue_redraw()

func set_sizes(base: float, knob: float) -> void:
	base_size = max(base, 50.0)
	knob_size = max(knob, 20.0)
	knob_size = min(knob_size, base_size * 0.8)  # Ensure knob fits in base
	queue_redraw()