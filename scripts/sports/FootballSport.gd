extends BaseSport
class_name FootballSport

## 足球运动模块
## 实现足球特有的游戏规则和物理系统

signal goal_scored(player_id: String, goal_type: String, position: Vector2)
signal offside_detected(player_id: String)
signal foul_committed(player_id: String, foul_type: String)
signal corner_kick_awarded(team: String)
signal penalty_kick_awarded(team: String)

var football_field: Node2D
var football: RigidBody2D
var goals: Array[Area2D] = []
var score_data: Dictionary = {}
var last_touch_player: String = ""
var offside_line_left: float = 0.0
var offside_line_right: float = 0.0
var match_time: float = 0.0
var half_time_duration: float = 45.0 * 60.0  # 45分钟半场

## 足球特有的游戏状态
enum FootballState {
	KICKOFF,     # 开球
	PLAYING,     # 正常比赛
	CORNER_KICK, # 角球
	PENALTY,     # 点球
	FREE_KICK,   # 任意球
	HALFTIME,    # 中场休息
	FULLTIME     # 全场结束
}

var football_state: FootballState = FootballState.KICKOFF
var current_half: int = 1

func initialize_sport() -> void:
	if not sport_config:
		push_error("Football config is required")
		return
	
	# 初始化比分
	score_data = {
		"player1": 0,
		"player2": 0,
		"half": 1,
		"fouls": {"player1": 0, "player2": 0},
		"corners": {"player1": 0, "player2": 0},
		"possession": {"player1": 0.0, "player2": 0.0}
	}
	
	# 创建足球场地
	football_field = create_field()
	if football_field:
		add_child(football_field)
	
	# 创建足球
	create_football()
	
	# 设置物理参数
	setup_physics()
	
	# 设置越位线
	setup_offside_lines()
	
	is_initialized = true
	sport_initialized.emit()
	print("Football sport initialized")

func get_rules() -> Dictionary:
	return {
		"game_duration": sport_config.game_duration,
		"halves": 2,
		"half_duration": sport_config.game_duration / 2,
		"offside_rule": true,
		"corner_kicks": true,
		"penalty_kicks": true,
		"free_kicks": true,
		"yellow_cards": true,
		"red_cards": true,
		"substitutions": 3,
		"injury_time": true,
		"scoring": {
			"goal": 1,
			"own_goal": -1
		},
		"field_dimensions": {
			"length": sport_config.field_size.x,
			"width": sport_config.field_size.y,
			"goal_width": 80,
			"goal_height": 40,
			"penalty_area_width": 160,
			"penalty_area_length": 60
		}
	}

func create_field() -> Node2D:
	var field = Node2D.new()
	field.name = "FootballField"
	
	# 创建场地边界
	var field_bounds = StaticBody2D.new()
	field_bounds.name = "FieldBounds"
	field.add_child(field_bounds)
	
	# 场地碰撞形状 - 创建四面墙
	create_field_boundaries(field_bounds)
	
	# 创建球门
	create_goals(field)
	
	# 创建禁区
	create_penalty_areas(field)
	
	# 创建中圈
	create_center_circle(field)
	
	# 创建角球区
	create_corner_areas(field)
	
	return field

func create_field_boundaries(field_bounds: StaticBody2D) -> void:
	var field_size = sport_config.field_size
	
	# 上边界
	var top_wall = create_wall(Vector2(field_size.x / 2, 0), Vector2(field_size.x, 20))
	field_bounds.add_child(top_wall)
	
	# 下边界
	var bottom_wall = create_wall(Vector2(field_size.x / 2, field_size.y), Vector2(field_size.x, 20))
	field_bounds.add_child(bottom_wall)
	
	# 左边界
	var left_wall = create_wall(Vector2(0, field_size.y / 2), Vector2(20, field_size.y))
	field_bounds.add_child(left_wall)
	
	# 右边界
	var right_wall = create_wall(Vector2(field_size.x, field_size.y / 2), Vector2(20, field_size.y))
	field_bounds.add_child(right_wall)

func create_wall(pos: Vector2, size: Vector2) -> CollisionShape2D:
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision.shape = rect_shape
	collision.position = pos
	return collision

