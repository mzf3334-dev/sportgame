extends Control
## MobileControlPanel manages the layout and customization of mobile UI controls
## Provides a customizable control layout system for different sports and preferences

signal control_layout_changed(layout_name: String)
signal action_triggered(action_name: String, strength: float, position: Vector2)

@export_group("Layout Settings")
@export var current_layout: String = "default"
@export var enable_customization: bool = true
@export var auto_hide_controls: bool = false
@export var control_opacity: float = 0.8

@export_group("Control Positions")
@export var joystick_position: Vector2 = Vector2(150, -150)
@export var action_buttons_position: Vector2 = Vector2(-150, -150)
@export var secondary_buttons_position: Vector2 = Vector2(-150, -300)

# Control components
var virtual_joystick: Control
var action_buttons: Dictionary = {}
var secondary_buttons: Dictionary = {}
var control_layouts: Dictionary = {}

# Layout customization
var is_customizing: bool = false
var selected_control: Control = null
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set up the control panel
	setup_control_panel()
	
	# Load default layouts
	setup_default_layouts()
	
	# Apply current layout
	apply_layout(current_layout)
	
	# Connect to InputController
	if InputController:
		InputController.setup_mobile_controls()

func setup_control_panel() -> void:
	# Set up the main control panel
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow touches to pass through empty areas
	
	# Create virtual joystick
	create_virtual_joystick()
	
	# Create action buttons
	create_action_buttons()
	
	# Create secondary buttons
	create_secondary_buttons()

func create_virtual_joystick() -> void:
	virtual_joystick = Control.new()
	virtual_joystick.set_script(preload("res://scripts/ui/VirtualJoystick.gd"))
	virtual_joystick.name = "VirtualJoystick"
	virtual_joystick.size = Vector2(140, 140)
	virtual_joystick.position = Vector2(joystick_position.x, size.y + joystick_position.y - virtual_joystick.size.y)
	virtual_joystick.modulate.a = control_opacity
	
	# Connect joystick signals
	virtual_joystick.direction_changed.connect(_on_joystick_direction_changed)
	virtual_joystick.joystick_pressed.connect(_on_joystick_pressed)
	virtual_joystick.joystick_released.connect(_on_joystick_released)
	
	add_child(virtual_joystick)

func create_action_buttons() -> void:
	# Primary action buttons (Jump, Shoot, Pass, etc.)
	var button_configs = [
		{"name": "jump", "text": "J", "position": Vector2(0, 0)},
		{"name": "shoot", "text": "S", "position": Vector2(-90, -30)},
		{"name": "pass", "text": "P", "position": Vector2(-60, 60)},
		{"name": "tackle", "text": "T", "position": Vector2(60, 30)}
	]
	
	for config in button_configs:
		var button = Control.new()
		button.set_script(preload("res://scripts/ui/VirtualButton.gd"))
		button.name = "Button_" + config.name
		button.button_name = config.name
		button.button_text = config.text
		button.size = Vector2(70, 70)
		
		var base_pos = Vector2(size.x + action_buttons_position.x, size.y + action_buttons_position.y)
		button.position = base_pos + config.position - button.size / 2
		button.modulate.a = control_opacity
		
		# Connect button signals
		button.button_pressed.connect(_on_action_button_pressed)
		button.button_released.connect(_on_action_button_released)
		
		action_buttons[config.name] = button
		add_child(button)

func create_secondary_buttons() -> void:
	# Secondary buttons (Pause, Settings, etc.)
	var secondary_configs = [
		{"name": "pause", "text": "||", "position": Vector2(0, 0)},
		{"name": "settings", "text": "⚙", "position": Vector2(80, 0)}
	]
	
	for config in secondary_configs:
		var button = Control.new()
		button.set_script(preload("res://scripts/ui/VirtualButton.gd"))
		button.name = "SecondaryButton_" + config.name
		button.button_name = config.name
		button.button_text = config.text
		button.size = Vector2(50, 50)
		
		var base_pos = Vector2(size.x + secondary_buttons_position.x, secondary_buttons_position.y)
		button.position = base_pos + config.position - button.size / 2
		button.modulate.a = control_opacity * 0.7  # Make secondary buttons more transparent
		
		# Connect button signals
		button.button_pressed.connect(_on_secondary_button_pressed)
		button.button_released.connect(_on_secondary_button_released)
		
		secondary_buttons[config.name] = button
		add_child(button)

func setup_default_layouts() -> void:
	# Default layout
	control_layouts["default"] = {
		"joystick_position": Vector2(150, -150),
		"action_buttons_position": Vector2(-150, -150),
		"secondary_buttons_position": Vector2(-150, -50),
		"joystick_size": 140,
		"button_size": 70,
		"opacity": 0.8
	}
	
	# Basketball layout
	control_layouts["basketball"] = {
		"joystick_position": Vector2(120, -120),
		"action_buttons_position": Vector2(-120, -120),
		"secondary_buttons_position": Vector2(-120, -50),
		"joystick_size": 150,
		"button_size": 75,
		"opacity": 0.8
	}
	
	# Football layout
	control_layouts["football"] = {
		"joystick_position": Vector2(140, -140),
		"action_buttons_position": Vector2(-140, -140),
		"secondary_buttons_position": Vector2(-140, -50),
		"joystick_size": 160,
		"button_size": 70,
		"opacity": 0.8
	}
	
	# Tennis layout
	control_layouts["tennis"] = {
		"joystick_position": Vector2(130, -130),
		"action_buttons_position": Vector2(-130, -130),
		"secondary_buttons_position": Vector2(-130, -50),
		"joystick_size": 140,
		"button_size": 65,
		"opacity": 0.8
	}

