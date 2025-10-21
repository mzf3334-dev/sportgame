extends BaseSport
class_name BasketballSport

## 篮球运动模块
## 实现篮球特有的游戏规则和物理系统

signal basket_scored(player_id: String, points: int, position: Vector2)
signal rebound_occurred(player_id: String)
signal foul_committed(player_id: String, foul_type: String)

var basketball_field: Node2D
var basketball: RigidBody2D
var hoops: Array[Area2D] = []
var score_data: Dictionary = {}
var last_shot_player: String = ""
var shot_clock: float = 24.0  # 24秒进攻时间
var current_shot_clock: float = 24.0

## 篮球特有的游戏状态
enum BasketballState {
	TIPOFF,      # 跳球
	PLAYING,     # 正常比赛
	FREE_THROW,  # 罚球
	TIMEOUT      # 暂停
}

var basketball_state: BasketballState = BasketballState.TIPOFF

func initialize_sport() -> void:
	if not sport_config:
		push_error("Basketball config is required")
		return
	
	# 初始化比分
	score_data = {
		"player1": 0,
		"player2": 0,
		"quarter": 1,
		"fouls": {"player1": 0, "player2": 0}
	}
	
	# 创建篮球场地
	basketball_field = create_field()
	if basketball_field:
		add_child(basketball_field)
	
	# 创建篮球
	create_basketball()
	
	# 设置物理参数
	setup_physics()
	
	is_initialized = true
	sport_initialized.emit()
	print("Basketball sport initialized")

func get_rules() -> Dictionary:
	return {
		"game_duration": sport_config.game_duration,
		"quarters": 4,
		"quarter_duration": sport_config.game_duration / 4,
		"shot_clock": 24.0,
		"three_point_line": true,
		"free_throws": true,
		"fouls_limit": 6,
		"overtime_duration": 300.0,  # 5分钟加时
		"scoring": {
			"field_goal": 2,
			"three_pointer": 3,
			"free_throw": 1
		}
	}

func create_field() -> Node2D:
	var field = Node2D.new()
	field.name = "BasketballField"
	
	# 创建场地边界
	var field_bounds = StaticBody2D.new()
	field_bounds.name = "FieldBounds"
	field.add_child(field_bounds)
	
	# 场地碰撞形状
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = sport_config.field_size
	collision_shape.shape = rect_shape
	field_bounds.add_child(collision_shape)
	
	# 创建篮筐
	create_hoops(field)
	
	# 创建三分线（视觉）
	create_three_point_lines(field)
	
	# 创建罚球线
	create_free_throw_lines(field)
	
	return field

func create_hoops(field: Node2D) -> void:
	# 左侧篮筐
	var left_hoop = create_single_hoop(Vector2(50, sport_config.field_size.y / 2), "left")
	field.add_child(left_hoop)
	hoops.append(left_hoop)
	
	# 右侧篮筐
	var right_hoop = create_single_hoop(Vector2(sport_config.field_size.x - 50, sport_config.field_size.y / 2), "right")
	field.add_child(right_hoop)
	hoops.append(right_hoop)

func create_single_hoop(pos: Vector2, side: String) -> Area2D:
	var hoop = Area2D.new()
	hoop.name = side.capitalize() + "Hoop"
	hoop.position = pos
	
	# 篮筐碰撞检测
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 25
	collision.shape = circle_shape
	hoop.add_child(collision)
	
	# 连接得分信号
	hoop.body_entered.connect(_on_hoop_entered.bind(side))
	
	# 篮筐视觉（简单的圆形）
	var visual = ColorRect.new()
	visual.size = Vector2(50, 50)
	visual.position = Vector2(-25, -25)
	visual.color = Color.ORANGE
	hoop.add_child(visual)
	
	return hoop

func create_three_point_lines(field: Node2D) -> void:
	# 创建三分线标记（简化版）
	var three_point_marker = Node2D.new()
	three_point_marker.name = "ThreePointLines"
	field.add_child(three_point_marker)
	
	# 这里可以添加更详细的三分线绘制逻辑

func create_free_throw_lines(field: Node2D) -> void:
	# 创建罚球线标记
	var free_throw_marker = Node2D.new()
	free_throw_marker.name = "FreeThrowLines"
	field.add_child(free_throw_marker)

func create_basketball() -> void:
	basketball = RigidBody2D.new()
	basketball.name = "Basketball"
	basketball.position = Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2)
	
	# 篮球碰撞形状
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 15
	collision.shape = circle_shape
	basketball.add_child(collision)
	
	# 篮球视觉
	var visual = ColorRect.new()
	visual.size = Vector2(30, 30)
	visual.position = Vector2(-15, -15)
	visual.color = Color.ORANGE_RED
	basketball.add_child(visual)
	
	# 设置物理属性
	basketball.bounce = sport_config.ball_bounce
	basketball.physics_material_override = PhysicsMaterial.new()
	basketball.physics_material_override.bounce = sport_config.ball_bounce
	basketball.physics_material_override.friction = sport_config.ball_friction
	
	if basketball_field:
		basketball_field.add_child(basketball)

