class_name SkillTree
extends Resource
## Skill tree system for player progression

signal skill_upgraded(skill_name: String, new_level: int)
signal skill_unlocked(skill_name: String)

@export var skills: Dictionary = {}
@export var skill_points: int = 0

# Skill definitions
var skill_definitions: Dictionary = {
	"speed": {
		"name": "Speed",
		"description": "Increases movement speed",
		"max_level": 10,
		"base_cost": 1,
		"cost_multiplier": 1.2,
		"effects": {
			"movement_speed": 0.1  # 10% per level
		},
		"prerequisites": []
	},
	"strength": {
		"name": "Strength",
		"description": "Increases shooting power and tackling force",
		"max_level": 10,
		"base_cost": 1,
		"cost_multiplier": 1.2,
		"effects": {
			"shot_power": 0.15,
			"tackle_force": 0.1
		},
		"prerequisites": []
	},
	"accuracy": {
		"name": "Accuracy",
		"description": "Improves shooting and passing precision",
		"max_level": 10,
		"base_cost": 1,
		"cost_multiplier": 1.2,
		"effects": {
			"shot_accuracy": 0.1,
			"pass_accuracy": 0.08
		},
		"prerequisites": []
	},
	"stamina": {
		"name": "Stamina",
		"description": "Increases endurance and reduces fatigue",
		"max_level": 10,
		"base_cost": 1,
		"cost_multiplier": 1.2,
		"effects": {
			"max_stamina": 0.2,
			"stamina_recovery": 0.15
		},
		"prerequisites": []
	},
	"agility": {
		"name": "Agility",
		"description": "Improves dodging and quick movements",
		"max_level": 8,
		"base_cost": 2,
		"cost_multiplier": 1.3,
		"effects": {
			"dodge_chance": 0.05,
			"acceleration": 0.12
		},
		"prerequisites": ["speed"]
	},
	"power_shot": {
		"name": "Power Shot",
		"description": "Unlocks devastating power shots",
		"max_level": 5,
		"base_cost": 3,
		"cost_multiplier": 1.5,
		"effects": {
			"power_shot_damage": 0.3,
			"power_shot_range": 0.2
		},
		"prerequisites": ["strength", "accuracy"]
	},
	"leadership": {
		"name": "Leadership",
		"description": "Boosts team performance when playing with others",
		"max_level": 5,
		"base_cost": 4,
		"cost_multiplier": 1.4,
		"effects": {
			"team_speed_bonus": 0.05,
			"team_accuracy_bonus": 0.03
		},
		"prerequisites": ["stamina", "agility"]
	},
	"clutch_performer": {
		"name": "Clutch Performer",
		"description": "Performs better under pressure",
		"max_level": 3,
		"base_cost": 5,
		"cost_multiplier": 1.6,
		"effects": {
			"pressure_resistance": 0.2,
			"clutch_accuracy": 0.15
		},
		"prerequisites": ["power_shot", "leadership"]
	}
}

func _init() -> void:
	# Initialize basic skills
	for skill_name in ["speed", "strength", "accuracy", "stamina"]:
		skills[skill_name] = 1  # Start at level 1
	
	skill_points = 0

func get_skill_level(skill_name: String) -> int:
	"""Get current level of a skill"""
	return skills.get(skill_name, 0)

func can_upgrade_skill(skill_name: String) -> bool:
	"""Check if a skill can be upgraded"""
	if not skill_definitions.has(skill_name):
		return false
	
	var skill_def = skill_definitions[skill_name]
	var current_level = get_skill_level(skill_name)
	
	# Check max level
	if current_level >= skill_def.max_level:
		return false
	
	# Check skill points
	var cost = get_upgrade_cost(skill_name)
	if skill_points < cost:
		return false
	
	# Check prerequisites
	for prereq in skill_def.prerequisites:
		if get_skill_level(prereq) == 0:
			return false
	
	return true

func get_upgrade_cost(skill_name: String) -> int:
	"""Get cost to upgrade a skill to next level"""
	if not skill_definitions.has(skill_name):
		return 0
	
	var skill_def = skill_definitions[skill_name]
	var current_level = get_skill_level(skill_name)
	
	if current_level == 0:
		# Unlocking the skill
		return skill_def.base_cost
	else:
		# Upgrading existing skill
		return int(skill_def.base_cost * pow(skill_def.cost_multiplier, current_level))