func apply_layout(layout_name: String) -> void:
	if not layout_name in control_layouts:
		print("Layout not found: ", layout_name)
		return
	
	var layout = control_layouts[layout_name]
	current_layout = layout_name
	
	# Update joystick
	if virtual_joystick:
		var joystick_pos = Vector2(layout.joystick_position.x, size.y + layout.joystick_position.y - layout.joystick_size)
		virtual_joystick.position = joystick_pos
		virtual_joystick.set_sizes(layout.joystick_size, layout.joystick_size * 0.3)
		virtual_joystick.modulate.a = layout.opacity
	
	# Update action buttons
	var base_action_pos = Vector2(size.x + layout.action_buttons_position.x, size.y + layout.action_buttons_position.y)
	for button_name in action_buttons:
		var button = action_buttons[button_name]
		button.set_button_size(layout.button_size)
		button.modulate.a = layout.opacity
		# Keep relative positions but update base position
		var relative_pos = button.position - Vector2(size.x + action_buttons_position.x, size.y + action_buttons_position.y)
		button.position = base_action_pos + relative_pos
	
	# Update secondary buttons
	var base_secondary_pos = Vector2(size.x + layout.secondary_buttons_position.x, layout.secondary_buttons_position.y)
	for button_name in secondary_buttons:
		var button = secondary_buttons[button_name]
		button.modulate.a = layout.opacity * 0.7
		var relative_pos = button.position - Vector2(size.x + secondary_buttons_position.x, secondary_buttons_position.y)
		button.position = base_secondary_pos + relative_pos
	
	# Update stored positions
	joystick_position = layout.joystick_position
	action_buttons_position = layout.action_buttons_position
	secondary_buttons_position = layout.secondary_buttons_position
	control_opacity = layout.opacity
	
	control_layout_changed.emit(layout_name)

# Signal handlers
func _on_joystick_direction_changed(direction: Vector2) -> void:
	action_triggered.emit("move", direction.length(), virtual_joystick.global_position)

func _on_joystick_pressed() -> void:
	action_triggered.emit("move_start", 1.0, virtual_joystick.global_position)

func _on_joystick_released() -> void:
	action_triggered.emit("move_end", 0.0, virtual_joystick.global_position)

func _on_action_button_pressed(button_name: String) -> void:
	var button = action_buttons.get(button_name)
	var position = button.global_position if button else Vector2.ZERO
	action_triggered.emit(button_name, 1.0, position)

func _on_action_button_released(button_name: String) -> void:
	var button = action_buttons.get(button_name)
	var position = button.global_position if button else Vector2.ZERO
	action_triggered.emit(button_name + "_release", 0.0, position)

func _on_secondary_button_pressed(button_name: String) -> void:
	var button = secondary_buttons.get(button_name)
	var position = button.global_position if button else Vector2.ZERO
	action_triggered.emit(button_name, 1.0, position)

func _on_secondary_button_released(button_name: String) -> void:
	var button = secondary_buttons.get(button_name)
	var position = button.global_position if button else Vector2.ZERO
	action_triggered.emit(button_name + "_release", 0.0, position)

# Public API
func get_current_layout() -> String:
	return current_layout

func get_available_layouts() -> Array:
	return control_layouts.keys()

func set_control_opacity(opacity: float) -> void:
	control_opacity = clamp(opacity, 0.1, 1.0)
	
	if virtual_joystick:
		virtual_joystick.modulate.a = control_opacity
	
	for button in action_buttons.values():
		button.modulate.a = control_opacity
	
	for button in secondary_buttons.values():
		button.modulate.a = control_opacity * 0.7

func hide_controls() -> void:
	visible = false

func show_controls() -> void:
	visible = true

func enable_customization_mode() -> void:
	is_customizing = true
	# Add visual indicators for customization mode
	for button in action_buttons.values():
		button.modulate = Color.YELLOW * 0.8
	for button in secondary_buttons.values():
		button.modulate = Color.YELLOW * 0.8
	if virtual_joystick:
		virtual_joystick.modulate = Color.YELLOW * 0.8

func disable_customization_mode() -> void:
	is_customizing = false
	# Restore normal colors
	set_control_opacity(control_opacity)

func save_custom_layout(layout_name: String) -> void:
	var custom_layout = {
		"joystick_position": joystick_position,
		"action_buttons_position": action_buttons_position,
		"secondary_buttons_position": secondary_buttons_position,
		"joystick_size": virtual_joystick.base_size if virtual_joystick else 140,
		"button_size": 70,
		"opacity": control_opacity
	}
	
	control_layouts[layout_name] = custom_layout
	print("Custom layout saved: ", layout_name)

func get_joystick_direction() -> Vector2:
	if virtual_joystick and virtual_joystick.has_method("get_direction"):
		return virtual_joystick.get_direction()
	return Vector2.ZERO

func is_button_pressed(button_name: String) -> bool:
	if button_name in action_buttons:
		return action_buttons[button_name].is_button_pressed()
	elif button_name in secondary_buttons:
		return secondary_buttons[button_name].is_button_pressed()
	return false

# Handle screen size changes
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Reapply layout when screen size changes
		apply_layout(current_layout)