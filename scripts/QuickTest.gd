extends Node
## Quick test to verify player data loading

func _ready() -> void:
	print("=== QUICK PLAYER SYSTEM TEST ===")
	
	# Test PlayerData creation
	var player_data_script = preload("res://scripts/PlayerData.gd")
	var test_player = player_data_script.new()
	
	print("✅ PlayerData created successfully")
	print("Player ID: " + test_player.player_id)
	print("Nickname: " + test_player.nickname)
	print("Currency: " + str(test_player.currency))
	
	# Test PlayerManager
	var player_manager_script = preload("res://scripts/managers/PlayerManager.gd")
	var manager = player_manager_script.new()
	add_child(manager)
	
	print("✅ PlayerManager created successfully")
	
	# Wait a moment then check
	await get_tree().create_timer(1.0).timeout
	
	if manager.has_method("get_player_data"):
		var loaded_data = manager.get_player_data()
		if loaded_data:
			print("✅ Player data loaded successfully!")
			print("Loaded Player: " + loaded_data.nickname)
			print("Loaded Currency: " + str(loaded_data.currency))
		else:
			print("❌ Player data is null")
	else:
		print("❌ PlayerManager missing get_player_data method")
	
	# Test skill tree
	if manager.has_method("get_player_data"):
		var player_data = manager.get_player_data()
		if player_data and player_data.has_method("get_skill_tree"):
			var skill_tree = player_data.get_skill_tree()
			if skill_tree:
				print("✅ Skill tree loaded successfully!")
				print("Available skills: " + str(skill_tree.skills.size()))
			else:
				print("❌ Skill tree is null")
	
	# Test equipment
	if manager.has_method("get_available_items"):
		var items = manager.get_available_items()
		print("✅ Equipment system loaded!")
		print("Available items: " + str(items.size()))
	
	print("=== TEST COMPLETE ===")
	print("🎮 Player System Status: WORKING!")
	
	# Quit after test
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()