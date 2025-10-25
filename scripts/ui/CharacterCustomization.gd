class_name CharacterCustomization
extends Control
## Character customization UI for appearance and equipment

signal customization_complete
signal appearance_changed(setting: String, value: int)

@onready var player_preview: Node2D = $PlayerPreview
@onready var appearance_panel: Control = $AppearancePanel
@onready var equipment_panel: Control = $EquipmentPanel
@onready var stats_panel: Control = $StatsPanel

# Appearance controls
@onready var skin_color_slider: HSlider = $AppearancePanel/SkinColorSlider
@onready var hair_style_slider: HSlider = $AppearancePanel/HairStyleSlider
@onready var hair_color_slider: HSlider = $AppearancePanel/HairColorSlider
@onready var jersey_color_slider: HSlider = $AppearancePanel/JerseyColorSlider
@onready var shorts_color_slider: HSlider = $AppearancePanel/ShortsColorSlider

# Equipment controls
@onready var equipment_list: ItemList = $EquipmentPanel/EquipmentList
@onready var equipped_items_container: VBoxContainer = $EquipmentPanel/EquippedItems
@onready var item_details: RichTextLabel = $EquipmentPanel/ItemDetails

# Stats display
@onready var stats_container: VBoxContainer = $StatsPanel/StatsContainer
@onready var currency_label: Label = $StatsPanel/CurrencyLabel

# References
var player_manager
var current_player_data
var available_items: Array = []

# Appearance options (20+ different combinations)
var skin_colors: Array[Color] = [
	Color(1.0, 0.8, 0.6),    # Light
	Color(0.9, 0.7, 0.5),    # Medium-Light
	Color(0.8, 0.6, 0.4),    # Medium
	Color(0.7, 0.5, 0.3),    # Medium-Dark
	Color(0.6, 0.4, 0.2)     # Dark
]

var hair_colors: Array[Color] = [
	Color.BLACK,
	Color(0.4, 0.2, 0.1),    # Brown
	Color(1.0, 0.8, 0.0),    # Blonde
	Color(0.8, 0.0, 0.0),    # Red
	Color.WHITE
]

var jersey_colors: Array[Color] = [
	Color.WHITE,
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE,
	Color.CYAN
]

func _ready() -> void:
	setup_ui()
	connect_signals()

func setup_ui() -> void:
	"""Initialize UI components"""
	# Setup sliders
	skin_color_slider.min_value = 0
	skin_color_slider.max_value = skin_colors.size() - 1
	skin_color_slider.step = 1
	
	hair_style_slider.min_value = 0
	hair_style_slider.max_value = 4  # 5 hair styles
	hair_style_slider.step = 1
	
	hair_color_slider.min_value = 0
	hair_color_slider.max_value = hair_colors.size() - 1
	hair_color_slider.step = 1
	
	jersey_color_slider.min_value = 0
	jersey_color_slider.max_value = jersey_colors.size() - 1
	jersey_color_slider.step = 1
	
	shorts_color_slider.min_value = 0
	shorts_color_slider.max_value = jersey_colors.size() - 1
	shorts_color_slider.step = 1

func connect_signals() -> void:
	"""Connect UI signals"""
	skin_color_slider.value_changed.connect(_on_skin_color_changed)
	hair_style_slider.value_changed.connect(_on_hair_style_changed)
	hair_color_slider.value_changed.connect(_on_hair_color_changed)
	jersey_color_slider.value_changed.connect(_on_jersey_color_changed)
	shorts_color_slider.value_changed.connect(_on_shorts_color_changed)
	
	equipment_list.item_selected.connect(_on_equipment_item_selected)

func initialize(manager) -> void:
	"""Initialize with player manager"""
	player_manager = manager
	current_player_data = manager.get_player_data()
	
	load_current_appearance()
	load_available_equipment()
	update_stats_display()
	update_currency_display()

