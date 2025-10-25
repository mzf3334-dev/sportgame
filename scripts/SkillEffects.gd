class_name SkillEffects
extends Node2D
## Visual effects system for skill usage

signal effect_completed(effect_name: String)

# Effect scenes and resources
var effect_scenes: Dictionary = {}
var particle_systems: Dictionary = {}

func _ready() -> void:
	setup_effect_systems()

func setup_effect_systems() -> void:
	"""Initialize particle systems and effect resources"""
	# Create particle systems for different skill effects
	create_speed_boost_effect()
	create_power_shot_effect()
	create_accuracy_boost_effect()
	create_leadership_aura_effect()

func create_speed_boost_effect() -> void:
	"""Create speed boost visual effect"""
	var particles = CPUParticles2D.new()
	particles.name = "SpeedBoostEffect"
	particles.emitting = false
	particles.amount = 50
	particles.lifetime = 1.0
	particles.texture = create_circle_texture(Color.CYAN, 4)
	
	# Speed boost properties
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color.CYAN
	
	add_child(particles)
	particle_systems["speed_boost"] = particles

func create_power_shot_effect() -> void:
	"""Create power shot visual effect"""
	var particles = CPUParticles2D.new()
	particles.name = "PowerShotEffect"
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 0.8
	particles.texture = create_circle_texture(Color.RED, 6)
	
	# Power shot properties
	particles.direction = Vector2(1, 0)
	particles.spread = 45.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color.RED
	
	add_child(particles)
	particle_systems["power_shot"] = particles

func create_accuracy_boost_effect() -> void:
	"""Create accuracy boost visual effect"""
	var particles = CPUParticles2D.new()
	particles.name = "AccuracyBoostEffect"
	particles.emitting = false
	particles.amount = 20
	particles.lifetime = 1.5
	particles.texture = create_star_texture(Color.YELLOW, 8)
	
	# Accuracy boost properties
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_radius = 30.0
	particles.direction = Vector2(0, -1)
	particles.spread = 360.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 1.0
	particles.color = Color.YELLOW
	
	add_child(particles)
	particle_systems["accuracy_boost"] = particles

func create_leadership_aura_effect() -> void:
	"""Create leadership aura visual effect"""
	var particles = CPUParticles2D.new()
	particles.name = "LeadershipAuraEffect"
	particles.emitting = false
	particles.amount = 40
	particles.lifetime = 2.0
	particles.texture = create_circle_texture(Color.GOLD, 3)
	
	# Leadership aura properties
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_CIRCLE
	particles.emission_radius = 50.0
	particles.direction = Vector2(0, 0)
	particles.spread = 360.0
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 30.0
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.8
	particles.color = Color.GOLD
	
	add_child(particles)
	particle_systems["leadership_aura"] = particles

func create_circle_texture(color: Color, size: int) -> ImageTexture:
	"""Create a simple circle texture for particles"""
	var image = Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	
	for x in range(size * 2):
		for y in range(size * 2):
			var distance = Vector2(x - size, y - size).length()
			if distance <= size:
				var alpha = 1.0 - (distance / size)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_star_texture(color: Color, size: int) -> ImageTexture:
	"""Create a simple star texture for particles"""
	var image = Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	
	# Simple star pattern (cross shape)
	for x in range(size * 2):
		for y in range(size * 2):
			var center_x = size
			var center_y = size
			
			# Horizontal line
			if abs(y - center_y) <= 1 and abs(x - center_x) <= size:
				image.set_pixel(x, y, color)
			# Vertical line
			elif abs(x - center_x) <= 1 and abs(y - center_y) <= size:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func play_skill_effect(skill_name: String, target_position: Vector2 = Vector2.ZERO) -> void:
	"""Play visual effect for a skill"""
	position = target_position
	
	match skill_name:
		"speed", "agility":
			play_speed_boost()
		"power_shot":
			play_power_shot()
		"accuracy":
			play_accuracy_boost()
		"leadership":
			play_leadership_aura()
		"strength":
			play_strength_effect()
		"stamina":
			play_stamina_effect()

func play_speed_boost() -> void:
	"""Play speed boost effect"""
	var particles = particle_systems.get("speed_boost")
	if particles:
		particles.restart()
		particles.emitting = true
		
		# Auto-stop after duration
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): particles.emitting = false)
		
		# Create speed lines effect
		create_speed_lines()

