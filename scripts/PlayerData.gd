class_name PlayerData
extends Resource
## Player data resource that stores player information and progress

@export var player_id: String = ""
@export var nickname: String = ""
@export var avatar_id: int = 0
@export var stats: Dictionary = {}
@export var equipment: Array[EquipmentItem] = []
@export var skills: Dictionary = {}
@export var appearance: Dictionary = {}
@export var unlocked_items: Array[String] = []
@export var currency: int = 0
@export var skill_tree_data: Dictionary = {}
@export var achievements: Array[String] = []

# Save file path
const SAVE_PATH = "user://player_data.save"

func _init(id: String = "", name: String = "") -> void:
	# Set default values if not provided
	if id.is_empty():
		player_id = "player_" + str(Time.get_unix_time_from_system())
	else:
		player_id = id
	
	if name.is_empty():
		nickname = "Player"
	else:
		nickname = name
	# Initialize default stats
	stats = {
		"games_played": 0,
		"games_won": 0,
		"total_score": 0,
		"level": 1,
		"experience": 0,
		"basketball_score": 0,
		"football_score": 0,
		"tennis_score": 0
	}
	# Initialize default skills
	skills = {
		"speed": 1,
		"strength": 1,
		"accuracy": 1,
		"stamina": 1
	}
	# Initialize appearance settings
	appearance = {
		"skin_color": 0,
		"hair_style": 0,
		"hair_color": 0,
		"jersey_color": 0,
		"shorts_color": 0
	}
	# Initialize with basic unlocked items
	unlocked_items = ["basic_jersey", "basic_shorts", "basic_shoes"]
	currency = 100

func get_win_rate() -> float:
	if stats.games_played == 0:
		return 0.0
	return float(stats.games_won) / float(stats.games_played)

func add_experience(exp: int) -> void:
	stats.experience += exp
	# Simple level calculation
	var new_level = 1 + (stats.experience / 1000)
	if new_level > stats.level:
		stats.level = new_level
		# Award currency for leveling up
		currency += new_level * 50
		print("Player ", nickname, " leveled up to level ", new_level)

func get_skill_total() -> int:
	var total = 0
	for skill_value in skills.values():
		total += skill_value
	return total

func get_effective_stats() -> Dictionary:
	"""Get stats including equipment bonuses and skill effects"""
	var effective_stats = skills.duplicate()
	
	# Apply equipment bonuses
	for item in equipment:
		if item != null:
			for stat_name in item.stat_bonuses:
				if stat_name in effective_stats:
					effective_stats[stat_name] += item.stat_bonuses[stat_name]
	
	# Apply skill tree effects
	var skill_tree = get_skill_tree()
	if skill_tree:
		var skill_effects = skill_tree.get_total_effects()
		for effect_name in skill_effects:
			# Map skill effects to stats
			match effect_name:
				"movement_speed":
					effective_stats["speed"] = int(effective_stats.get("speed", 1) * (1.0 + skill_effects[effect_name]))
				"shot_power", "tackle_force":
					effective_stats["strength"] = int(effective_stats.get("strength", 1) * (1.0 + skill_effects[effect_name]))
				"shot_accuracy", "pass_accuracy":
					effective_stats["accuracy"] = int(effective_stats.get("accuracy", 1) * (1.0 + skill_effects[effect_name]))
				"max_stamina", "stamina_recovery":
					effective_stats["stamina"] = int(effective_stats.get("stamina", 1) * (1.0 + skill_effects[effect_name]))
	
	return effective_stats

func equip_item(item: EquipmentItem) -> bool:
	"""Equip an item, replacing any existing item of the same type"""
	if not item or item.item_id not in unlocked_items:
		return false
	
	# Remove existing item of same type
	for i in range(equipment.size()):
		if equipment[i] != null and equipment[i].equipment_type == item.equipment_type:
			equipment.remove_at(i)
			break
	
	equipment.append(item)
	return true

func unequip_item(equipment_type: EquipmentItem.EquipmentType) -> bool:
	"""Remove equipped item of specified type"""
	for i in range(equipment.size()):
		if equipment[i] != null and equipment[i].equipment_type == equipment_type:
			equipment.remove_at(i)
			return true
	return false