func upgrade_skill(skill_name: String) -> bool:
	"""Upgrade a skill if possible"""
	if not can_upgrade_skill(skill_name):
		return false
	
	var cost = get_upgrade_cost(skill_name)
	skill_points -= cost
	
	var current_level = get_skill_level(skill_name)
	var new_level = current_level + 1
	
	if current_level == 0:
		# Unlocking new skill
		skills[skill_name] = 1
		skill_unlocked.emit(skill_name)
	else:
		# Upgrading existing skill
		skills[skill_name] = new_level
	
	skill_upgraded.emit(skill_name, new_level)
	return true

func add_skill_points(points: int) -> void:
	"""Add skill points for spending"""
	skill_points += points

func get_skill_effects(skill_name: String) -> Dictionary:
	"""Get the effects of a skill at its current level"""
	if not skill_definitions.has(skill_name):
		return {}
	
	var skill_def = skill_definitions[skill_name]
	var current_level = get_skill_level(skill_name)
	
	if current_level == 0:
		return {}
	
	var effects = {}
	for effect_name in skill_def.effects:
		var base_value = skill_def.effects[effect_name]
		effects[effect_name] = base_value * current_level
	
	return effects

func get_total_effects() -> Dictionary:
	"""Get combined effects from all skills"""
	var total_effects = {}
	
	for skill_name in skills:
		var skill_effects = get_skill_effects(skill_name)
		for effect_name in skill_effects:
			if effect_name in total_effects:
				total_effects[effect_name] += skill_effects[effect_name]
			else:
				total_effects[effect_name] = skill_effects[effect_name]
	
	return total_effects

func get_available_skills() -> Array:
	"""Get list of skills that can be unlocked or upgraded"""
	var available = []
	
	for skill_name in skill_definitions:
		if can_upgrade_skill(skill_name):
			available.append(skill_name)
	
	return available

func get_skill_tree_data() -> Dictionary:
	"""Get complete skill tree data for UI display"""
	var tree_data = {}
	
	for skill_name in skill_definitions:
		var skill_def = skill_definitions[skill_name]
		var current_level = get_skill_level(skill_name)
		
		tree_data[skill_name] = {
			"definition": skill_def,
			"current_level": current_level,
			"can_upgrade": can_upgrade_skill(skill_name),
			"upgrade_cost": get_upgrade_cost(skill_name),
			"effects": get_skill_effects(skill_name),
			"is_unlocked": current_level > 0
		}
	
	return tree_data

func reset_skills() -> int:
	"""Reset all skills and return refunded skill points"""
	var refunded_points = 0
	
	# Calculate refunded points
	for skill_name in skills:
		var level = skills[skill_name]
		if level > 1:  # Don't refund base level
			var skill_def = skill_definitions[skill_name]
			for i in range(1, level):
				refunded_points += int(skill_def.base_cost * pow(skill_def.cost_multiplier, i))
	
	# Reset to base levels
	for skill_name in ["speed", "strength", "accuracy", "stamina"]:
		skills[skill_name] = 1
	
	# Remove advanced skills
	for skill_name in skills.keys():
		if skill_name not in ["speed", "strength", "accuracy", "stamina"]:
			skills.erase(skill_name)
	
	skill_points += refunded_points
	return refunded_points

func get_skill_description(skill_name: String) -> String:
	"""Get formatted description of a skill"""
	if not skill_definitions.has(skill_name):
		return ""
	
	var skill_def = skill_definitions[skill_name]
	var current_level = get_skill_level(skill_name)
	var description = skill_def.description
	
	if current_level > 0:
		description += "\n\nCurrent Level: " + str(current_level) + "/" + str(skill_def.max_level)
		
		var effects = get_skill_effects(skill_name)
		if effects.size() > 0:
			description += "\nEffects:"
			for effect_name in effects:
				var value = effects[effect_name]
				description += "\n  " + effect_name.replace("_", " ").capitalize() + ": +" + str(int(value * 100)) + "%"
	
	if can_upgrade_skill(skill_name):
		description += "\n\nUpgrade Cost: " + str(get_upgrade_cost(skill_name)) + " skill points"
	
	return description