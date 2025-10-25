extends Node2D
## Interactive Basketball Demo - Player vs AI

# Player nodes
var player1: CharacterBody2D  # Human controlled
var player2: CharacterBody2D  # AI controlled
var ball: Area2D

# Player data
var player1_data: Resource
var player2_data: Resource
var player_manager: Node

# Game state
var score_player1: int = 0
var score_player2: int = 0
var ball_holder = null

# UI
var ui_layer: CanvasLayer
var score_label: Label
var controls_label: Label
var stats_label: Label

# Constants
const PLAYER_SPEED = 200.0
const AI_SPEED = 150.0
const BALL_SPEED = 300.0
const COURT_WIDTH = 800
const COURT_HEIGHT = 600

func _ready() -> void:
	setup_ui()
	setup_player_system()
	await get_tree().create_timer(0.5).timeout
	setup_court()
	setup_players()
	setup_ball()
	start_game()

func setup_ui() -> void:
	"""Create game UI"""
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Title
	var title = Label.new()
	title.text = "🏀 Basketball Demo - Player vs AI"
	title.position = Vector2(20, 10)
	title.add_theme_font_size_override("font_size", 24)
	ui_layer.add_child(title)
	
	# Score
	score_label = Label.new()
	score_label.text = "Score: 0 - 0"
	score_label.position = Vector2(20, 50)
	score_label.add_theme_font_size_override("font_size", 20)
	ui_layer.add_child(score_label)
	
	# Controls
	controls_label = Label.new()
	controls_label.text = "Controls: WASD to move | SPACE to shoot"
	controls_label.position = Vector2(20, 80)
	ui_layer.add_child(controls_label)
	
	# Stats
	stats_label = Label.new()
	stats_label.text = "Player Stats Loading..."
	stats_label.position = Vector2(20, 110)
	ui_layer.add_child(stats_label)

func setup_player_system() -> void:
	"""Initialize player system"""
	var player_manager_script = preload("res://scripts/managers/PlayerManager.gd")
	player_manager = player_manager_script.new()
	add_child(player_manager)
	
	await get_tree().process_frame
	
	if player_manager.has_method("get_player_data"):
		player1_data = player_manager.get_player_data()
		
		# Create AI player data
		var player_data_script = preload("res://scripts/PlayerData.gd")
		player2_data = player_data_script.new("ai_player", "AI Opponent")
		player2_data.skills.speed = 3
		player2_data.skills.accuracy = 4

func setup_court() -> void:
	"""Create basketball court"""
	# Court background
	var court = ColorRect.new()
	court.color = Color(0.8, 0.6, 0.4, 1)  # Wood color
	court.position = Vector2(100, 150)
	court.size = Vector2(COURT_WIDTH, COURT_HEIGHT)
	add_child(court)
	
	# Center line
	var center_line = ColorRect.new()
	center_line.color = Color.WHITE
	center_line.position = Vector2(100 + COURT_WIDTH/2 - 2, 150)
	center_line.size = Vector2(4, COURT_HEIGHT)
	add_child(center_line)
	
	# Left hoop
	var left_hoop = ColorRect.new()
	left_hoop.color = Color.RED
	left_hoop.position = Vector2(120, 150 + COURT_HEIGHT/2 - 30)
	left_hoop.size = Vector2(20, 60)
	add_child(left_hoop)
	
	# Right hoop
	var right_hoop = ColorRect.new()
	right_hoop.color = Color.BLUE
	right_hoop.position = Vector2(100 + COURT_WIDTH - 40, 150 + COURT_HEIGHT/2 - 30)
	right_hoop.size = Vector2(20, 60)
	add_child(right_hoop)

func setup_players() -> void:
	"""Create player characters"""
	# Player 1 (Human)
	player1 = CharacterBody2D.new()
	player1.position = Vector2(250, 450)
	add_child(player1)
	
	var p1_sprite = create_player_sprite(Color.GREEN, "YOU")
	player1.add_child(p1_sprite)
	
	var p1_collision = CollisionShape2D.new()
	var p1_shape = CircleShape2D.new()
	p1_shape.radius = 20
	p1_collision.shape = p1_shape
	player1.add_child(p1_collision)
	
	# Player 2 (AI)
	player2 = CharacterBody2D.new()
	player2.position = Vector2(750, 450)
	add_child(player2)
	
	var p2_sprite = create_player_sprite(Color.RED, "AI")
	player2.add_child(p2_sprite)
	
	var p2_collision = CollisionShape2D.new()
	var p2_shape = CircleShape2D.new()
	p2_shape.radius = 20
	p2_collision.shape = p2_shape
	player2.add_child(p2_collision)
	
	# Update stats display
	if player1_data:
		var stats_text = "Your Stats: "
		stats_text += "Speed: " + str(player1_data.skills.get("speed", 1)) + " | "
		stats_text += "Accuracy: " + str(player1_data.skills.get("accuracy", 1)) + " | "
		stats_text += "Level: " + str(player1_data.stats.get("level", 1))
		stats_label.text = stats_text

