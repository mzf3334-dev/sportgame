extends Resource
class_name SportConfig

## 运动配置资源类
## 存储每种运动的配置信息和规则

@export var sport_name: String = ""
@export var sport_type: GameManager.SportType
@export var field_size: Vector2 = Vector2(800, 600)
@export var player_count: int = 2
@export var max_players: int = 4
@export var game_duration: float = 300.0  # 5分钟默认
@export var rules: Dictionary = {}
@export var assets_path: String = ""
@export var field_scene_path: String = ""

## 物理设置
@export_group("Physics Settings")
@export var gravity: Vector2 = Vector2(0, 980)
@export var ball_bounce: float = 0.8
@export var ball_friction: float = 0.1

## 游戏规则设置
@export_group("Game Rules")
@export var scoring_rules: Dictionary = {}
@export var win_conditions: Dictionary = {}
@export var special_rules: Array[String] = []

## 视觉设置
@export_group("Visual Settings")
@export var field_color: Color = Color.GREEN
@export var ui_theme_path: String = ""

## 音频设置
@export_group("Audio Settings")
@export var background_music_path: String = ""
@export var sound_effects: Dictionary = {}

func _init():
	# 设置默认值
	rules = {
		"time_limit": true,
		"score_limit": 0,  # 0表示无限制
		"overtime_enabled": false
	}
	
	scoring_rules = {
		"basic_score": 1,
		"bonus_multiplier": 1.0
	}
	
	win_conditions = {
		"score_to_win": 10,
		"time_based": true
	}
	
	sound_effects = {
		"score": "",
		"whistle": "",
		"crowd_cheer": ""
	}

## 验证配置是否有效
func is_valid() -> bool:
	if sport_name.is_empty():
		push_error("Sport name cannot be empty")
		return false
	
	if field_size.x <= 0 or field_size.y <= 0:
		push_error("Field size must be positive")
		return false
	
	if player_count <= 0 or player_count > max_players:
		push_error("Invalid player count")
		return false
	
	if game_duration <= 0:
		push_error("Game duration must be positive")
		return false
	
	return true

## 获取特定规则
func get_rule(rule_name: String, default_value = null):
	return rules.get(rule_name, default_value)

## 设置规则
func set_rule(rule_name: String, value) -> void:
	rules[rule_name] = value

## 获取音效路径
func get_sound_effect(effect_name: String) -> String:
	return sound_effects.get(effect_name, "")

## 创建运动配置的副本
func duplicate_config() -> SportConfig:
	var new_config = SportConfig.new()
	new_config.sport_name = sport_name
	new_config.sport_type = sport_type
	new_config.field_size = field_size
	new_config.player_count = player_count
	new_config.max_players = max_players
	new_config.game_duration = game_duration
	new_config.rules = rules.duplicate()
	new_config.assets_path = assets_path
	new_config.field_scene_path = field_scene_path
	new_config.gravity = gravity
	new_config.ball_bounce = ball_bounce
	new_config.ball_friction = ball_friction
	new_config.scoring_rules = scoring_rules.duplicate()
	new_config.win_conditions = win_conditions.duplicate()
	new_config.special_rules = special_rules.duplicate()
	new_config.field_color = field_color
	new_config.ui_theme_path = ui_theme_path
	new_config.background_music_path = background_music_path
	new_config.sound_effects = sound_effects.duplicate()
	
	return new_config