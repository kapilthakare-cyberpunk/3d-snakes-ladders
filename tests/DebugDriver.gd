extends Node
# Temporary end-to-end smoke driver. Runs the real game (autoloads + Main.tscn)
# headless: verifies the board populated, players registered, the roll_dice
# action loaded, and that two injected rolls move both tokens. Delete after use.

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	_log_state("initial")
	await _press_roll_once()
	await get_tree().create_timer(1.8).timeout
	_log_state("after-roll-player1")
	await _press_roll_once()
	await get_tree().create_timer(1.8).timeout
	_log_state("after-roll-player2")
	get_tree().quit()

func _press_roll_once() -> void:
	Input.action_press("roll_dice")
	await get_tree().process_frame
	Input.action_release("roll_dice")

func _log_state(label: String) -> void:
	var board := get_node_or_null("/root/Board")
	var gc := get_node_or_null("/root/GameController")
	print("SMOKE[%s] action_roll_dice=%s" % [label, InputMap.has_action("roll_dice")])
	if board:
		var cells = board.get("cells")
		print("SMOKE[%s] cells=%d board_children=%d" % [label, cells.size() if cells else -1, board.get_child_count()])
	if gc:
		var ps: Array = gc.get("players")
		var out: Array[String] = []
		for p in ps:
			out.append("%s@cell%d" % [p.name, p.get("current_cell")])
		print("SMOKE[%s] players=%d [%s] next_player_index=%d" % [label, ps.size(), ", ".join(out), gc.get("current_player_index")])