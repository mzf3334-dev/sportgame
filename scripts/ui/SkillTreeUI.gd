class_name SkillTreeUI
extends Control
## UI for managing player skill tree

signal skill_upgraded(skill_name: String)
signal skills_reset

@onready var skill_points_label: Label = $SkillPointsLabel
@onready var skill_tree_container: GridContainer = $ScrollContainer/SkillTreeContainer
@onready var skill_description: RichTextLabel = $SkillDescription
@onready var reset_button: Button = $ResetButton

var skill_tree
var skill_buttons: Dictionary = {}

func _ready() -> void:
	setup_ui()

func setup_ui() -> void:
	"""Initialize the skill tree UI"""
	if reset_button:
		reset_button.pressed.connect(_on_reset_skills_pressed)

func initialize(player_skill_tree) -> void:
	"""Initialize with a skill tree"""
	skill_tree = player_skill_tree
	
	# Connect signals
	skill_tree.skill_upgraded.connect(_on_skill_upgraded)
	skill_tree.skill_unlocked.connect(_on_skill_unlocked)
	
	create_skill_tree_ui()
	update_display()

func create_skill_tree_ui() -> void:
	"""Create the visual skill tree"""
	if not skill_tree_container:
		return
	
	# Clear existing buttons
	for child in skill_tree_container.get_children():
		child.queue_free()
	skill_buttons.clear()
	
	# Set up grid layout (4 columns for better organization)
	skill_tree_container.columns = 4
	
	var tree_data = skill_tree.get_skill_tree_data()
	
	# Create skill buttons in logical order
	var skill_order = [
		"speed", "strength", "accuracy", "stamina",
		"agility", "power_shot", "", "",
		"leadership", "", "", "",
		"clutch_performer", "", "", ""
	]
	
	for skill_name in skill_order:
		if skill_name.is_empty():
			# Add spacer
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(100, 80)
			skill_tree_container.add_child(spacer)
			continue
		
		if not tree_data.has(skill_name):
			continue
		
		var skill_data = tree_data[skill_name]
		var skill_button = create_skill_button(skill_name, skill_data)
		skill_tree_container.add_child(skill_button)
		skill_buttons[skill_name] = skill_button

