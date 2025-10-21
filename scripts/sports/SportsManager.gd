extends Node
class_name SportsManager

## 运动项目注册和管理系统
## 负责动态加载和管理不同的运动模块

signal sport_registered(sport_type: GameManager.SportType)
signal sport_loaded(sport_type: GameManager.SportType)
signal sport_unloaded(sport_type: GameManager.SportType)
signal sport_changed(old_sport: GameManager.SportType, new_sport: GameManager.SportType)

var registered_sports: Dictionary = {}
var loaded_sports: Dictionary = {}
var current_sport: BaseSport = null
var current_sport_type: GameManager.SportType

## 运动类型到脚本路径的映射
const SPORT_SCRIPTS = {
	GameManager.SportType.BASKETBALL: "res://scripts/sports/BasketballSport.gd",
	GameManager.SportType.FOOTBALL: "res://scripts/sports/FootballSport.gd",
	GameManager.SportType.TENNIS: "res://scripts/sports/TennisSport.gd"
}

## 运动类型到配置资源的映射
const SPORT_CONFIGS = {
	GameManager.SportType.BASKETBALL: "res://resources/sports/basketball_config.tres",
	GameManager.SportType.FOOTBALL: "res://resources/sports/football_config.tres",
	GameManager.SportType.TENNIS: "res://resources/sports/tennis_config.tres"
}

func _ready() -> void:
	# 注册所有可用的运动项目
	register_all_sports()

## 注册所有运动项目
func register_all_sports() -> void:
	for sport_type in GameManager.SportType.values():
		register_sport(sport_type)

## 注册单个运动项目
func register_sport(sport_type: GameManager.SportType) -> bool:
	if sport_type in registered_sports:
		push_warning("Sport already registered: " + str(sport_type))
		return false
	
	var script_path = SPORT_SCRIPTS.get(sport_type, "")
	var config_path = SPORT_CONFIGS.get(sport_type, "")
	
	if script_path.is_empty():
		push_error("No script path defined for sport type: " + str(sport_type))
		return false
	
	# 验证脚本文件是否存在
	if not ResourceLoader.exists(script_path):
		push_error("Sport script not found: " + script_path)
		return false
	
	registered_sports[sport_type] = {
		"script_path": script_path,
		"config_path": config_path,
		"is_loaded": false
	}
	
	sport_registered.emit(sport_type)
	print("Registered sport: ", GameManager.get_sport_name(sport_type))
	return true

## 加载运动模块
func load_sport(sport_type: GameManager.SportType) -> BaseSport:
	if sport_type not in registered_sports:
		push_error("Sport not registered: " + str(sport_type))
		return null
	
	# 如果已经加载，直接返回
	if sport_type in loaded_sports:
		return loaded_sports[sport_type]
	
	var sport_info = registered_sports[sport_type]
	var script_path = sport_info["script_path"]
	var config_path = sport_info["config_path"]
	
	# 加载脚本
	var sport_script = load(script_path)
	if sport_script == null:
		push_error("Failed to load sport script: " + script_path)
		return null
	
	# 创建运动实例
	var sport_instance = sport_script.new()
	if not sport_instance is BaseSport:
		push_error("Sport script must extend BaseSport: " + script_path)
		sport_instance.queue_free()
		return null
	
	# 加载配置
	if not config_path.is_empty() and ResourceLoader.exists(config_path):
		var config = load(config_path)
		if config is SportConfig:
			sport_instance.sport_config = config
		else:
			push_warning("Invalid config resource: " + config_path)
	
	# 添加到场景树
	add_child(sport_instance)
	sport_instance.name = GameManager.get_sport_name(sport_type) + "Sport"
	
	# 缓存实例
	loaded_sports[sport_type] = sport_instance
	sport_info["is_loaded"] = true
	
	sport_loaded.emit(sport_type)
	print("Loaded sport: ", GameManager.get_sport_name(sport_type))
	return sport_instance

## 卸载运动模块
func unload_sport(sport_type: GameManager.SportType) -> void:
	if sport_type not in loaded_sports:
		return
	
	var sport_instance = loaded_sports[sport_type]
	
	# 如果是当前运动，先切换
	if current_sport == sport_instance:
		current_sport = null
		current_sport_type = GameManager.SportType.BASKETBALL  # 默认值
	
	# 从场景树移除并释放
	sport_instance.queue_free()
	loaded_sports.erase(sport_type)
	
	if sport_type in registered_sports:
		registered_sports[sport_type]["is_loaded"] = false
	
	sport_unloaded.emit(sport_type)
	print("Unloaded sport: ", GameManager.get_sport_name(sport_type))

## 切换到指定运动
func switch_to_sport(sport_type: GameManager.SportType) -> BaseSport:
	var old_sport_type = current_sport_type
	
	# 加载新运动
	var new_sport = load_sport(sport_type)
	if new_sport == null:
		push_error("Failed to switch to sport: " + str(sport_type))
		return null
	
	# 停止当前运动
	if current_sport != null and current_sport != new_sport:
		if current_sport.is_game_active:
			current_sport.end_game()
	
	# 切换运动
	current_sport = new_sport
	current_sport_type = sport_type
	
	sport_changed.emit(old_sport_type, sport_type)
	print("Switched to sport: ", GameManager.get_sport_name(sport_type))
	return current_sport

## 获取当前运动
func get_current_sport() -> BaseSport:
	return current_sport

## 获取当前运动类型
func get_current_sport_type() -> GameManager.SportType:
	return current_sport_type

## 检查运动是否已注册
func is_sport_registered(sport_type: GameManager.SportType) -> bool:
	return sport_type in registered_sports

## 检查运动是否已加载
func is_sport_loaded(sport_type: GameManager.SportType) -> bool:
	return sport_type in loaded_sports

## 获取所有已注册的运动类型
func get_registered_sports() -> Array:
	return registered_sports.keys()

## 获取所有已加载的运动类型
func get_loaded_sports() -> Array:
	return loaded_sports.keys()

## 预加载所有运动（可选）
func preload_all_sports() -> void:
	for sport_type in registered_sports.keys():
		load_sport(sport_type)

## 卸载所有运动
func unload_all_sports() -> void:
	for sport_type in loaded_sports.keys():
		unload_sport(sport_type)

## 获取运动信息
func get_sport_info(sport_type: GameManager.SportType) -> Dictionary:
	return registered_sports.get(sport_type, {})