func play_power_shot() -> void:
	"""Play power shot effect"""
	var particles = particle_systems.get("power_shot")
	if particles:
		particles.restart()
		particles.emitting = true
		
		# Screen shake effect
		create_screen_shake()
		
		var timer = get_tree().create_timer(0.8)
		timer.timeout.connect(func(): particles.emitting = false)

func play_accuracy_boost() -> void:
	"""Play accuracy boost effect"""
	var particles = particle_systems.get("accuracy_boost")
	if particles:
		particles.restart()
		particles.emitting = true
		
		# Create targeting reticle effect
		create_targeting_reticle()
		
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): particles.emitting = false)

func play_leadership_aura() -> void:
	"""Play leadership aura effect"""
	var particles = particle_systems.get("leadership_aura")
	if particles:
		particles.restart()
		particles.emitting = true
		
		# Create pulsing aura effect
		create_pulsing_aura()
		
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): particles.emitting = false)

func play_strength_effect() -> void:
	"""Play strength enhancement effect"""
	# Create muscle flex visual
	var strength_sprite = Sprite2D.new()
	strength_sprite.texture = create_circle_texture(Color.RED, 16)
	strength_sprite.modulate = Color(1, 0, 0, 0.7)
	add_child(strength_sprite)
	
	var tween = create_tween()
	tween.parallel().tween_property(strength_sprite, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(strength_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(strength_sprite.queue_free)

func play_stamina_effect() -> void:
	"""Play stamina boost effect"""
	# Create energy wave effect
	var stamina_sprite = Sprite2D.new()
	stamina_sprite.texture = create_circle_texture(Color.GREEN, 12)
	stamina_sprite.modulate = Color(0, 1, 0, 0.8)
	add_child(stamina_sprite)
	
	var tween = create_tween()
	tween.parallel().tween_property(stamina_sprite, "scale", Vector2(3.0, 3.0), 1.0)
	tween.parallel().tween_property(stamina_sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(stamina_sprite.queue_free)

func create_speed_lines() -> void:
	"""Create speed lines effect"""
	for i in range(5):
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = Color.CYAN
		line.add_point(Vector2(-50 + i * 25, -20))
		line.add_point(Vector2(-30 + i * 25, -20))
		add_child(line)
		
		var tween = create_tween()
		tween.parallel().tween_property(line, "position:x", 100, 0.3)
		tween.parallel().tween_property(line, "modulate:a", 0.0, 0.3)
		tween.tween_callback(line.queue_free)

func create_screen_shake() -> void:
	"""Create screen shake effect"""
	# This would typically affect the camera
	# For now, we'll create a visual shake on the effect node
	var original_position = position
	var tween = create_tween()
	
	for i in range(10):
		var shake_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		tween.tween_property(self, "position", original_position + shake_offset, 0.05)
	
	tween.tween_property(self, "position", original_position, 0.05)

func create_targeting_reticle() -> void:
	"""Create targeting reticle effect"""
	var reticle = Node2D.new()
	add_child(reticle)
	
	# Create crosshair lines
	var h_line = Line2D.new()
	h_line.width = 2.0
	h_line.default_color = Color.YELLOW
	h_line.add_point(Vector2(-20, 0))
	h_line.add_point(Vector2(20, 0))
	reticle.add_child(h_line)
	
	var v_line = Line2D.new()
	v_line.width = 2.0
	v_line.default_color = Color.YELLOW
	v_line.add_point(Vector2(0, -20))
	v_line.add_point(Vector2(0, 20))
	reticle.add_child(v_line)
	
	# Animate reticle
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(reticle, "scale", Vector2(1.5, 1.5), 0.25)
	tween.tween_property(reticle, "scale", Vector2(1.0, 1.0), 0.25)
	tween.tween_callback(reticle.queue_free)

func create_pulsing_aura() -> void:
	"""Create pulsing aura effect"""
	var aura = Sprite2D.new()
	aura.texture = create_circle_texture(Color.GOLD, 32)
	aura.modulate = Color(1, 1, 0, 0.3)
	add_child(aura)
	
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(aura, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(aura, "modulate:a", 0.1, 0.5)
	tween.tween_property(aura, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(aura, "modulate:a", 0.3, 0.5)
	tween.tween_callback(aura.queue_free)

func stop_all_effects() -> void:
	"""Stop all active particle effects"""
	for particles in particle_systems.values():
		if particles:
			particles.emitting = false

func cleanup_effects() -> void:
	"""Clean up all effect nodes"""
	for child in get_children():
		if child.name.ends_with("Effect") or child is CPUParticles2D:
			child.queue_free()