func create_goals(field: Node2D) -> void:
	# 左侧球门
	var left_goal = create_single_goal(Vector2(0, sport_config.field_size.y / 2), "left")
	field.add_child(left_goal)
	goals.append(left_goal)
	
	# 右侧球门
	var right_goal = create_single_goal(Vector2(sport_config.field_size.x, sport_config.field_size.y / 2), "right")
	field.add_child(right_goal)
	goals.append(right_goal)

func create_single_goal(pos: Vector2, side: String) -> Area2D:
	var goal = Area2D.new()
	goal.name = side.capitalize() + "Goal"
	goal.position = pos
	
	# 球门碰撞检测区域
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(40, 80)  # 球门大小
	collision.shape = rect_shape
	goal.add_child(collision)
	
	# 连接进球信号
	goal.body_entered.connect(_on_goal_entered.bind(side))
	
	# 球门视觉
	var goal_visual = ColorRect.new()
	goal_visual.size = Vector2(40, 80)
	goal_visual.position = Vector2(-20, -40)
	goal_visual.color = Color.WHITE
	goal.add_child(goal_visual)
	
	# 球门柱
	create_goal_posts(goal, side)
	
	return goal

func create_goal_posts(goal: Area2D, side: String) -> void:
	# 左球门柱
	var left_post = StaticBody2D.new()
	left_post.name = "LeftPost"
	var left_collision = CollisionShape2D.new()
	var left_rect = RectangleShape2D.new()
	left_rect.size = Vector2(5, 5)
	left_collision.shape = left_rect
	left_collision.position = Vector2(-20, -40)
	left_post.add_child(left_collision)
	goal.add_child(left_post)
	
	# 右球门柱
	var right_post = StaticBody2D.new()
	right_post.name = "RightPost"
	var right_collision = CollisionShape2D.new()
	var right_rect = RectangleShape2D.new()
	right_rect.size = Vector2(5, 5)
	right_collision.shape = right_rect
	right_collision.position = Vector2(-20, 40)
	right_post.add_child(right_collision)
	goal.add_child(right_post)

func create_penalty_areas(field: Node2D) -> void:
	# 左侧禁区
	var left_penalty = create_penalty_area(Vector2(60, sport_config.field_size.y / 2), "left")
	field.add_child(left_penalty)
	
	# 右侧禁区
	var right_penalty = create_penalty_area(Vector2(sport_config.field_size.x - 60, sport_config.field_size.y / 2), "right")
	field.add_child(right_penalty)

func create_penalty_area(pos: Vector2, side: String) -> Area2D:
	var penalty_area = Area2D.new()
	penalty_area.name = side.capitalize() + "PenaltyArea"
	penalty_area.position = pos
	
	# 禁区检测
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(120, 160)
	collision.shape = rect_shape
	penalty_area.add_child(collision)
	
	# 禁区视觉标记
	var visual = ColorRect.new()
	visual.size = Vector2(120, 160)
	visual.position = Vector2(-60, -80)
	visual.color = Color(1, 1, 1, 0.1)  # 半透明白色
	penalty_area.add_child(visual)
	
	return penalty_area

func create_center_circle(field: Node2D) -> void:
	var center_circle = Area2D.new()
	center_circle.name = "CenterCircle"
	center_circle.position = Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2)
	
	# 中圈检测
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50
	collision.shape = circle_shape
	center_circle.add_child(collision)
	
	field.add_child(center_circle)

func create_corner_areas(field: Node2D) -> void:
	var corner_positions = [
		Vector2(0, 0),  # 左上角
		Vector2(sport_config.field_size.x, 0),  # 右上角
		Vector2(0, sport_config.field_size.y),  # 左下角
		Vector2(sport_config.field_size.x, sport_config.field_size.y)  # 右下角
	]
	
	for i in range(corner_positions.size()):
		var corner = Area2D.new()
		corner.name = "Corner" + str(i)
		corner.position = corner_positions[i]
		
		var collision = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 10
		collision.shape = circle_shape
		corner.add_child(collision)
		
		football_field.add_child(corner)

