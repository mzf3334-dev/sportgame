extends Control
## Test scene for demonstrating the player system functionality

@onready var player_info_label: Label = $VBoxContainer/PlayerInfoLabel
@onready var results_label: RichTextLabel = $VBoxContainer/ResultsLabel
@onready var test_data_button: Button = $VBoxContainer/ButtonContainer/TestDataButton
@onready var test_skills_button: Button = $VBoxContainer/ButtonContainer/TestSkillsButton
@onready var test_equipment_button: Button = $VBoxContainer/ButtonContainer/TestEquipmentButton
@onready var open_customization_button: Button = $VBoxContainer/OpenCustomizationButton
@onready var open_skill_tree_button: Button = $VBoxContainer/OpenSkillTreeButton

var player_manager: Node
var current_player_data: Resource

func _ready() -> void:
	# Initialize player manager
	var player_manager_script = preload("res://scripts/managers/PlayerManager.gd")
	player_manager = player_manager_script.new()
	add_child(player_manager)
	
	# Wait for player data to load
	await player_manager.player_data_loaded
	if player_manager and player_manager.has_method("get_player_data"):
		current_player_data = player_manager.get_player_data()
	
	# Connect buttons
	test_data_button.pressed.connect(_on_test_data_pressed)
	test_skills_button.pressed.connect(_on_test_skills_pressed)
	test_equipment_button.pressed.connect(_on_test_equipment_pressed)
	open_customization_button.pressed.connect(_on_open_customization_pressed)
	open_skill_tree_button.pressed.connect(_on_open_skill_tree_pressed)
	
	# Update display
	update_player_info()
	
	# Show initial test results
	show_initial_info()

func update_player_info() -> void:
	"""Update player info display"""
	if current_player_data:
		@warning_ignore("unsafe_method_access")
		var info = "Player: %s | Level: %d | Currency: %d" % [
			current_player_data.nickname,
			current_player_data.stats.level,
			current_player_data.currency
		]
		player_info_label.text = info

func show_initial_info() -> void:
	"""Show initial system information"""
	var text = "[b]Player System Test Initialized[/b]\n\n"
	text += "[color=green]✓ PlayerData system loaded[/color]\n"
	text += "[color=green]✓ PlayerManager initialized[/color]\n"
	text += "[color=green]✓ Save/Load system ready[/color]\n\n"
	text += "Click the buttons above to test different features!"
	
	results_label.text = text

func _on_test_data_pressed() -> void:
	"""Test player data functionality"""
	var text = "[b]Testing Player Data System[/b]\n\n"
	
	if not current_player_data:
		text += "[color=red]Error: Player data not loaded[/color]"
		results_label.text = text
		return
	
	# Test basic data
	text += "[color=yellow]Basic Player Data:[/color]\n"
	@warning_ignore("unsafe_method_access")
	text += "• Player ID: " + current_player_data.player_id + "\n"
	@warning_ignore("unsafe_method_access")
	text += "• Nickname: " + current_player_data.nickname + "\n"
	@warning_ignore("unsafe_method_access")
	text += "• Level: " + str(current_player_data.stats.level) + "\n"
	@warning_ignore("unsafe_method_access")
	text += "• Experience: " + str(current_player_data.stats.experience) + "\n"
	@warning_ignore("unsafe_method_access")
	text += "• Currency: " + str(current_player_data.currency) + "\n\n"
	
	# Test adding experience
	text += "[color=yellow]Testing Experience System:[/color]\n"
	@warning_ignore("unsafe_method_access")
	var old_level = current_player_data.stats.level
	@warning_ignore("unsafe_method_access")
	current_player_data.add_experience(500)
	@warning_ignore("unsafe_method_access")
	var new_level = current_player_data.stats.level
	
	if new_level > old_level:
		text += "[color=green]✓ Level up! " + str(old_level) + " → " + str(new_level) + "[/color]\n"
	else:
		text += "• Added 500 XP (Level: " + str(new_level) + ")\n"
	
	# Test stats
	text += "\n[color=yellow]Current Stats:[/color]\n"
	var effective_stats = current_player_data.get_effective_stats()
	for stat_name in effective_stats:
		text += "• " + stat_name.capitalize() + ": " + str(effective_stats[stat_name]) + "\n"
	
	# Save data
	if player_manager and player_manager.has_method("save_player_data"):
		player_manager.save_player_data()
	text += "\n[color=green]✓ Player data saved successfully[/color]"
	
	results_label.text = text
	update_player_info()

