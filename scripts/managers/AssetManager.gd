extends Node
## AssetManager singleton for managing game resources and optimization
## Handles dynamic loading, compression, and memory management

signal assets_loaded(sport_type: GameManager.SportType)
signal assets_unloaded(sport_type: GameManager.SportType)

# Resource caches
var texture_cache: Dictionary = {}
var audio_cache: Dictionary = {}
var scene_cache: Dictionary = {}
var current_sport_assets: GameManager.SportType = GameManager.SportType.BASKETBALL

# Memory management
var memory_threshold_mb: float = 400.0  # Trigger cleanup at 400MB
var max_cache_size: int = 50  # Maximum cached resources

func _ready() -> void:
	print("AssetManager initialized")
	# Preload essential assets
	preload_essential_assets()

func preload_essential_assets() -> void:
	"""Preload core game assets that are always needed"""
	print("Preloading essential assets...")
	
	# Load default textures and UI elements
	var essential_paths = [
		"res://icon.svg"
	]
	
	for path in essential_paths:
		if ResourceLoader.exists(path):
			var resource = load(path)
			texture_cache[path] = resource
			print("Preloaded: ", path)

func load_sport_assets(sport_type: GameManager.SportType) -> void:
	"""Load assets for a specific sport"""
	print("Loading assets for sport: ", GameManager.SportType.keys()[sport_type])
	
	# Unload previous sport assets if different
	if current_sport_assets != sport_type:
		unload_sport_assets(current_sport_assets)
	
	current_sport_assets = sport_type
	
	# Define sport-specific asset paths
	var sport_assets = get_sport_asset_paths(sport_type)
	
	# Load sport assets
	for asset_path in sport_assets:
		if ResourceLoader.exists(asset_path):
			var resource = load_asset_safe(asset_path)
			if resource:
				cache_resource(asset_path, resource)
	
	assets_loaded.emit(sport_type)
	print("Assets loaded for sport: ", GameManager.SportType.keys()[sport_type])

func unload_sport_assets(sport_type: GameManager.SportType) -> void:
	"""Unload assets for a specific sport to free memory"""
	print("Unloading assets for sport: ", GameManager.SportType.keys()[sport_type])
	
	var sport_assets = get_sport_asset_paths(sport_type)
	
	for asset_path in sport_assets:
		if texture_cache.has(asset_path):
			texture_cache.erase(asset_path)
		if audio_cache.has(asset_path):
			audio_cache.erase(asset_path)
		if scene_cache.has(asset_path):
			scene_cache.erase(asset_path)
	
	# Force garbage collection
	trigger_garbage_collection()
	assets_unloaded.emit(sport_type)

func unload_unused_assets() -> void:
	"""Clean up unused assets to free memory"""
	print("Cleaning up unused assets...")
	
	# Check memory usage
	var memory_usage = get_memory_usage_mb()
	if memory_usage > memory_threshold_mb:
		print("Memory usage high (", memory_usage, "MB), cleaning up...")
		
		# Clear caches if they're too large
		if texture_cache.size() > max_cache_size:
			var keys_to_remove = texture_cache.keys().slice(0, texture_cache.size() - max_cache_size)
			for key in keys_to_remove:
				texture_cache.erase(key)
		
		trigger_garbage_collection()

func get_compressed_texture(path: String) -> Texture2D:
	"""Get a compressed texture, loading if not cached"""
	if texture_cache.has(path):
		return texture_cache[path]
	
	var texture = load_asset_safe(path)
	if texture and texture is Texture2D:
		cache_resource(path, texture)
		return texture
	
	return null

func get_audio_resource(path: String) -> AudioStream:
	"""Get an audio resource, loading if not cached"""
	if audio_cache.has(path):
		return audio_cache[path]
	
	var audio = load_asset_safe(path)
	if audio and audio is AudioStream:
		cache_resource(path, audio)
		return audio
	
	return null

func get_scene_resource(path: String) -> PackedScene:
	"""Get a scene resource, loading if not cached"""
	if scene_cache.has(path):
		return scene_cache[path]
	
	var scene = load_asset_safe(path)
	if scene and scene is PackedScene:
		cache_resource(path, scene)
		return scene
	
	return null

func load_asset_safe(path: String) -> Resource:
	"""Safely load a resource with error handling"""
	if not ResourceLoader.exists(path):
		push_error("Asset not found: " + path)
		return null
	
	var resource = load(path)
	if not resource:
		push_error("Failed to load asset: " + path)
		return null
	
	return resource

func cache_resource(path: String, resource: Resource) -> void:
	"""Cache a resource in the appropriate cache"""
	if resource is Texture2D:
		texture_cache[path] = resource
	elif resource is AudioStream:
		audio_cache[path] = resource
	elif resource is PackedScene:
		scene_cache[path] = resource

func get_sport_asset_paths(sport_type: GameManager.SportType) -> Array[String]:
	"""Get asset paths for a specific sport"""
	var paths: Array[String] = []
	
	match sport_type:
		GameManager.SportType.BASKETBALL:
			paths = [
				"res://assets/textures/basketball_court.png",
				"res://assets/textures/basketball.png",
				"res://assets/textures/basketball_hoop.png",
				"res://assets/audio/basketball_bounce.ogg",
				"res://scenes/sports/BasketballScene.tscn"
			]
		GameManager.SportType.FOOTBALL:
			paths = [
				"res://assets/textures/football_field.png",
				"res://assets/textures/football.png",
				"res://assets/textures/football_goal.png",
				"res://assets/audio/football_kick.ogg",
				"res://scenes/sports/FootballScene.tscn"
			]
		GameManager.SportType.TENNIS:
			paths = [
				"res://assets/textures/tennis_court.png",
				"res://assets/textures/tennis_ball.png",
				"res://assets/textures/tennis_racket.png",
				"res://assets/audio/tennis_hit.ogg",
				"res://scenes/sports/TennisScene.tscn"
			]
	
	return paths

func get_memory_usage_mb() -> float:
	"""Get current memory usage in MB"""
	var memory_usage = OS.get_static_memory_usage_by_type()
	var total_mb = 0.0
	
	for usage in memory_usage.values():
		total_mb += float(usage) / (1024.0 * 1024.0)
	
	return total_mb

func trigger_garbage_collection() -> void:
	"""Force garbage collection to free memory"""
	print("Triggering garbage collection...")
	# In Godot, we can't directly force GC, but we can help by clearing references
	# The engine will handle GC automatically
	pass

func get_cache_stats() -> Dictionary:
	"""Get statistics about cached resources"""
	return {
		"texture_cache_size": texture_cache.size(),
		"audio_cache_size": audio_cache.size(),
		"scene_cache_size": scene_cache.size(),
		"memory_usage_mb": get_memory_usage_mb()
	}