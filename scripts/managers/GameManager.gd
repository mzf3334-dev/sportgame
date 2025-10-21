extends Node
## GameManager singleton that handles game state and sport management
## Autoloaded as a singleton to manage global game state

signal game_state_changed(new_state: GameState)
signal sport_changed(sport_type: SportType)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
enum SportType { BASKETBALL, FOOTBALL, TENNIS }

var current_state: GameState = GameState.MENU
var current_sport: SportType = SportType.BASKETBALL
var players: Array[PlayerData] = []
var game_time: float = 0.0
var match_settings: Dictionary = {}

func _ready() -> void:
	print("GameManager initialized")
	# Set process to handle game time updates
	set_process(false)

func change_game_state(new_state: GameState) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		print("Game state changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
		game_state_changed.emit(new_state)
		
		# Handle state-specific logic
		match new_state:
			GameState.PLAYING:
				start_game_timer()
			GameState.PAUSED, GameState.MENU, GameState.GAME_OVER:
				stop_game_timer()

func change_sport(new_sport: SportType) -> void:
	if current_sport != new_sport:
		var old_sport = current_sport
		current_sport = new_sport
		print("Sport changed from ", SportType.keys()[old_sport], " to ", SportType.keys()[new_sport])
		sport_changed.emit(new_sport)

func start_game_timer() -> void:
	game_time = 0.0
	set_process(true)

func stop_game_timer() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_time += delta

func get_current_state() -> GameState:
	return current_state

func get_current_sport() -> SportType:
	return current_sport

func get_game_time() -> float:
	return game_time

func add_player(player_data: PlayerData) -> void:
	players.append(player_data)

func remove_player(player_id: String) -> void:
	for i in range(players.size()):
		if players[i].player_id == player_id:
			players.remove_at(i)
			break

func get_players() -> Array[PlayerData]:
	return players

func set_match_settings(settings: Dictionary) -> void:
	match_settings = settings

func get_match_settings() -> Dictionary:
	return match_settings

## Get sport name from SportType enum
static func get_sport_name(sport_type: SportType) -> String:
	match sport_type:
		SportType.BASKETBALL:
			return "Basketball"
		SportType.FOOTBALL:
			return "Football"
		SportType.TENNIS:
			return "Tennis"
		_:
			return "Unknown"