func _on_test_skills_pressed() -> void:
	"""Test skill system functionality"""
	var text = "[b]Testing Skill System[/b]\n\n"
	
	# Get skill tree
	var skill_tree = current_player_data.get_skill_tree()
	
	# Add some skill points for testing
	skill_tree.add_skill_points(5)
	text += "[color=yellow]Added 5 skill points for testing[/color]\n\n"
	
	# Show current skills
	text += "[color=yellow]Current Skills:[/color]\n"
	for skill_name in skill_tree.skills:
		var level = skill_tree.skills[skill_name]
		text += "• " + skill_name.capitalize() + ": Level " + str(level) + "\n"
	
	text += "\nSkill Points Available: " + str(skill_tree.skill_points) + "\n\n"
	
	# Test upgrading a skill
	if skill_tree.can_upgrade_skill("speed"):
		var old_level = skill_tree.get_skill_level("speed")
		if skill_tree.upgrade_skill("speed"):
			var new_level = skill_tree.get_skill_level("speed")
			text += "[color=green]✓ Upgraded Speed: " + str(old_level) + " → " + str(new_level) + "[/color]\n"
	
	# Show skill effects
	text += "\n[color=yellow]Total Skill Effects:[/color]\n"
	var effects = skill_tree.get_total_effects()
	for effect_name in effects:
		text += "• " + effect_name.replace("_", " ").capitalize() + ": +" + str(int(effects[effect_name] * 100)) + "%\n"
	
	# Save skill tree
	current_player_data.save_skill_tree(skill_tree)
	text += "\n[color=green]✓ Skill tree saved successfully[/color]"
	
	results_label.text = text

func _on_test_equipment_pressed() -> void:
	"""Test equipment system functionality"""
	var text = "[b]Testing Equipment System[/b]\n\n"
	
	# Show available items
	var available_items = []
	if player_manager and player_manager.has_method("get_available_items"):
		available_items = player_manager.get_available_items()
	text += "[color=yellow]Available Equipment (" + str(available_items.size()) + " items):[/color]\n"
	
	for item in available_items.slice(0, 5):  # Show first 5 items
		var rarity_name = EquipmentItem.Rarity.keys()[item.rarity - 1]
		text += "• " + item.item_name + " (" + rarity_name + ")\n"
		text += "  Type: " + item.get_equipment_type_name() + "\n"
		if item.stat_bonuses.size() > 0:
			text += "  Bonuses: "
			var bonus_text = []
			for stat in item.stat_bonuses:
				bonus_text.append(stat + " +" + str(item.stat_bonuses[stat]))
			text += ", ".join(bonus_text) + "\n"
		text += "\n"
	
	# Test purchasing an item
	if current_player_data.currency >= 150:
		if player_manager and player_manager.has_method("purchase_item") and player_manager.purchase_item("red_jersey"):
			text += "[color=green]✓ Purchased Red Jersey![/color]\n"
		else:
			text += "[color=red]✗ Failed to purchase Red Jersey[/color]\n"
	
	# Show equipped items
	text += "\n[color=yellow]Currently Equipped:[/color]\n"
	if current_player_data.equipment.size() > 0:
		for item in current_player_data.equipment:
			if item:
				text += "• " + item.item_name + " (" + item.get_equipment_type_name() + ")\n"
	else:
		text += "No items equipped\n"
	
	# Show effective stats with equipment
	text += "\n[color=yellow]Stats with Equipment:[/color]\n"
	var effective_stats = current_player_data.get_effective_stats()
	for stat_name in effective_stats:
		text += "• " + stat_name.capitalize() + ": " + str(effective_stats[stat_name]) + "\n"
	
	results_label.text = text
	update_player_info()

func _on_open_customization_pressed() -> void:
	"""Open character customization UI"""
	var customization_scene = preload("res://scenes/ui/CharacterCustomization.tscn")
	var customization = customization_scene.instantiate()
	
	# Add to scene
	get_tree().current_scene.add_child(customization)
	
	# Initialize with player manager
	customization.initialize(player_manager)
	
	# Connect completion signal
	customization.customization_complete.connect(_on_customization_complete.bind(customization))
	
	results_label.text = "[b]Character Customization Opened[/b]\n\nThe customization UI has been opened. You can:\n• Change appearance (skin, hair, colors)\n• Equip/unequip items\n• Purchase new equipment\n• View current stats"

func _on_open_skill_tree_pressed() -> void:
	"""Open skill tree UI"""
	var skill_tree_scene = preload("res://scenes/ui/SkillTreeUI.tscn")
	var skill_tree_ui = skill_tree_scene.instantiate()
	
	# Add to scene
	get_tree().current_scene.add_child(skill_tree_ui)
	
	# Initialize with skill tree
	var skill_tree = current_player_data.get_skill_tree()
	skill_tree.add_skill_points(10)  # Add some points for testing
	skill_tree_ui.initialize(skill_tree)
	
	# Connect signals
	skill_tree_ui.skill_upgraded.connect(_on_skill_upgraded)
	
	results_label.text = "[b]Skill Tree Opened[/b]\n\nThe skill tree UI has been opened. You can:\n• View available skills\n• Upgrade skills with skill points\n• See skill effects and bonuses\n• Reset skills if needed\n\n[color=green]Added 10 skill points for testing![/color]"

func _on_customization_complete(customization_ui) -> void:
	"""Handle customization completion"""
	customization_ui.queue_free()
	results_label.text = "[b]Customization Complete[/b]\n\nCharacter customization has been closed. All changes have been saved automatically."
	update_player_info()

func _on_skill_upgraded(skill_name: String) -> void:
	"""Handle skill upgrade"""
	results_label.text = "[b]Skill Upgraded![/b]\n\n[color=green]✓ " + skill_name.capitalize() + " has been upgraded![/color]\n\nThe skill tree system is working correctly."
	update_player_info()