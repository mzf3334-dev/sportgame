class_name PlayerManager
extends Node
## Manages player data, progression, and persistence

signal player_data_loaded(player_data: PlayerData)
signal player_leveled_up(new_level: int)
signal item_unlocked(item_id: String)

var current_player_data: PlayerData
var equipment_database: Dictionary = {}

func _ready() -> void:
	load_equipment_database()
	load_player_data()

func load_player_data() -> void:
	"""Load player data from save file"""
	current_player_data = PlayerData.load_data()
	
	# If no save exists, create default player
	if not current_player_data or current_player_data.player_id.is_empty():
		current_player_data = PlayerData.new()
		current_player_data.player_id = generate_player_id()
		current_player_data.nickname = "Player"
		save_player_data()
	
	player_data_loaded.emit(current_player_data)

func save_player_data() -> bool:
	"""Save current player data"""
	if current_player_data:
		return current_player_data.save_data()
	return false

func generate_player_id() -> String:
	"""Generate unique player ID"""
	return "player_" + str(Time.get_unix_time_from_system())

func get_player_data() -> PlayerData:
	"""Get current player data"""
	return current_player_data

func add_experience(amount: int) -> void:
	"""Add experience to player and handle level ups"""
	if not current_player_data:
		return
	
	var old_level = current_player_data.stats.level
	current_player_data.add_experience(amount)
	var new_level = current_player_data.stats.level
	
	if new_level > old_level:
		player_leveled_up.emit(new_level)
		unlock_level_rewards(new_level)
	
	save_player_data()

func unlock_level_rewards(level: int) -> void:
	"""Unlock items and rewards for reaching a level"""
	var rewards = get_level_rewards(level)
	
	for reward in rewards:
		match reward.type:
			"item":
				unlock_item(reward.item_id)
			"currency":
				current_player_data.currency += reward.amount

func get_level_rewards(level: int) -> Array:
	"""Get rewards for a specific level"""
	var rewards = []
	
	# Define level-based rewards
	match level:
		2:
			rewards.append({"type": "item", "item_id": "red_jersey"})
		3:
			rewards.append({"type": "currency", "amount": 200})
		5:
			rewards.append({"type": "item", "item_id": "speed_shoes"})
		10:
			rewards.append({"type": "item", "item_id": "pro_gloves"})
	
	return rewards

func unlock_item(item_id: String) -> void:
	"""Unlock an item for the player"""
	if current_player_data and item_id not in current_player_data.unlocked_items:
		current_player_data.unlock_item(item_id)
		item_unlocked.emit(item_id)
		save_player_data()

func purchase_item(item_id: String) -> bool:
	"""Purchase an item with currency"""
	if not current_player_data or not equipment_database.has(item_id):
		return false
	
	var item_data = equipment_database[item_id]
	var cost = item_data.get("cost", 0)
	
	if current_player_data.can_afford(cost):
		if current_player_data.spend_currency(cost):
			unlock_item(item_id)
			return true
	
	return false

func equip_item(item_id: String) -> bool:
	"""Equip an item on the player"""
	if not current_player_data or item_id not in current_player_data.unlocked_items:
		return false
	
	if not equipment_database.has(item_id):
		return false
	
	var item_data = equipment_database[item_id]
	var item = create_equipment_item(item_data)
	
	var success = current_player_data.equip_item(item)
	if success:
		save_player_data()
	
	return success

func unequip_item(equipment_type: EquipmentItem.EquipmentType) -> bool:
	"""Unequip an item of the specified type"""
	if not current_player_data:
		return false
	
	var success = current_player_data.unequip_item(equipment_type)
	if success:
		save_player_data()
	
	return success

func create_equipment_item(item_data: Dictionary) -> EquipmentItem:
	"""Create an EquipmentItem from database data"""
	var item = EquipmentItem.new()
	item.item_id = item_data.get("id", "")
	item.item_name = item_data.get("name", "")
	item.description = item_data.get("description", "")
	item.equipment_type = item_data.get("type", EquipmentItem.EquipmentType.SHOES)
	item.stat_bonuses = item_data.get("stat_bonuses", {})
	item.icon_path = item_data.get("icon_path", "")
	item.rarity = item_data.get("rarity", EquipmentItem.Rarity.COMMON)
	item.cost = item_data.get("cost", 0)
	item.unlock_level = item_data.get("unlock_level", 1)
	item.visual_data = item_data.get("visual_data", {})
	return item

