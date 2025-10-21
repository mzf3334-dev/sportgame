extends Node
## Main scene controller that manages the overall game flow

@onready var ui_layer: CanvasLayer = $UI
@onready var main_menu: Control = $UI/MainMenu
@onready var game_hud: Control = $UI/GameHUD
@onready var mobile_controls: Control = $UI/MobileControls
@onready var game_world: Node2D = $GameWorld
@onready var field: Node2D = $GameWorld/Field
@onready var players: Node2D = $GameWorld/Players
@onready var effects: Node2D = $GameWorld/Effects

func _ready() -> void:
	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.sport_changed.connect(_on_sport_changed)
	
	# Set up mobile controls
	setup_mobile_controls()
	
	# Initialize the main menu
	show_main_menu()

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.MENU:
			show_main_menu()
		GameManager.GameState.PLAYING:
			show_game_hud()
		GameManager.GameState.PAUSED:
			# Handle pause state
			pass
		GameManager.GameState.GAME_OVER:
			# Handle game over state
			pass

func _on_sport_changed(sport_type: GameManager.SportType) -> void:
	# Clear current field
	for child in field.get_children():
		child.queue_free()
	
	# Load new sport field (will be implemented in later tasks)
	print("Sport changed to: ", GameManager.SportType.keys()[sport_type])

func show_main_menu() -> void:
	main_menu.visible = true
	game_hud.visible = false
	mobile_controls.visible = false

func show_game_hud() -> void:
	main_menu.visible = false
	game_hud.visible = true
	mobile_controls.visible = true

func setup_mobile_controls() -> void:
	# Add MobileControlPanel script to the MobileControls node
	var mobile_control_panel = preload("res://scripts/ui/MobileControlPanel.gd").new()
	mobile_controls.add_child(mobile_control_panel)
	
	# Connect mobile control signals
	mobile_control_panel.action_triggered.connect(_on_mobile_action_triggered)
	mobile_control_panel.control_layout_changed.connect(_on_control_layout_changed)

func _on_mobile_action_triggered(action_name: String, strength: float, position: Vector2) -> void:
	# Handle mobile control actions
	print("Mobile action: ", action_name, " strength: ", strength, " at: ", position)
	
	# Forward to InputController for processing
	if InputController:
		InputController.action_performed.emit(action_name, strength, position)

func _on_control_layout_changed(layout_name: String) -> void:
	print("Control layout changed to: ", layout_name)