func load_current_appearance() -> void:
	"""Load current player appearance settings"""
	if not current_player_data:
		return
	
	var appearance = current_player_data.appearance
	
	skin_color_slider.value = appearance.get("skin_color", 0)
	hair_style_slider.value = appearance.get("hair_style", 0)
	hair_color_slider.value = appearance.get("hair_color", 0)
	jersey_color_slider.value = appearance.get("jersey_color", 0)
	shorts_color_slider.value = appearance.get("shorts_color", 0)
	
	update_player_preview()

func load_available_equipment() -> void:
	"""Load available equipment items"""
	if not player_manager:
		return
	
	available_items = player_manager.get_available_items()
	update_equipment_list()
	update_equipped_items_display()

func update_equipment_list() -> void:
	"""Update the equipment list UI"""
	equipment_list.clear()
	
	for item in available_items:
		var item_text = item.item_name
		var is_unlocked = item.item_id in current_player_data.unlocked_items
		
		if not is_unlocked:
			item_text += " (Locked - " + str(item.cost) + " coins)"
		
		equipment_list.add_item(item_text)
		
		# Color code by rarity
		var item_index = equipment_list.get_item_count() - 1
		equipment_list.set_item_custom_bg_color(item_index, item.get_rarity_color())
		
		if not is_unlocked:
			equipment_list.set_item_disabled(item_index, true)

func update_equipped_items_display() -> void:
	"""Update display of currently equipped items"""
	# Clear existing displays
	for child in equipped_items_container.get_children():
		child.queue_free()
	
	# Show equipped items
	for item in current_player_data.equipment:
		if item:
			var item_label = Label.new()
			item_label.text = item.get_equipment_type_name() + ": " + item.item_name
			item_label.modulate = item.get_rarity_color()
			equipped_items_container.add_child(item_label)
			
			# Add unequip button
			var unequip_button = Button.new()
			unequip_button.text = "Unequip"
			unequip_button.pressed.connect(_on_unequip_item.bind(item.equipment_type))
			equipped_items_container.add_child(unequip_button)

func update_stats_display() -> void:
	"""Update the stats display"""
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()
	
	var effective_stats = current_player_data.get_effective_stats()
	
	for stat_name in effective_stats:
		var stat_label = Label.new()
		stat_label.text = stat_name.capitalize() + ": " + str(effective_stats[stat_name])
		stats_container.add_child(stat_label)

func update_currency_display() -> void:
	"""Update currency display"""
	if currency_label:
		currency_label.text = "Coins: " + str(current_player_data.currency)

func update_player_preview() -> void:
	"""Update the player preview with current appearance"""
	# This would update a 2D character preview
	# For now, we'll just print the changes
	print("Updated player preview with appearance: ", current_player_data.appearance)

func _on_skin_color_changed(value: float) -> void:
	"""Handle skin color change"""
	current_player_data.appearance.skin_color = int(value)
	player_manager.update_appearance_setting("skin_color", int(value))
	update_player_preview()
	appearance_changed.emit("skin_color", int(value))

func _on_hair_style_changed(value: float) -> void:
	"""Handle hair style change"""
	current_player_data.appearance.hair_style = int(value)
	player_manager.update_appearance_setting("hair_style", int(value))
	update_player_preview()
	appearance_changed.emit("hair_style", int(value))

func _on_hair_color_changed(value: float) -> void:
	"""Handle hair color change"""
	current_player_data.appearance.hair_color = int(value)
	player_manager.update_appearance_setting("hair_color", int(value))
	update_player_preview()
	appearance_changed.emit("hair_color", int(value))

func _on_jersey_color_changed(value: float) -> void:
	"""Handle jersey color change"""
	current_player_data.appearance.jersey_color = int(value)
	player_manager.update_appearance_setting("jersey_color", int(value))
	update_player_preview()
	appearance_changed.emit("jersey_color", int(value))

