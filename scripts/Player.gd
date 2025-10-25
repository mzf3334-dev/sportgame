class_name Player
extends CharacterBody2D
## Player character controller for sports games

signal player_scored(points: int)
signal player_action_performed(action: String)

@export var player_data: PlayerData
@export var team_id: int = 0
@export var is_local_player: bool = false

# Movement properties
@export var base_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Current state
var current_sport: String = ""
var is_active: bool = true
var input_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not player_data:
		player_data = PlayerData.new()
	
	update_visual_appearance()
	update_stats_from_equipment()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	handle_movement(delta)
	handle_animations()

func handle_movement(delta: float) -> void:
	"""Handle player movement with physics"""
	var effective_stats = player_data.get_effective_stats()
	var current_speed = base_speed * (1.0 + effective_stats.get("speed", 1) * 0.1)
	
	if input_vector.length() > 0:
		# Apply acceleration
		velocity = velocity.move_toward(input_vector * current_speed, acceleration * delta)
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()

func handle_animations() -> void:
	"""Update animations based on movement"""
	if not animation_player:
		return
	
	if velocity.length() > 10:
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
		
		if animation_player.has_animation("run"):
			animation_player.play("run")
	else:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")

func set_input_vector(new_input: Vector2) -> void:
	"""Set movement input vector"""
	input_vector = new_input.normalized()

func perform_action(action_name: String) -> void:
	"""Perform a sport-specific action"""
	var effective_stats = player_data.get_effective_stats()
	
	match action_name:
		"shoot":
			perform_shoot_action(effective_stats)
		"pass":
			perform_pass_action(effective_stats)
		"jump":
			perform_jump_action(effective_stats)
		"tackle":
			perform_tackle_action(effective_stats)
	
	player_action_performed.emit(action_name)

func perform_shoot_action(stats: Dictionary) -> void:
	"""Perform shooting action with accuracy based on stats"""
	var accuracy = stats.get("accuracy", 1)
	var strength = stats.get("strength", 1)
	
	# Play shooting animation
	if animation_player and animation_player.has_animation("shoot"):
		animation_player.play("shoot")
	
	# Emit signal for game logic to handle
	print("Player ", player_data.nickname, " shoots with accuracy: ", accuracy, " strength: ", strength)

func perform_pass_action(stats: Dictionary) -> void:
	"""Perform passing action"""
	var accuracy = stats.get("accuracy", 1)
	
	if animation_player and animation_player.has_animation("pass"):
		animation_player.play("pass")
	
	print("Player ", player_data.nickname, " passes with accuracy: ", accuracy)

func perform_jump_action(stats: Dictionary) -> void:
	"""Perform jumping action"""
	var strength = stats.get("strength", 1)
	
	if animation_player and animation_player.has_animation("jump"):
		animation_player.play("jump")
	
	print("Player ", player_data.nickname, " jumps with strength: ", strength)

func perform_tackle_action(stats: Dictionary) -> void:
	"""Perform tackling action"""
	var strength = stats.get("strength", 1)
	var speed = stats.get("speed", 1)
	
	if animation_player and animation_player.has_animation("tackle"):
		animation_player.play("tackle")
	
	print("Player ", player_data.nickname, " tackles with strength: ", strength, " speed: ", speed)

func update_visual_appearance() -> void:
	"""Update player visual appearance based on equipment and customization"""
	if not player_data:
		return
	
	# Update sprite based on appearance settings
	var appearance = player_data.appearance
	
	# This would typically load different sprite textures or modify colors
	# For now, we'll just change the modulate color as an example
	if sprite:
		match appearance.get("jersey_color", 0):
			0: sprite.modulate = Color.WHITE
			1: sprite.modulate = Color.RED
			2: sprite.modulate = Color.BLUE
			3: sprite.modulate = Color.GREEN
			4: sprite.modulate = Color.YELLOW
	
	# Apply equipment visual effects
	apply_equipment_visuals()

func apply_equipment_visuals() -> void:
	"""Apply visual effects from equipped items"""
	for item in player_data.equipment:
		if item and item.visual_data:
			# Apply visual modifications based on equipment
			# This is where you'd change textures, colors, etc.
			pass

func update_stats_from_equipment() -> void:
	"""Update cached stats when equipment changes"""
	# This is called when equipment is changed
	# The actual stat calculation is done in PlayerData.get_effective_stats()
	pass

func set_team_color(color: Color) -> void:
	"""Set team-specific color"""
	if sprite:
		sprite.modulate = color

func get_current_stats() -> Dictionary:
	"""Get current effective stats including equipment bonuses"""
	return player_data.get_effective_stats() if player_data else {}

func add_score(points: int) -> void:
	"""Add score for this player"""
	if player_data:
		player_data.stats.total_score += points
		
		# Add sport-specific score
		match current_sport:
			"basketball":
				player_data.stats.basketball_score += points
			"football":
				player_data.stats.football_score += points
			"tennis":
				player_data.stats.tennis_score += points
	
	player_scored.emit(points)

func set_sport_context(sport_name: String) -> void:
	"""Set the current sport context for the player"""
	current_sport = sport_name

func get_stamina_percentage() -> float:
	"""Get current stamina as percentage (0.0 to 1.0)"""
	var stamina_stat = player_data.get_effective_stats().get("stamina", 1) if player_data else 1
	# Simple stamina calculation - in a real game this would decrease over time
	return min(1.0, stamina_stat / 10.0)

func is_exhausted() -> bool:
	"""Check if player is too exhausted to perform actions"""
	return get_stamina_percentage() < 0.2