func create_football() -> void:
	football = RigidBody2D.new()
	football.name = "Football"
	football.position = Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2)
	
	# 足球碰撞形状
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 12
	collision.shape = circle_shape
	football.add_child(collision)
	
	# 足球视觉
	var visual = ColorRect.new()
	visual.size = Vector2(24, 24)
	visual.position = Vector2(-12, -12)
	visual.color = Color.WHITE
	football.add_child(visual)
	
	# 设置物理属性
	football.bounce = sport_config.ball_bounce
	football.physics_material_override = PhysicsMaterial.new()
	football.physics_material_override.bounce = sport_config.ball_bounce
	football.physics_material_override.friction = sport_config.ball_friction
	
	# 连接碰撞信号
	football.body_entered.connect(_on_football_touched)
	
	if football_field:
		football_field.add_child(football)

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

func setup_offside_lines() -> void:
	# 设置越位线位置
	offside_line_left = sport_config.field_size.x * 0.2
	offside_line_right = sport_config.field_size.x * 0.8

func setup_players(player_count: int) -> Array[Node]:
	var players_array: Array[Node] = []
	
	for i in range(min(player_count, sport_config.max_players)):
		var player = create_football_player(i)
		players_array.append(player)
		current_players.append(player)
		
		if football_field:
			football_field.add_child(player)
	
	return players_array

func create_football_player(player_index: int) -> CharacterBody2D:
	var player = CharacterBody2D.new()
	player.name = "Player" + str(player_index + 1)
	
	# 设置初始位置（足球阵型）
	var start_positions = [
		Vector2(sport_config.field_size.x * 0.3, sport_config.field_size.y * 0.5),  # 左队
		Vector2(sport_config.field_size.x * 0.7, sport_config.field_size.y * 0.5),  # 右队
		Vector2(sport_config.field_size.x * 0.25, sport_config.field_size.y * 0.3), # 左队前锋
		Vector2(sport_config.field_size.x * 0.75, sport_config.field_size.y * 0.7)  # 右队前锋
	]
	
	if player_index < start_positions.size():
		player.position = start_positions[player_index]
	
	# 玩家碰撞形状
	var collision = CollisionShape2D.new()
	var capsule_shape = CapsuleShape2D.new()
	capsule_shape.radius = 15
	capsule_shape.height = 50
	collision.shape = capsule_shape
	player.add_child(collision)
	
	# 玩家视觉
	var visual = ColorRect.new()
	visual.size = Vector2(30, 50)
	visual.position = Vector2(-15, -25)
	visual.color = Color.BLUE if player_index % 2 == 0 else Color.RED
	player.add_child(visual)
	
	# 添加玩家属性
	player.set_meta("team", "team1" if player_index % 2 == 0 else "team2")
	player.set_meta("player_id", "player" + str(player_index + 1))
	
	return player

func start_game() -> void:
	if not is_initialized:
		push_error("Football sport not initialized")
		return
	
	is_game_active = true
	football_state = FootballState.KICKOFF
	current_half = 1
	match_time = 0.0
	game_started.emit()
	print("Football game started")

func end_game() -> void:
	is_game_active = false
	football_state = FootballState.FULLTIME
	
	# 确定获胜者
	var result = determine_winner()
	game_ended.emit(result)
	print("Football game ended: ", result)

func update_game_logic(delta: float) -> void:
	if not is_game_active:
		return
	
	match_time += delta
	
	# 检查半场时间
	if match_time >= half_time_duration and current_half == 1:
		end_first_half()
	elif match_time >= (half_time_duration * 2) and current_half == 2:
		end_game()
	
	# 检查越位
	check_offside()
	
	# 更新控球统计
	update_possession_stats(delta)

func end_first_half() -> void:
	current_half = 2
	football_state = FootballState.HALFTIME
	score_data.half = 2
	print("First half ended, starting second half")
	
	# 重置球的位置到中场
	if football:
		football.position = Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2)
		football.linear_velocity = Vector2.ZERO
	
	football_state = FootballState.KICKOFF

