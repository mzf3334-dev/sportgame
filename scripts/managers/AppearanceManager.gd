class_name AppearanceManager
extends Node
## Manages player visual appearance and customization options

signal appearance_updated(player: Player)

# Appearance asset paths
var skin_textures: Array[String] = [
	"res://assets/textures/player/skin_light.png",
	"res://assets/textures/player/skin_medium_light.png",
	"res://assets/textures/player/skin_medium.png",
	"res://assets/textures/player/skin_medium_dark.png",
	"res://assets/textures/player/skin_dark.png"
]

var hair_textures: Array[String] = [
	"res://assets/textures/player/hair_short.png",
	"res://assets/textures/player/hair_medium.png",
	"res://assets/textures/player/hair_long.png",
	"res://assets/textures/player/hair_curly.png",
	"res://assets/textures/player/hair_bald.png"
]

var jersey_textures: Array[String] = [
	"res://assets/textures/equipment/jersey_basic.png",
	"res://assets/textures/equipment/jersey_striped.png",
	"res://assets/textures/equipment/jersey_numbered.png",
	"res://assets/textures/equipment/jersey_vintage.png"
]

# Color palettes
var skin_colors: Array[Color] = [
	Color(1.0, 0.8, 0.6, 1.0),    # Light
	Color(0.9, 0.7, 0.5, 1.0),    # Medium-Light
	Color(0.8, 0.6, 0.4, 1.0),    # Medium
	Color(0.7, 0.5, 0.3, 1.0),    # Medium-Dark
	Color(0.6, 0.4, 0.2, 1.0)     # Dark
]

var hair_colors: Array[Color] = [
	Color.BLACK,
	Color(0.4, 0.2, 0.1, 1.0),    # Brown
	Color(1.0, 0.8, 0.0, 1.0),    # Blonde
	Color(0.8, 0.0, 0.0, 1.0),    # Red
	Color.WHITE,
	Color(0.5, 0.5, 0.5, 1.0)     # Gray
]

var team_colors: Array[Color] = [
	Color.WHITE,
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE,
	Color.CYAN,
	Color.MAGENTA,
	Color(1.0, 0.5, 0.0, 1.0)     # Orange-Red
]

func apply_appearance_to_player(player: Player, appearance_data: Dictionary) -> void:
	"""Apply appearance settings to a player character"""
	if not player or not player.sprite:
		return
	
	# Apply skin color
	var skin_color_index = appearance_data.get("skin_color", 0)
	if skin_color_index < skin_colors.size():
		apply_skin_color(player, skin_colors[skin_color_index])
	
	# Apply hair style and color
	var hair_style_index = appearance_data.get("hair_style", 0)
	var hair_color_index = appearance_data.get("hair_color", 0)
	apply_hair_appearance(player, hair_style_index, hair_color_index)
	
	# Apply jersey color
	var jersey_color_index = appearance_data.get("jersey_color", 0)
	if jersey_color_index < team_colors.size():
		apply_jersey_color(player, team_colors[jersey_color_index])
	
	# Apply shorts color
	var shorts_color_index = appearance_data.get("shorts_color", 0)
	if shorts_color_index < team_colors.size():
		apply_shorts_color(player, team_colors[shorts_color_index])
	
	# Apply equipment visuals
	apply_equipment_visuals(player)
	
	appearance_updated.emit(player)

func apply_skin_color(player: Player, color: Color) -> void:
	"""Apply skin color to player"""
	# This would typically modify the skin texture or use a shader
	# For now, we'll use modulation as a simple example
	if player.sprite:
		# Create a skin color node if it doesn't exist
		var skin_node = player.get_node_or_null("SkinColor")
		if not skin_node:
			skin_node = Sprite2D.new()
			skin_node.name = "SkinColor"
			player.add_child(skin_node)
		
		if skin_node is Sprite2D:
			skin_node.modulate = color

func apply_hair_appearance(player: Player, style_index: int, color_index: int) -> void:
	"""Apply hair style and color to player"""
	var hair_node = player.get_node_or_null("HairSprite")
	if not hair_node:
		hair_node = Sprite2D.new()
		hair_node.name = "HairSprite"
		player.add_child(hair_node)
	
	if hair_node is Sprite2D:
		# Load hair texture based on style
		if style_index < hair_textures.size():
			var texture_path = hair_textures[style_index]
			if ResourceLoader.exists(texture_path):
				hair_node.texture = load(texture_path)
		
		# Apply hair color
		if color_index < hair_colors.size():
			hair_node.modulate = hair_colors[color_index]

func apply_jersey_color(player: Player, color: Color) -> void:
	"""Apply jersey color to player"""
	var jersey_node = player.get_node_or_null("JerseySprite")
	if not jersey_node:
		jersey_node = Sprite2D.new()
		jersey_node.name = "JerseySprite"
		player.add_child(jersey_node)
	
	if jersey_node is Sprite2D:
		jersey_node.modulate = color

func apply_shorts_color(player: Player, color: Color) -> void:
	"""Apply shorts color to player"""
	var shorts_node = player.get_node_or_null("ShortsSprite")
	if not shorts_node:
		shorts_node = Sprite2D.new()
		shorts_node.name = "ShortsSprite"
		player.add_child(shorts_node)
	
	if shorts_node is Sprite2D:
		shorts_node.modulate = color

