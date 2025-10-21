extends Node
class_name BaseSport

## 运动模块抽象基类
## 定义所有运动项目的通用接口和行为

signal sport_initialized
signal game_started
signal game_ended(result: Dictionary)
signal score_changed(score_data: Dictionary)

@export var sport_config: SportConfig
var is_initialized: bool = false
var current_players: Array[Node] = []
var game_time: float = 0.0
var is_game_active: bool = false

## 抽象方法 - 子类必须实现
func initialize_sport() -> void:
	push_error("initialize_sport() must be implemented by subclass")

func get_rules() -> Dictionary:
	push_error("get_rules() must be implemented by subclass")
	return {}

func create_field() -> Node2D:
	push_error("create_field() must be implemented by subclass")
	return null

func setup_players(player_count: int) -> Array[Node]:
	push_error("setup_players() must be implemented by subclass")
	return []

func start_game() -> void:
	push_error("start_game() must be implemented by subclass")

func end_game() -> void:
	push_error("end_game() must be implemented by subclass")

func update_game_logic(delta: float) -> void:
	push_error("update_game_logic() must be implemented by subclass")

## 通用方法 - 可被子类重写
func _ready() -> void:
	if sport_config == null:
		push_error("SportConfig is required for " + get_class())
		return
	
	call_deferred("initialize_sport")

func _process(delta: float) -> void:
	if is_game_active:
		game_time += delta
		update_game_logic(delta)

## 通用游戏管理方法
func add_player(player: Node) -> void:
	if player not in current_players:
		current_players.append(player)

func remove_player(player: Node) -> void:
	if player in current_players:
		current_players.erase(player)

func get_player_count() -> int:
	return current_players.size()

func get_game_time() -> float:
	return game_time

func reset_game() -> void:
	game_time = 0.0
	is_game_active = false
	current_players.clear()

## 获取运动类型名称
func get_sport_name() -> String:
	if sport_config:
		return sport_config.sport_name
	return "Unknown Sport"

## 验证游戏状态
func is_valid_game_state() -> bool:
	return is_initialized and sport_config != null

## 获取当前比分（子类可重写）
func get_current_score() -> Dictionary:
	return {}