func check_offside() -> void:
	# 简化的越位检测逻辑
	for player in current_players:
		if not player.has_meta("team"):
			continue
			
		var team = player.get_meta("team")
		var player_pos = player.position
		
		# 检查是否越位
		if team == "team1" and player_pos.x > offside_line_right:
			if is_player_offside(player):
				handle_offside(player.get_meta("player_id"))
		elif team == "team2" and player_pos.x < offside_line_left:
			if is_player_offside(player):
				handle_offside(player.get_meta("player_id"))

func is_player_offside(player: Node) -> bool:
	# 简化的越位判断：如果球员比球更接近球门线
	if not football:
		return false
		
	var team = player.get_meta("team")
	var player_pos = player.position.x
	var ball_pos = football.position.x
	
	if team == "team1":
		return player_pos > ball_pos and player_pos > offside_line_right
	else:
		return player_pos < ball_pos and player_pos < offside_line_left

func handle_offside(player_id: String) -> void:
	print("Offside detected for player: ", player_id)
	offside_detected.emit(player_id)
	football_state = FootballState.FREE_KICK

func update_possession_stats(delta: float) -> void:
	# 简单的控球统计：基于最后触球的球员
	if not last_touch_player.is_empty():
		if last_touch_player.begins_with("player1") or last_touch_player.begins_with("player3"):
			score_data.possession.player1 += delta
		else:
			score_data.possession.player2 += delta

func _on_goal_entered(side: String, body: Node) -> void:
	if body == football:
		handle_goal_scored(side)

func handle_goal_scored(goal_side: String) -> void:
	if last_touch_player.is_empty():
		return
	
	# 确定进球类型和得分队伍
	var goal_type = "normal"
	var scoring_team = ""
	
	# 判断是否为乌龙球
	if (goal_side == "left" and last_touch_player.begins_with("player1")) or \
	   (goal_side == "right" and last_touch_player.begins_with("player2")):
		goal_type = "own_goal"
		scoring_team = "player2" if goal_side == "left" else "player1"
	else:
		scoring_team = "player1" if goal_side == "right" else "player2"
	
	# 更新比分
	if scoring_team == "player1":
		score_data.player1 += 1
	else:
		score_data.player2 += 1
	
	# 重置球位置
	reset_ball_position()
	
	# 发出信号
	goal_scored.emit(last_touch_player, goal_type, football.position)
	score_changed.emit(score_data)
	
	print(scoring_team, " scored! Goal type: ", goal_type)

func reset_ball_position() -> void:
	if football:
		football.position = Vector2(sport_config.field_size.x / 2, sport_config.field_size.y / 2)
		football.linear_velocity = Vector2.ZERO
		football_state = FootballState.KICKOFF

func _on_football_touched(body: Node) -> void:
	if body in current_players and body.has_meta("player_id"):
		last_touch_player = body.get_meta("player_id")

func handle_corner_kick(team: String) -> void:
	football_state = FootballState.CORNER_KICK
	corner_kick_awarded.emit(team)
	print("Corner kick awarded to ", team)

func handle_penalty_kick(team: String) -> void:
	football_state = FootballState.PENALTY
	penalty_kick_awarded.emit(team)
	print("Penalty kick awarded to ", team)

func handle_foul(player_id: String, foul_type: String) -> void:
	foul_committed.emit(player_id, foul_type)
	
	# 更新犯规统计
	if player_id.begins_with("player1") or player_id.begins_with("player3"):
		score_data.fouls.player1 += 1
	else:
		score_data.fouls.player2 += 1
	
	football_state = FootballState.FREE_KICK
	print("Foul committed by ", player_id, ": ", foul_type)

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
		"match_time": match_time,
		"sport": "Football",
		"halves_played": current_half
	}

## 获取当前比赛状态
func get_match_state() -> Dictionary:
	return {
		"state": football_state,
		"half": current_half,
		"time": match_time,
		"ball_position": football.position if football else Vector2.ZERO,
		"last_touch": last_touch_player
	}

## 设置比赛状态（用于网络同步）
func set_match_state(state_data: Dictionary) -> void:
	if state_data.has("state"):
		football_state = state_data.state
	if state_data.has("half"):
		current_half = state_data.half
	if state_data.has("time"):
		match_time = state_data.time
	if state_data.has("ball_position") and football:
		football.position = state_data.ball_position
	if state_data.has("last_touch"):
		last_touch_player = state_data.last_touch