func _on_shorts_color_changed(value: float) -> void:
	"""Handle shorts color change"""
	current_player_data.appearance.shorts_color = int(value)
	player_manager.update_appearance_setting("shorts_color", int(value))
	update_player_preview()
	appearance_changed.emit("shorts_color", int(value))

func _on_equipment_item_selected(index: int) -> void:
	"""Handle equipment item selection"""
	if index < 0 or index >= available_items.size():
		return
	
	var selected_item = available_items[index]
	show_item_details(selected_item)

func show_item_details(item: EquipmentItem) -> void:
	"""Show details for selected item"""
	var details_text = "[b]" + item.item_name + "[/b]\n"
	details_text += item.description + "\n\n"
	details_text += "[b]Type:[/b] " + item.get_equipment_type_name() + "\n"
	details_text += "[b]Rarity:[/b] " + EquipmentItem.Rarity.keys()[item.rarity - 1] + "\n"
	
	if item.stat_bonuses.size() > 0:
		details_text += "[b]Stat Bonuses:[/b]\n"
		for stat in item.stat_bonuses:
			details_text += "  " + stat.capitalize() + ": +" + str(item.stat_bonuses[stat]) + "\n"
	
	var is_unlocked = item.item_id in current_player_data.unlocked_items
	if not is_unlocked:
		details_text += "\n[b]Cost:[/b] " + str(item.cost) + " coins"
	
	item_details.text = details_text
	
	# Add action buttons
	create_item_action_buttons(item, is_unlocked)

func create_item_action_buttons(item: EquipmentItem, is_unlocked: bool) -> void:
	"""Create action buttons for the selected item"""
	# Remove existing buttons
	var buttons_container = item_details.get_parent().get_node_or_null("ButtonsContainer")
	if buttons_container:
		buttons_container.queue_free()
	
	buttons_container = HBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	item_details.get_parent().add_child(buttons_container)
	
	if is_unlocked:
		# Check if already equipped
		var is_equipped = false
		for equipped_item in current_player_data.equipment:
			if equipped_item and equipped_item.item_id == item.item_id:
				is_equipped = true
				break
		
		if not is_equipped:
			var equip_button = Button.new()
			equip_button.text = "Equip"
			equip_button.pressed.connect(_on_equip_item.bind(item.item_id))
			buttons_container.add_child(equip_button)
	else:
		if current_player_data.can_afford(item.cost):
			var purchase_button = Button.new()
			purchase_button.text = "Purchase"
			purchase_button.pressed.connect(_on_purchase_item.bind(item.item_id))
			buttons_container.add_child(purchase_button)

func _on_equip_item(item_id: String) -> void:
	"""Handle item equipping"""
	if player_manager.equip_item(item_id):
		update_equipped_items_display()
		update_stats_display()
		print("Equipped item: ", item_id)
	else:
		print("Failed to equip item: ", item_id)

func _on_unequip_item(equipment_type: EquipmentItem.EquipmentType) -> void:
	"""Handle item unequipping"""
	if player_manager.unequip_item(equipment_type):
		update_equipped_items_display()
		update_stats_display()
		print("Unequipped item of type: ", equipment_type)

func _on_purchase_item(item_id: String) -> void:
	"""Handle item purchase"""
	if player_manager.purchase_item(item_id):
		update_currency_display()
		load_available_equipment()  # Refresh the list
		print("Purchased item: ", item_id)
	else:
		print("Failed to purchase item: ", item_id)

func _on_done_button_pressed() -> void:
	"""Handle customization completion"""
	customization_complete.emit()

func get_appearance_combinations_count() -> int:
	"""Get total number of appearance combinations"""
	return skin_colors.size() * 5 * hair_colors.size() * jersey_colors.size() * jersey_colors.size()

# Function to verify we meet the 20+ appearance options requirement
func verify_appearance_options() -> bool:
	var total_combinations = get_appearance_combinations_count()
	print("Total appearance combinations available: ", total_combinations)
	return total_combinations >= 20