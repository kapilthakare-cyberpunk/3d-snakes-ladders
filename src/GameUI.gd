class_name GameUI
extends CanvasLayer

@onready var turn_label: Label = $TopBar/MarginContainer/HBoxContainer/TurnLabel
@onready var p1_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P1Card/P1CellLabel
@onready var p2_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P2Card/P2CellLabel
@onready var p1_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P1Card
@onready var p2_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P2Card

@onready var roll_button: Button = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollButton
@onready var roll_result_label: Label = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollResultBadge/RollResultLabel
@onready var log_label: Label = $BottomPanel/MarginContainer/VBoxContainer/LogBanner/LogLabel

@onready var victory_modal: Control = $VictoryModal
@onready var victory_title: Label = $VictoryModal/PanelContainer/MarginContainer/VBoxContainer/VictoryTitle
@onready var victory_stats: Label = $VictoryModal/PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var play_again_button: Button = $VictoryModal/PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton

func _ready() -> void:
	victory_modal.visible = false
	roll_button.pressed.connect(_on_roll_button_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		var gc = get_node("/root/GameController")
		gc.turn_changed.connect(_on_turn_changed)
		gc.roll_started.connect(_on_roll_started)
		gc.dice_rolled.connect(_on_dice_rolled)
		gc.player_turn_finished.connect(_on_player_turn_finished)
		gc.log_message.connect(_on_log_message)
		gc.game_won.connect(_on_game_won)
		gc.game_restarted.connect(_on_game_restarted)

func _on_roll_button_pressed() -> void:
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		get_node("/root/GameController").request_roll()

func _on_play_again_pressed() -> void:
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		get_node("/root/GameController").restart_game()

func _on_turn_changed(player_id: int, current_cell: int) -> void:
	roll_button.disabled = false
	turn_label.text = "🎯 PLAYER %d'S TURN" % player_id
	
	if player_id == 1:
		turn_label.modulate = Color(0.95, 0.3, 0.35, 1.0)
		p1_card.modulate = Color(1.2, 1.2, 1.2, 1.0)
		p2_card.modulate = Color(0.7, 0.7, 0.7, 0.8)
	else:
		turn_label.modulate = Color(0.2, 0.75, 1.0, 1.0)
		p1_card.modulate = Color(0.7, 0.7, 0.7, 0.8)
		p2_card.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_roll_started(player_id: int) -> void:
	roll_button.disabled = true
	roll_result_label.text = "🎲 Rolling..."

func _on_dice_rolled(player_id: int, steps: int) -> void:
	roll_result_label.text = "🎲 Rolled: %d" % steps

func _on_player_turn_finished(player_id: int, final_cell: int) -> void:
	if player_id == 1:
		p1_cell_label.text = "Cell %d" % final_cell
	else:
		p2_cell_label.text = "Cell %d" % final_cell

func _on_log_message(text: String, message_type: String) -> void:
	log_label.text = text
	
	# Colorize log text based on message type
	if message_type == "ladder":
		log_label.modulate = Color(0.3, 0.9, 0.5, 1.0)
	elif message_type == "snake":
		log_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
	elif message_type == "win":
		log_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		log_label.modulate = Color(0.9, 0.9, 0.9, 1.0)

func _on_game_won(winner_id: int, game_stats: Dictionary) -> void:
	victory_modal.visible = true
	roll_button.disabled = true
	
	victory_title.text = "🏆 PLAYER %d WINS! 🏆" % winner_id
	if winner_id == 1:
		victory_title.modulate = Color(0.95, 0.3, 0.35, 1.0)
	else:
		victory_title.modulate = Color(0.2, 0.75, 1.0, 1.0)
	
	var turns = game_stats.get("total_turns", 0)
	var p_stats = game_stats.get("player_stats", {})
	var ladders = p_stats.get("ladders", 0)
	var snakes = p_stats.get("snakes", 0)
	var rolls = p_stats.get("rolls", 0)
	
	victory_stats.text = "Game Statistics:\n• Total Turns Taken: %d\n• Dice Rolls: %d\n• Ladders Climbed: %d\n• Snakes Encountered: %d" % [turns, rolls, ladders, snakes]

func _on_game_restarted() -> void:
	victory_modal.visible = false
	p1_cell_label.text = "Cell 1"
	p2_cell_label.text = "Cell 1"
	roll_result_label.text = "🎲 Ready"
	roll_button.disabled = false
