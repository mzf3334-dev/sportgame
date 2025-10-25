extends Control
## VirtualButton provides touch-based button input for mobile devices
## Supports various button types and visual/haptic feedback

signal button_pressed(button_name: String)
signal button_released(button_name: String)
signal button_held(button_name: String, hold_time: float)

@export_group("Button Settings")
@export var button_name: String = "action"
@export var button_type: ButtonType = ButtonType.NORMAL
@export var hold_threshold: float = 0.5
@export var repeat_rate: float = 0.1

@export_group("Visual Settings")
@export var normal_color: Color = Color(1, 1, 1, 0.6)
@export var pressed_color: Color = Color(0.8, 0.8, 1, 0.9)
@export var disabled_color: Color = Color(0.5, 0.5, 0.5, 0.3)
@export var button_size: float = 80.0
@export var icon_texture: Texture2D
@export var button_text: String = ""

@export_group("Feedback Settings")
@export var enable_haptic_feedback: bool = true
@export var haptic_strength: float = 0.3
@export var enable_visual_feedback: bool = true
@export var feedback_scale: float = 1.1

enum ButtonType {
	NORMAL,      # Single press
	TOGGLE,      # On/off state
	HOLD,        # Hold for continuous action
	REPEAT       # Repeat while held
}

# Internal state
var is_pressed: bool = false
var is_enabled: bool = true
var is_toggled: bool = false
var touch_id: int = -1
var press_start_time: float = 0.0
var hold_timer: Timer
var repeat_timer: Timer

# Visual state
var current_scale: float = 1.0
var target_scale: float = 1.0

func _ready() -> void:
	# Set up timers
	setup_timers()
	
	# Connect input events
	gui_input.connect(_on_gui_input)
	
	# Set initial size
	size = Vector2(button_size, button_size)
	
	# Connect to InputController if available
	if InputController:
		InputController.touch_started.connect(_on_touch_started)
		InputController.touch_ended.connect(_on_touch_ended)
	
	# Enable drawing and processing
	set_process(true)

func setup_timers() -> void:
	# Hold timer for HOLD button type
	hold_timer = Timer.new()
	hold_timer.wait_time = hold_threshold
	hold_timer.one_shot = true
	hold_timer.timeout.connect(_on_hold_timeout)
	add_child(hold_timer)
	
	# Repeat timer for REPEAT button type
	repeat_timer = Timer.new()
	repeat_timer.wait_time = repeat_rate
	repeat_timer.timeout.connect(_on_repeat_timeout)
	add_child(repeat_timer)

func _draw() -> void:
	var center = size / 2
	var radius = button_size / 2
	
	# Choose color based on state
	var draw_color = normal_color
	if not is_enabled:
		draw_color = disabled_color
	elif is_pressed or (button_type == ButtonType.TOGGLE and is_toggled):
		draw_color = pressed_color
	
	# Draw button background
	draw_circle(center, radius * current_scale, draw_color)
	draw_arc(center, radius * current_scale, 0, TAU, 64, draw_color * 1.3, 2.0)
	
	# Draw icon if available
	if icon_texture:
		var icon_size = Vector2(radius, radius) * current_scale
		var icon_pos = center - icon_size / 2
		draw_texture_rect(icon_texture, Rect2(icon_pos, icon_size), false, Color.WHITE)
	
	# Draw text if available
	if button_text != "":
		var font = ThemeDB.fallback_font
		var font_size = int(radius * 0.3 * current_scale)
		var text_size = font.get_string_size(button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = center - text_size / 2
		draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _process(delta: float) -> void:
	# Smooth scale animation
	if abs(current_scale - target_scale) > 0.01:
		current_scale = lerp(current_scale, target_scale, delta * 10.0)
		queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if not is_enabled:
		return
	
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventMouseButton and OS.is_debug_build():
		handle_mouse_input(event)

func handle_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed and not is_pressed:
		start_button_press(event.index, event.position)
	elif not event.pressed and is_pressed and event.index == touch_id:
		end_button_press()

func handle_mouse_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_pressed:
			start_button_press(0, event.position)
		elif not event.pressed and is_pressed:
			end_button_press()

func _on_touch_started(id: int, position: Vector2) -> void:
	var local_pos = global_position - position
	if get_rect().has_point(local_pos) and not is_pressed and is_enabled:
		start_button_press(id, local_pos)

func _on_touch_ended(id: int, position: Vector2) -> void:
	if is_pressed and id == touch_id:
		end_button_press()

func start_button_press(id: int, position: Vector2) -> void:
	is_pressed = true
	touch_id = id
	press_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	# Visual feedback
	if enable_visual_feedback:
		target_scale = feedback_scale
	
	# Haptic feedback
	if enable_haptic_feedback and Input.get_connected_joypads().size() > 0:
		Input.start_joy_vibration(0, haptic_strength, haptic_strength, 0.05)
	
	# Handle different button types
	match button_type:
		ButtonType.NORMAL:
			button_pressed.emit(button_name)
		
		ButtonType.TOGGLE:
			is_toggled = not is_toggled
			button_pressed.emit(button_name)
		
		ButtonType.HOLD:
			hold_timer.start()
			button_pressed.emit(button_name)
		
		ButtonType.REPEAT:
			button_pressed.emit(button_name)
			repeat_timer.start()
	
	queue_redraw()

func end_button_press() -> void:
	is_pressed = false
	touch_id = -1
	
	# Visual feedback
	if enable_visual_feedback:
		target_scale = 1.0
	
	# Stop timers
	hold_timer.stop()
	repeat_timer.stop()
	
	# Handle button release
	match button_type:
		ButtonType.NORMAL, ButtonType.HOLD, ButtonType.REPEAT:
			button_released.emit(button_name)
		
		ButtonType.TOGGLE:
			# Toggle buttons don't emit release, state is maintained
			pass
	
	queue_redraw()

func _on_hold_timeout() -> void:
	if is_pressed:
		var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		var hold_time = current_time - press_start_time
		button_held.emit(button_name, hold_time)

func _on_repeat_timeout() -> void:
	if is_pressed:
		button_pressed.emit(button_name)
		repeat_timer.start()  # Continue repeating

# Public API
func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	if not enabled and is_pressed:
		end_button_press()
	queue_redraw()

func is_button_enabled() -> bool:
	return is_enabled

func is_button_pressed() -> bool:
	return is_pressed

func is_button_toggled() -> bool:
	return is_toggled and button_type == ButtonType.TOGGLE

func set_toggle_state(toggled: bool) -> void:
	if button_type == ButtonType.TOGGLE:
		is_toggled = toggled
		queue_redraw()

func set_button_text(text: String) -> void:
	button_text = text
	queue_redraw()

func set_button_icon(texture: Texture2D) -> void:
	icon_texture = texture
	queue_redraw()

func set_button_size(size: float) -> void:
	button_size = max(size, 30.0)
	self.size = Vector2(button_size, button_size)
	queue_redraw()

func set_colors(normal: Color, pressed: Color, disabled: Color) -> void:
	normal_color = normal
	pressed_color = pressed
	disabled_color = disabled
	queue_redraw()

# Animation methods
func pulse_animation(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_method(_set_scale, 1.0, 1.2, duration / 2)
	tween.tween_method(_set_scale, 1.2, 1.0, duration / 2)

func _set_scale(scale: float) -> void:
	current_scale = scale
	queue_redraw()