func create_skill_button(skill_name: String, skill_data: Dictionary) -> Button:
	"""Create a button for a skill"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 80)
	button.text = skill_data.definition.name + "\nLv." + str(skill_data.current_level)
	
	# Style based on skill state
	if not skill_data.is_unlocked:
		button.modulate = Color.GRAY
		button.disabled = not skill_data.can_upgrade
	elif skill_data.can_upgrade:
		button.modulate = Color.GREEN
	else:
		button.modulate = Color.WHITE
	
	# Connect signals
	button.pressed.connect(_on_skill_button_pressed.bind(skill_name))
	button.mouse_entered.connect(_on_skill_button_hovered.bind(skill_name))
	
	return button

func update_display() -> void:
	"""Update the entire display"""
	update_skill_points_display()
	update_skill_buttons()

func update_skill_points_display() -> void:
	"""Update skill points label"""
	if skill_points_label and skill_tree:
		skill_points_label.text = "Skill Points: " + str(skill_tree.skill_points)

func update_skill_buttons() -> void:
	"""Update all skill buttons"""
	if not skill_tree:
		return
	
	var tree_data = skill_tree.get_skill_tree_data()
	
	for skill_name in skill_buttons:
		if not tree_data.has(skill_name):
			continue
		
		var skill_data = tree_data[skill_name]
		var button = skill_buttons[skill_name]
		
		# Update text
		button.text = skill_data.definition.name + "\nLv." + str(skill_data.current_level)
		
		# Update appearance
		if not skill_data.is_unlocked:
			button.modulate = Color.GRAY
			button.disabled = not skill_data.can_upgrade
		elif skill_data.can_upgrade:
			button.modulate = Color.GREEN
			button.disabled = false
		else:
			button.modulate = Color.WHITE
			button.disabled = true
		
		# Add max level indicator
		if skill_data.current_level >= skill_data.definition.max_level:
			button.text += "\n(MAX)"
			button.modulate = Color.GOLD

func _on_skill_button_pressed(skill_name: String) -> void:
	"""Handle skill button press"""
	if skill_tree and skill_tree.can_upgrade_skill(skill_name):
		if skill_tree.upgrade_skill(skill_name):
			skill_upgraded.emit(skill_name)
			update_display()
			show_skill_description(skill_name)

func _on_skill_button_hovered(skill_name: String) -> void:
	"""Handle skill button hover"""
	show_skill_description(skill_name)

func show_skill_description(skill_name: String) -> void:
	"""Show description for a skill"""
	if not skill_description or not skill_tree:
		return
	
	var description = skill_tree.get_skill_description(skill_name)
	skill_description.text = description

func _on_skill_upgraded(skill_name: String, new_level: int) -> void:
	"""Handle skill upgrade"""
	print("Skill upgraded: ", skill_name, " to level ", new_level)
	
	# Show upgrade effect
	show_upgrade_effect(skill_name)

func _on_skill_unlocked(skill_name: String) -> void:
	"""Handle skill unlock"""
	print("Skill unlocked: ", skill_name)
	
	# Show unlock effect
	show_unlock_effect(skill_name)

func show_upgrade_effect(skill_name: String) -> void:
	"""Show visual effect for skill upgrade"""
	if not skill_buttons.has(skill_name):
		return
	
	var button = skill_buttons[skill_name]
	
	# Create upgrade effect
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2(1.2, 1.2), 0.2)
	tween.parallel().tween_property(button, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.2)

func show_unlock_effect(skill_name: String) -> void:
	"""Show visual effect for skill unlock"""
	if not skill_buttons.has(skill_name):
		return
	
	var button = skill_buttons[skill_name]
	
	# Create unlock effect
	var tween = create_tween()
	tween.parallel().tween_property(button, "scale", Vector2(1.3, 1.3), 0.3)
	tween.parallel().tween_property(button, "modulate", Color.CYAN, 0.3)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.3)
	tween.parallel().tween_property(button, "modulate", Color.WHITE, 0.3)

func _on_reset_skills_pressed() -> void:
	"""Handle reset skills button"""
	if not skill_tree:
		return
	
	# Show confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Are you sure you want to reset all skills? This will refund your skill points."
	dialog.title = "Reset Skills"
	
	# Add cancel button
	dialog.add_cancel_button("Cancel")
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Wait for user response
	var result = await dialog.confirmed
	dialog.queue_free()
	
	if result:
		var refunded_points = skill_tree.reset_skills()
		skills_reset.emit()
		update_display()
		
		# Show refund message
		var refund_dialog = AcceptDialog.new()
		refund_dialog.dialog_text = "Skills reset! Refunded " + str(refunded_points) + " skill points."
		add_child(refund_dialog)
		refund_dialog.popup_centered()
		await refund_dialog.confirmed
		refund_dialog.queue_free()

func add_skill_points(points: int) -> void:
	"""Add skill points and update display"""
	if skill_tree:
		skill_tree.add_skill_points(points)
		update_display()

func get_total_skill_effects() -> Dictionary:
	"""Get total effects from all skills"""
	if skill_tree:
		return skill_tree.get_total_effects()
	return {}

func save_skill_tree() -> Dictionary:
	"""Save skill tree data"""
	if not skill_tree:
		return {}
	
	return {
		"skills": skill_tree.skills,
		"skill_points": skill_tree.skill_points
	}

func load_skill_tree(data: Dictionary) -> void:
	"""Load skill tree data"""
	if not skill_tree:
		return
	
	skill_tree.skills = data.get("skills", {})
	skill_tree.skill_points = data.get("skill_points", 0)
	
	# Ensure basic skills exist
	for skill_name in ["speed", "strength", "accuracy", "stamina"]:
		if not skill_tree.skills.has(skill_name):
			skill_tree.skills[skill_name] = 1
	
	update_display()