func setup_physics() -> void:
	# 设置重力
	PhysicsServer2D.area_set_param(
		get_viewport().world_2d.space,
		PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR,
		sport_config.gravity.normalized()
	)
	PhysicsServer2D.area_set_param(
		get_viewport().world_2d.space,
		PhysicsServer2D.AREA_PARAM_GRAVITY,
		sport_config.gravity.length()
	)

func setup_players(player_count: int) -> Array[Node]:
	var players_array: Array[Node] = []
	
	for i in range(min(player_count, sport_config.max_players)):
		var player = create_basketball_player(i)
		players_array.append(player)
		current_players.append(player)
		
		if basketball_field:
			basketball_field.add_child(player)
	
	return players_array

func create_basketball_player(player_index: int) -> CharacterBody2D:
	var player = CharacterBody2D.new()
	player.name = "Player" + str(player_index + 1)
	
	# 设置初始位置
	var start_positions = [
		Vector2(sport_config.field_size.x * 0.25, sport_config.field_size.y * 0.5),
		Vector2(sport_config.field_size.x * 0.75, sport_config.field_size.y * 0.5)
	]
	
	if player_index < start_positions.size():
		player.position = start_positions[player_index]
	
	# 玩家碰撞形状
	var collision = CollisionShape2D.new()
	var capsule_shape = CapsuleShape2D.new()
	capsule_shape.radius = 20
	capsule_shape.height = 60
	collision.shape = capsule_shape
	player.add_child(collision)
	
	# 玩家视觉
	var visual = ColorRect.new()
	visual.size = Vector2(40, 60)
	visual.position = Vector2(-20, -30)
	visual.color = Color.BLUE if player_index == 0 else Color.RED
	player.add_child(visual)
	
	return player

func start_game() -> void:
	if not is_initialized:
		push_error("Basketball sport not initialized")
		return
	
	is_game_active = true
	basketball_state = BasketballState.TIPOFF
	current_shot_clock = shot_clock
	game_started.emit()
	print("Basketball game started")

func end_game() -> void:
	is_game_active = false
	basketball_state = BasketballState.TIMEOUT
	
	# 确定获胜者
	var result = determine_winner()
	game_ended.emit(result)
	print("Basketball game ended: ", result)

func update_game_logic(delta: float) -> void:
	if not is_game_active:
		return
	
	# 更新进攻时间
	if basketball_state == BasketballState.PLAYING:
		current_shot_clock -= delta
		if current_shot_clock <= 0:
			handle_shot_clock_violation()
	
	# 检查比赛时间
	check_game_time()

func handle_shot_clock_violation() -> void:
	print("Shot clock violation!")
	current_shot_clock = shot_clock
	# 这里可以添加换球权逻辑

func check_game_time() -> void:
	var quarter_time = sport_config.game_duration / 4
	var current_quarter_time = fmod(game_time, quarter_time)
	
	if current_quarter_time >= quarter_time and score_data.quarter < 4:
		end_quarter()

func end_quarter() -> void:
	score_data.quarter += 1
	print("Quarter ", score_data.quarter - 1, " ended")
	
	if score_data.quarter > 4:
		# 检查是否需要加时
		if score_data.player1 == score_data.player2:
			start_overtime()
		else:
			end_game()

func start_overtime() -> void:
	print("Starting overtime")
	game_time = 0.0  # 重置时间为加时赛

func _on_hoop_entered(side: String, body: Node) -> void:
	if body == basketball:
		handle_basket_scored(side)

func handle_basket_scored(hoop_side: String) -> void:
	if last_shot_player.is_empty():
		return
	
	# 确定得分
	var points = calculate_shot_points()
	var scoring_player = last_shot_player
	
	# 更新比分
	if scoring_player == "player1":
		score_data.player1 += points
	else:
		score_data.player2 += points
	
	# 重置进攻时间
	current_shot_clock = shot_clock
	
	# 发出信号
	basket_scored.emit(scoring_player, points, basketball.position)
	score_changed.emit(score_data)
	
	print(scoring_player, " scored ", points, " points!")

func calculate_shot_points() -> int:
	# 简化版：根据投篮位置计算得分
	var shot_distance = basketball.position.distance_to(Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2))
	
	if shot_distance > 200:  # 三分线外
		return 3
	else:
		return 2

func set_last_shot_player(player_id: String) -> void:
	last_shot_player = player_id

func get_current_score() -> Dictionary:
	return score_data.duplicate()

func determine_winner() -> Dictionary:
	var winner = ""
	if score_data.player1 > score_data.player2:
		winner = "player1"
	elif score_data.player2 > score_data.player1:
		winner = "player2"
	else:
		winner = "tie"
	
	return {
		"winner": winner,
		"final_score": score_data.duplicate(),
		"game_time": game_time,
		"sport": "Basketball"
	}