func apply_equipment_visuals(player: Player) -> void:
	"""Apply visual effects from equipped items"""
	if not player.player_data:
		return
	
	for item in player.player_data.equipment:
		if not item:
			continue
		
		match item.equipment_type:
			EquipmentItem.EquipmentType.SHOES:
				apply_shoes_visual(player, item)
			EquipmentItem.EquipmentType.JERSEY:
				apply_jersey_visual(player, item)
			EquipmentItem.EquipmentType.SHORTS:
				apply_shorts_visual(player, item)
			EquipmentItem.EquipmentType.GLOVES:
				apply_gloves_visual(player, item)
			EquipmentItem.EquipmentType.HEADBAND:
				apply_headband_visual(player, item)
			EquipmentItem.EquipmentType.ACCESSORY:
				apply_accessory_visual(player, item)

func apply_shoes_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply shoes visual effect"""
	var shoes_node = player.get_node_or_null("ShoesSprite")
	if not shoes_node:
		shoes_node = Sprite2D.new()
		shoes_node.name = "ShoesSprite"
		player.add_child(shoes_node)
	
	if shoes_node is Sprite2D:
		# Load shoes texture if available
		if item.icon_path and ResourceLoader.exists(item.icon_path):
			shoes_node.texture = load(item.icon_path)
		
		# Apply visual data
		var visual_color = item.visual_data.get("color", Color.WHITE)
		shoes_node.modulate = visual_color

func apply_jersey_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply jersey visual effect"""
	var jersey_node = player.get_node_or_null("JerseySprite")
	if jersey_node and jersey_node is Sprite2D:
		# Apply equipment-specific jersey modifications
		var visual_color = item.visual_data.get("color", Color.WHITE)
		jersey_node.modulate = visual_color
		
		# Add rarity glow effect for higher tier items
		if item.rarity >= EquipmentItem.Rarity.RARE:
			add_glow_effect(jersey_node, item.get_rarity_color())

func apply_shorts_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply shorts visual effect"""
	var shorts_node = player.get_node_or_null("ShortsSprite")
	if shorts_node and shorts_node is Sprite2D:
		var visual_color = item.visual_data.get("color", Color.WHITE)
		shorts_node.modulate = visual_color

func apply_gloves_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply gloves visual effect"""
	var gloves_node = player.get_node_or_null("GlovesSprite")
	if not gloves_node:
		gloves_node = Sprite2D.new()
		gloves_node.name = "GlovesSprite"
		player.add_child(gloves_node)
	
	if gloves_node is Sprite2D:
		if item.icon_path and ResourceLoader.exists(item.icon_path):
			gloves_node.texture = load(item.icon_path)
		
		var visual_color = item.visual_data.get("color", Color.WHITE)
		gloves_node.modulate = visual_color

func apply_headband_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply headband visual effect"""
	var headband_node = player.get_node_or_null("HeadbandSprite")
	if not headband_node:
		headband_node = Sprite2D.new()
		headband_node.name = "HeadbandSprite"
		player.add_child(headband_node)
	
	if headband_node is Sprite2D:
		if item.icon_path and ResourceLoader.exists(item.icon_path):
			headband_node.texture = load(item.icon_path)
		
		var visual_color = item.visual_data.get("color", Color.WHITE)
		headband_node.modulate = visual_color

func apply_accessory_visual(player: Player, item: EquipmentItem) -> void:
	"""Apply accessory visual effect"""
	var accessory_node = player.get_node_or_null("AccessorySprite")
	if not accessory_node:
		accessory_node = Sprite2D.new()
		accessory_node.name = "AccessorySprite"
		player.add_child(accessory_node)
	
	if accessory_node is Sprite2D:
		if item.icon_path and ResourceLoader.exists(item.icon_path):
			accessory_node.texture = load(item.icon_path)
		
		var visual_color = item.visual_data.get("color", Color.WHITE)
		accessory_node.modulate = visual_color

func add_glow_effect(node: Sprite2D, glow_color: Color) -> void:
	"""Add glow effect to a sprite for rare items"""
	# Remove existing glow
	var existing_glow = node.get_node_or_null("GlowEffect")
	if existing_glow:
		existing_glow.queue_free()
	
	# Create new glow effect
	var glow_sprite = Sprite2D.new()
	glow_sprite.name = "GlowEffect"
	glow_sprite.texture = node.texture
	glow_sprite.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.3)
	glow_sprite.z_index = -1
	glow_sprite.scale = Vector2(1.1, 1.1)
	node.add_child(glow_sprite)
	
	# Animate the glow
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow_sprite, "modulate:a", 0.1, 1.0)
	tween.tween_property(glow_sprite, "modulate:a", 0.3, 1.0)

func get_total_appearance_combinations() -> int:
	"""Calculate total number of appearance combinations"""
	return skin_colors.size() * hair_textures.size() * hair_colors.size() * team_colors.size() * team_colors.size()

func create_random_appearance() -> Dictionary:
	"""Create a random appearance configuration"""
	return {
		"skin_color": randi() % skin_colors.size(),
		"hair_style": randi() % hair_textures.size(),
		"hair_color": randi() % hair_colors.size(),
		"jersey_color": randi() % team_colors.size(),
		"shorts_color": randi() % team_colors.size()
	}

func get_appearance_preview_data() -> Dictionary:
	"""Get data for appearance preview in UI"""
	return {
		"skin_colors": skin_colors,
		"hair_colors": hair_colors,
		"team_colors": team_colors,
		"total_combinations": get_total_appearance_combinations()
	}