func load_equipment_database() -> void:
	"""Load equipment database from resources"""
	# This would typically load from a JSON file or resource
	# For now, we'll create a basic database in code
	equipment_database = {
		"basic_jersey": {
			"id": "basic_jersey",
			"name": "Basic Jersey",
			"description": "Standard team jersey",
			"type": EquipmentItem.EquipmentType.JERSEY,
			"stat_bonuses": {},
			"icon_path": "res://assets/icons/basic_jersey.png",
			"rarity": EquipmentItem.Rarity.COMMON,
			"cost": 0,
			"unlock_level": 1,
			"visual_data": {"color": Color.WHITE}
		},
		"basic_shorts": {
			"id": "basic_shorts",
			"name": "Basic Shorts",
			"description": "Standard team shorts",
			"type": EquipmentItem.EquipmentType.SHORTS,
			"stat_bonuses": {},
			"icon_path": "res://assets/icons/basic_shorts.png",
			"rarity": EquipmentItem.Rarity.COMMON,
			"cost": 0,
			"unlock_level": 1,
			"visual_data": {"color": Color.WHITE}
		},
		"basic_shoes": {
			"id": "basic_shoes",
			"name": "Basic Shoes",
			"description": "Standard athletic shoes",
			"type": EquipmentItem.EquipmentType.SHOES,
			"stat_bonuses": {"speed": 1},
			"icon_path": "res://assets/icons/basic_shoes.png",
			"rarity": EquipmentItem.Rarity.COMMON,
			"cost": 0,
			"unlock_level": 1,
			"visual_data": {"color": Color.WHITE}
		},
		"red_jersey": {
			"id": "red_jersey",
			"name": "Red Team Jersey",
			"description": "Stylish red team jersey",
			"type": EquipmentItem.EquipmentType.JERSEY,
			"stat_bonuses": {"strength": 1},
			"icon_path": "res://assets/icons/red_jersey.png",
			"rarity": EquipmentItem.Rarity.UNCOMMON,
			"cost": 150,
			"unlock_level": 2,
			"visual_data": {"color": Color.RED}
		},
		"speed_shoes": {
			"id": "speed_shoes",
			"name": "Speed Runners",
			"description": "Lightweight shoes for maximum speed",
			"type": EquipmentItem.EquipmentType.SHOES,
			"stat_bonuses": {"speed": 3, "stamina": 1},
			"icon_path": "res://assets/icons/speed_shoes.png",
			"rarity": EquipmentItem.Rarity.RARE,
			"cost": 300,
			"unlock_level": 5,
			"visual_data": {"color": Color.CYAN}
		},
		"pro_gloves": {
			"id": "pro_gloves",
			"name": "Pro Gloves",
			"description": "Professional grade gloves for better grip",
			"type": EquipmentItem.EquipmentType.GLOVES,
			"stat_bonuses": {"accuracy": 2, "strength": 1},
			"icon_path": "res://assets/icons/pro_gloves.png",
			"rarity": EquipmentItem.Rarity.EPIC,
			"cost": 500,
			"unlock_level": 10,
			"visual_data": {"color": Color.BLACK}
		}
	}

func get_available_items() -> Array:
	"""Get all items available for purchase/unlock"""
	var available_items = []
	
	for item_id in equipment_database:
		var item_data = equipment_database[item_id]
		if current_player_data.stats.level >= item_data.get("unlock_level", 1):
			available_items.append(create_equipment_item(item_data))
	
	return available_items

func get_unlocked_items() -> Array:
	"""Get all items the player has unlocked"""
	var unlocked_items = []
	
	for item_id in current_player_data.unlocked_items:
		if equipment_database.has(item_id):
			unlocked_items.append(create_equipment_item(equipment_database[item_id]))
	
	return unlocked_items

func update_appearance_setting(setting_name: String, value: int) -> void:
	"""Update a player appearance setting"""
	if current_player_data:
		current_player_data.appearance[setting_name] = value
		save_player_data()

func reset_player_data() -> void:
	"""Reset player data to defaults (for testing/debugging)"""
	current_player_data = PlayerData.new()
	current_player_data.player_id = generate_player_id()
	current_player_data.nickname = "Player"
	save_player_data()
	player_data_loaded.emit(current_player_data)