func create_player_sprite(color: Color, label_text: String) -> Node2D:
	"""Create a player sprite with label"""
	var container = Node2D.new()
	
	# Player circle
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	
	# Draw circle
	for x in range(40):
		for y in range(40):
			var distance = Vector2(x - 20, y - 20).length()
			if distance <= 18:
				var alpha = 1.0 - (distance / 18.0) * 0.2
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	texture.set_image(image)
	sprite.texture = texture
	container.add_child(sprite)
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.position = Vector2(-15, -30)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	return container

func setup_ball() -> void:
	"""Create basketball"""
	ball = Area2D.new()
	ball.position = Vector2(500, 450)
	add_child(ball)
	
	# Ball sprite
	var ball_sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	
	# Draw orange ball
	for x in range(20):
		for y in range(20):
			var distance = Vector2(x - 10, y - 10).length()
			if distance <= 9:
				image.set_pixel(x, y, Color.ORANGE)
	
	texture.set_image(image)
	ball_sprite.texture = texture
	ball.add_child(ball_sprite)
	
	var ball_collision = CollisionShape2D.new()
	var ball_shape = CircleShape2D.new()
	ball_shape.radius = 10
	ball_collision.shape = ball_shape
	ball.add_child(ball_collision)

func start_game() -> void:
	"""Start the game"""
	print("🏀 Basketball game started!")
	print("Player 1 (Green - YOU) vs Player 2 (Red - AI)")

func _process(delta: float) -> void:
	handle_player_input(delta)
	handle_ai(delta)
	handle_ball(delta)
	check_scoring()
	update_ui()

func handle_player_input(delta: float) -> void:
	"""Handle player 1 controls"""
	if not player1:
		return
	
	var input_dir = Vector2.ZERO
	
	# WASD controls
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# Apply speed based on player stats
	var speed_multiplier = 1.0
	if player1_data and player1_data.skills.has("speed"):
		speed_multiplier = 1.0 + (player1_data.skills.speed * 0.1)
	
	player1.velocity = input_dir * PLAYER_SPEED * speed_multiplier
	player1.move_and_slide()
	
	# Keep player on court
	player1.position.x = clamp(player1.position.x, 120, 880)
	player1.position.y = clamp(player1.position.y, 170, 730)
	
	# Shoot ball
	if Input.is_key_pressed(KEY_SPACE) and ball_holder == player1:
		shoot_ball(player1, Vector2(1, 0))
		ball_holder = null

func handle_ai(delta: float) -> void:
	"""Simple AI for player 2"""
	if not player2 or not ball:
		return
	
	# AI chases the ball
	var direction = (ball.position - player2.position).normalized()
	
	player2.velocity = direction * AI_SPEED
	player2.move_and_slide()
	
	# Keep AI on court
	player2.position.x = clamp(player2.position.x, 120, 880)
	player2.position.y = clamp(player2.position.y, 170, 730)
	
	# AI shoots if close to left hoop
	if ball_holder == player2 and player2.position.x < 200:
		shoot_ball(player2, Vector2(-1, 0))
		ball_holder = null

func handle_ball(delta: float) -> void:
	"""Handle ball physics"""
	if not ball:
		return
	
	# Ball follows holder
	if ball_holder:
		ball.position = ball_holder.position + Vector2(0, -30)
	
	# Check if players touch ball
	if not ball_holder:
		var dist_to_p1 = ball.position.distance_to(player1.position)
		var dist_to_p2 = ball.position.distance_to(player2.position)
		
		if dist_to_p1 < 30:
			ball_holder = player1
		elif dist_to_p2 < 30:
			ball_holder = player2

func shoot_ball(shooter: CharacterBody2D, direction: Vector2) -> void:
	"""Shoot the ball"""
	# Simple shooting - ball moves toward hoop
	var target_hoop = Vector2(140, 450) if shooter == player1 else Vector2(860, 450)
	
	# Create tween for ball movement
	var tween = create_tween()
	tween.tween_property(ball, "position", target_hoop, 0.5)
	
	print("Player shoots!")

func check_scoring() -> void:
	"""Check if ball scored"""
	if not ball:
		return
	
	# Check left hoop (Player 1 scores)
	if ball.position.x < 150 and ball.position.y > 420 and ball.position.y < 480:
		if ball_holder == null:  # Ball must be shot
			score_player1 += 1
			reset_ball()
			print("Player 1 scores! 🎉")
			
			# Add experience to player
			if player1_data and player1_data.has_method("add_experience"):
				player1_data.add_experience(50)
	
	# Check right hoop (Player 2 scores)
	elif ball.position.x > 850 and ball.position.y > 420 and ball.position.y < 480:
		if ball_holder == null:
			score_player2 += 1
			reset_ball()
			print("Player 2 scores!")

func reset_ball() -> void:
	"""Reset ball to center"""
	if ball:
		ball.position = Vector2(500, 450)
		ball_holder = null

func update_ui() -> void:
	"""Update UI elements"""
	if score_label:
		score_label.text = "Score: " + str(score_player1) + " - " + str(score_player2)
	
	# Update stats if player leveled up
	if player1_data and stats_label:
		var stats_text = "Your Stats: "
		stats_text += "Speed: " + str(player1_data.skills.get("speed", 1)) + " | "
		stats_text += "Accuracy: " + str(player1_data.skills.get("accuracy", 1)) + " | "
		stats_text += "Level: " + str(player1_data.stats.get("level", 1))
		stats_label.text = stats_text