func unlock_item(item_id: String) -> void:
	"""Unlock a new item for the player"""
	if item_id not in unlocked_items:
		unlocked_items.append(item_id)

func can_afford(cost: int) -> bool:
	"""Check if player has enough currency"""
	return currency >= cost

func spend_currency(amount: int) -> bool:
	"""Spend currency if available"""
	if can_afford(amount):
		currency -= amount
		return true
	return false

func get_skill_tree():
	"""Get or create skill tree instance"""
	var skill_tree_script = preload("res://scripts/SkillTree.gd")
	var skill_tree = skill_tree_script.new()
	
	# Load saved skill tree data
	if skill_tree_data.has("skills"):
		skill_tree.skills = skill_tree_data.skills
	if skill_tree_data.has("skill_points"):
		skill_tree.skill_points = skill_tree_data.skill_points
	
	return skill_tree

func save_skill_tree(skill_tree) -> void:
	"""Save skill tree data"""
	skill_tree_data = {
		"skills": skill_tree.skills,
		"skill_points": skill_tree.skill_points
	}

func add_skill_points(points: int) -> void:
	"""Add skill points for upgrades"""
	var skill_tree = get_skill_tree()
	skill_tree.add_skill_points(points)
	save_skill_tree(skill_tree)

func unlock_achievement(achievement_id: String) -> bool:
	"""Unlock an achievement"""
	if achievement_id not in achievements:
		achievements.append(achievement_id)
		return true
	return false

func save_data() -> bool:
	"""Save player data to file"""
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("Failed to open save file for writing")
		return false
	
	var save_data = {
		"player_id": player_id,
		"nickname": nickname,
		"avatar_id": avatar_id,
		"stats": stats,
		"skills": skills,
		"appearance": appearance,
		"unlocked_items": unlocked_items,
		"currency": currency,
		"skill_tree_data": skill_tree_data,
		"achievements": achievements,
		"equipment": []
	}
	
	# Serialize equipment
	for item in equipment:
		if item != null:
			save_data.equipment.append({
				"item_id": item.item_id,
				"item_name": item.item_name,
				"equipment_type": item.equipment_type,
				"stat_bonuses": item.stat_bonuses,
				"icon_path": item.icon_path,
				"rarity": item.rarity
			})
	
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	return true

static func load_data() -> PlayerData:
	"""Load player data from file"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, creating new player data")
		return PlayerData.new()
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		print("Failed to open save file for reading")
		return PlayerData.new()
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save file")
		return PlayerData.new()
	
	var save_data = json.data
	var player_data = PlayerData.new()
	
	# Load basic data
	player_data.player_id = save_data.get("player_id", "")
	player_data.nickname = save_data.get("nickname", "")
	player_data.avatar_id = save_data.get("avatar_id", 0)
	player_data.stats = save_data.get("stats", {})
	player_data.skills = save_data.get("skills", {})
	player_data.appearance = save_data.get("appearance", {})
	var unlocked_items_data = save_data.get("unlocked_items", [])
	player_data.unlocked_items.clear()
	for item_id in unlocked_items_data:
		player_data.unlocked_items.append(item_id)
	player_data.currency = save_data.get("currency", 0)
	player_data.skill_tree_data = save_data.get("skill_tree_data", {})
	var achievements_data = save_data.get("achievements", [])
	player_data.achievements.clear()
	for achievement_id in achievements_data:
		player_data.achievements.append(achievement_id)
	
	# Load equipment
	var equipment_data = save_data.get("equipment", [])
	for item_data in equipment_data:
		var item = EquipmentItem.new()
		item.item_id = item_data.get("item_id", "")
		item.item_name = item_data.get("item_name", "")
		item.equipment_type = item_data.get("equipment_type", EquipmentItem.EquipmentType.SHOES)
		item.stat_bonuses = item_data.get("stat_bonuses", {})
		item.icon_path = item_data.get("icon_path", "")
		item.rarity = item_data.get("rarity", 1)
		player_data.equipment.append(item)
	
	return player_data