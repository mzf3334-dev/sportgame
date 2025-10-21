class_name PlayerData
extends Resource
## Player data resource that stores player information and progress

@export var player_id: String = ""
@export var nickname: String = ""
@export var avatar_id: int = 0
@export var stats: Dictionary = {}
@export var equipment: Array[EquipmentItem] = []
@export var skills: Dictionary = {}

func _init(id: String = "", name: String = "") -> void:
	player_id = id
	nickname = name
	# Initialize default stats
	stats = {
		"games_played": 0,
		"games_won": 0,
		"total_score": 0,
		"level": 1,
		"experience": 0
	}
	# Initialize default skills
	skills = {
		"speed": 1,
		"strength": 1,
		"accuracy": 1,
		"stamina": 1
	}

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
		print("Player ", nickname, " leveled up to level ", new_level)

func get_skill_total() -> int:
	var total = 0
	for skill_value in skills.values():
		total += skill_value
	return total