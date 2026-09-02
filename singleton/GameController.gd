extends Node

# State Machine
enum GameState {
	IDLE,
	ROLLING,
	MOVING,
	SPECIAL_EVENT,
	TURN_END,
	GAME_OVER
}

var current_state: GameState = GameState.IDLE
var active_player_id: int = 1
var is_game_active: bool = false  # Starts false — waits for player selection
var total_turns: int = 0
var num_players: int = 3  # Set by PlayerSelect

# Player references registered at runtime
var player_tokens: Dictionary = {}

# Stats tracking
var stats: Dictionary = {
	1: {"rolls": 0, "ladders": 0, "snakes": 0, "name": "Iron Man"},
	2: {"rolls": 0, "ladders": 0, "snakes": 0, "name": "Spider-Man"},
	3: {"rolls": 0, "ladders": 0, "snakes": 0, "name": "Wonder Woman"}
}

# Signals
signal state_changed(new_state: GameState)
signal turn_changed(player_id: int, current_cell: int)
signal roll_started(player_id: int)
signal dice_rolled(player_id: int, steps: int)
signal player_turn_finished(player_id: int, final_cell: int)
signal special_tile_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)
signal game_won(winner_player_id: int, game_stats: Dictionary)
signal game_restarted()
signal log_message(text: String, message_type: String)
signal players_configured(count: int)

func _ready() -> void:
	_setup_input_map()
	call_deferred("_connect_player_select")

func _setup_input_map() -> void:
	if not InputMap.has_action("roll_dice"):
		InputMap.add_action("roll_dice")

		var ev_space := InputEventKey.new()
		ev_space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("roll_dice", ev_space)

		var ev_enter := InputEventKey.new()
		ev_enter.physical_keycode = KEY_ENTER
		InputMap.action_add_event("roll_dice", ev_enter)

		var ev_mouse := InputEventMouseButton.new()
		ev_mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("roll_dice", ev_mouse)

func _connect_player_select() -> void:
	var ps = get_tree().root.find_child("PlayerSelect", true, false)
	if ps and ps.has_signal("players_selected"):
		ps.players_selected.connect(_on_players_selected)
	else:
		# No selection screen — default to 3 players
		_on_players_selected(3)

func _on_players_selected(count: int) -> void:
	num_players = clampi(count, 1, 3)
	_register_players()
	players_configured.emit(num_players)

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
	if event.is_action_pressed("roll_dice"):
		request_roll()

func _register_players() -> void:
	player_tokens.clear()
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if p is Player:
			if p.player_id <= num_players:
				player_tokens[p.player_id] = p
				p.visible = true
				if not p.move_finished.is_connected(_on_player_moved):
					p.move_finished.connect(_on_player_moved)
				if not p.special_triggered.is_connected(_on_player_special_triggered):
					p.special_triggered.connect(_on_player_special_triggered)
			else:
				p.visible = false

	active_player_id = 1
	is_game_active = true
	current_state = GameState.IDLE
	state_changed.emit(current_state)
	turn_changed.emit(active_player_id, get_active_player_cell())

	var hero_names := []
	for i in range(1, num_players + 1):
		hero_names.append(get_hero_name(i))
	log_message.emit("🌟 %s — GAME ON! %s's turn!" % [" vs ".join(hero_names), get_hero_name(1)], "info")

	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_bgm("gameplay", 1.2)

func get_active_player_cell() -> int:
	if player_tokens.has(active_player_id):
		return player_tokens[active_player_id].current_cell
	return 1

func get_hero_name(p_id: int) -> String:
	match p_id:
		1: return "Iron Man"
		2: return "Spider-Man"
		3: return "Wonder Woman"
		_: return "Player %d" % p_id

func request_roll() -> void:
	if current_state != GameState.IDLE or not is_game_active:
		return

	_set_state(GameState.ROLLING)
	roll_started.emit(active_player_id)

	stats[active_player_id]["rolls"] += 1
	total_turns += 1

	var rolled_value := randi_range(1, 6)

	log_message.emit("🎲 %s rolled a %d!" % [get_hero_name(active_player_id), rolled_value], "roll")
	dice_rolled.emit(active_player_id, rolled_value)

	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx(AudioManager.SFX.DICE_ROLL, 0.1)

	get_tree().create_timer(0.9).timeout.connect(func():
		_execute_move(rolled_value)
	)

func _execute_move(steps: int) -> void:
	_set_state(GameState.MOVING)
	if player_tokens.has(active_player_id):
		var p: Player = player_tokens[active_player_id]
		p.move_steps(steps)
	else:
		_end_turn()

func _on_player_moved(p_id: int, final_cell: int) -> void:
	if p_id != active_player_id:
		return

	player_turn_finished.emit(p_id, final_cell)

	if final_cell == 100:
		_set_state(GameState.GAME_OVER)
		is_game_active = false
		var game_summary := {
			"winner": active_player_id,
			"winner_name": get_hero_name(active_player_id),
			"total_turns": total_turns,
			"player_stats": stats[active_player_id]
		}
		log_message.emit("🏆 %s reached tile 100 and WON THE GAME!" % get_hero_name(active_player_id), "win")
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_sfx(AudioManager.SFX.WIN_FANFARE, 0.0)
			am.stop_bgm(1.5)
		game_won.emit(active_player_id, game_summary)
		return

	_end_turn()

func _on_player_special_triggered(p_id: int, is_ladder: bool, from_cell: int, to_cell: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if is_ladder:
		stats[p_id]["ladders"] += 1
		log_message.emit("🌈 %s powered up a ladder from %d to %d!" % [get_hero_name(p_id), from_cell, to_cell], "ladder")
		if am:
			am.play_sfx(AudioManager.SFX.LADDER_WHOOSH, 0.1)
	else:
		stats[p_id]["snakes"] += 1
		log_message.emit("🐍 %s slid down a snake from %d to %d!" % [get_hero_name(p_id), from_cell, to_cell], "snake")
		if am:
			am.play_sfx(AudioManager.SFX.SNAKE_SLIDE, 0.1)

	special_tile_triggered.emit(p_id, is_ladder, from_cell, to_cell)

func _end_turn() -> void:
	_set_state(GameState.TURN_END)

	# Cycle through only active players
	active_player_id = (active_player_id % num_players) + 1

	get_tree().create_timer(0.35).timeout.connect(func():
		_set_state(GameState.IDLE)
		turn_changed.emit(active_player_id, get_active_player_cell())
		log_message.emit("🎯 %s's turn! Roll the dice!" % get_hero_name(active_player_id), "turn")
	)

func restart_game() -> void:
	total_turns = 0
	for p_id in stats.keys():
		stats[p_id]["rolls"] = 0
		stats[p_id]["ladders"] = 0
		stats[p_id]["snakes"] = 0

	for p in player_tokens.values():
		p.reset_to_start()
		p.global_position = get_tree().root.find_child("Board", true, false).get_cell_position(1)

	active_player_id = 1
	is_game_active = true
	_set_state(GameState.IDLE)
	game_restarted.emit()
	turn_changed.emit(active_player_id, 1)
	log_message.emit("🌟 New Game! %s's turn!" % get_hero_name(1), "info")

	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_bgm("gameplay", 1.0)

func _set_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
