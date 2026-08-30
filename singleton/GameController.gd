extends Node

## GameController - Central game manager & turn coordinator (AutoLoad)

enum GameState {
	WAITING_FOR_ROLL,
	ROLLING_DICE,
	MOVING_TOKEN,
	SPECIAL_MOVE,
	GAME_OVER
}

signal turn_changed(player_id: int, current_cell: int)
signal roll_started(player_id: int)
signal dice_rolled(player_id: int, steps: int)
signal player_move_started(player_id: int, from_cell: int, to_cell: int)
signal special_tile_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)
signal player_turn_finished(player_id: int, final_cell: int)
signal game_won(player_id: int, stats: Dictionary)
signal game_restarted()
signal log_message(text: String, message_type: String)

var current_state: GameState = GameState.WAITING_FOR_ROLL
var players: Array = []
var current_player_index: int = 0
var dice = null

var total_turns: int = 0
var stats: Dictionary = {
	1: {"rolls": 0, "ladders": 0, "snakes": 0},
	2: {"rolls": 0, "ladders": 0, "snakes": 0}
}

func _ready() -> void:
	dice = load("res://src/DiceRoll.gd").new()
	_register_players.call_deferred()

func _process(_delta: float) -> void:
	if players.is_empty():
		var found := get_tree().get_nodes_in_group("players")
		if not found.is_empty():
			_register_players()

func _register_players() -> void:
	var found := get_tree().get_nodes_in_group("players")
	if found.is_empty():
		return
	
	players.clear()
	# Sort players deterministically by player_id
	found.sort_custom(func(a, b):
		var id_a: int = a.player_id if "player_id" in a else 0
		var id_b: int = b.player_id if "player_id" in b else 0
		return id_a < id_b
	)
	
	for i in range(found.size()):
		var node = found[i]
		if node.has_method("move_steps"):
			players.append(node)
			if not node.is_connected("move_finished", Callable(self, "_on_player_moved")):
				node.connect("move_finished", Callable(self, "_on_player_moved"))
			if not node.is_connected("special_triggered", Callable(self, "_on_player_special_triggered")):
				node.connect("special_triggered", Callable(self, "_on_player_special_triggered"))
			if node.has_method("setup_player"):
				node.setup_player(i + 1)
	
	if not players.is_empty():
		var active_player = players[current_player_index]
		turn_changed.emit(active_player.player_id, active_player.current_cell)
		log_message.emit("Game started! Player 1's turn to roll.", "info")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		request_roll()

func request_roll() -> void:
	if current_state != GameState.WAITING_FOR_ROLL or players.is_empty():
		return
	
	var player = players[current_player_index]
	var p_id: int = player.player_id
	current_state = GameState.ROLLING_DICE
	
	var steps: int = dice.roll()
	if not stats.has(p_id):
		stats[p_id] = {"rolls": 0, "ladders": 0, "snakes": 0}
	stats[p_id]["rolls"] += 1
	total_turns += 1
	
	roll_started.emit(p_id)
	dice_rolled.emit(p_id, steps)
	log_message.emit("Player %d rolled a %d!" % [p_id, steps], "roll")
	
	# Small delay before token movement to allow dice animation to be seen
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		if current_state == GameState.ROLLING_DICE:
			_execute_player_move(player, steps)
	)

func _execute_player_move(player, steps: int) -> void:
	current_state = GameState.MOVING_TOKEN
	var start_cell: int = player.current_cell
	var target_cell: int = min(start_cell + steps, 100)
	player_move_started.emit(player.player_id, start_cell, target_cell)
	player.move_steps(steps)

func _on_player_special_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int) -> void:
	current_state = GameState.SPECIAL_MOVE
	if is_ladder:
		stats[player_id]["ladders"] += 1
		log_message.emit("🚀 Player %d climbed a ladder from %d to %d!" % [player_id, from_cell, to_cell], "ladder")
	else:
		stats[player_id]["snakes"] += 1
		log_message.emit("🐍 Player %d bitten by a snake from %d down to %d!" % [player_id, from_cell, to_cell], "snake")
	
	special_tile_triggered.emit(player_id, is_ladder, from_cell, to_cell)

func _on_player_moved(player_id: int, final_cell: int) -> void:
	player_turn_finished.emit(player_id, final_cell)
	
	# Update positions for all players to adjust any visual offsets
	_update_all_token_offsets()
	
	if final_cell >= 100:
		current_state = GameState.GAME_OVER
		log_message.emit("🎉 PLAYER %d WINS THE GAME! 🎉" % player_id, "win")
		game_won.emit(player_id, {
			"total_turns": total_turns,
			"player_stats": stats.get(player_id, {}),
			"all_stats": stats
		})
		return
	
	# Advance turn
	current_player_index = (current_player_index + 1) % players.size()
	current_state = GameState.WAITING_FOR_ROLL
	var next_player = players[current_player_index]
	turn_changed.emit(next_player.player_id, next_player.current_cell)
	log_message.emit("Player %d's turn. Roll the dice!" % next_player.player_id, "turn")

func _update_all_token_offsets() -> void:
	var board = get_tree().root.find_child("Board", true, false)
	if not board or not board.has_method("get_cell_position"):
		return
	
	# Group players by current cell
	var cell_groups: Dictionary = {}
	for player in players:
		var cell: int = player.current_cell
		if not cell_groups.has(cell):
			cell_groups[cell] = []
		cell_groups[cell].append(player)
	
	# Apply offsets for tokens sharing cells when they are not currently moving
	for cell in cell_groups.keys():
		var group: Array = cell_groups[cell]
		for idx in range(group.size()):
			var p = group[idx]
			if not p.is_moving:
				var pos: Vector3 = board.get_cell_position(cell, idx, group.size())
				p.global_position = pos

func restart_game() -> void:
	total_turns = 0
	stats = {
		1: {"rolls": 0, "ladders": 0, "snakes": 0},
		2: {"rolls": 0, "ladders": 0, "snakes": 0}
	}
	current_player_index = 0
	current_state = GameState.WAITING_FOR_ROLL
	
	var board = get_tree().root.find_child("Board", true, false)
	for i in range(players.size()):
		var p = players[i]
		if p.has_method("reset_to_start"):
			p.reset_to_start()
		if board and board.has_method("get_cell_position"):
			p.global_position = board.get_cell_position(1, i, players.size())
	
	game_restarted.emit()
	if not players.is_empty():
		var active_player = players[0]
		turn_changed.emit(active_player.player_id, 1)
		log_message.emit("Game reset! Player 1's turn.", "info")
