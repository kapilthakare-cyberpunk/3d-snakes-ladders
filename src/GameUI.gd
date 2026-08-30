class_name GameUI
extends CanvasLayer

@onready var turn_label: Label = $TopBar/MarginContainer/HBoxContainer/TurnContainer/Margin/TurnLabel
@onready var p1_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P1Card
@onready var p2_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P2Card
@onready var p1_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P1Card/Margin/HBox/P1CellLabel
@onready var p2_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P2Card/Margin/HBox/P2CellLabel

@onready var roll_button: Button = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollButton
@onready var roll_result_badge: PanelContainer = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollResultBadge
@onready var roll_result_label: Label = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollResultBadge/RollResultLabel
@onready var log_banner: PanelContainer = $BottomPanel/MarginContainer/VBoxContainer/LogBanner
@onready var log_label: Label = $BottomPanel/MarginContainer/VBoxContainer/LogBanner/LogLabel

@onready var victory_modal: Control = $VictoryModal
@onready var victory_title: Label = $VictoryModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VictoryTitle
@onready var victory_stats: Label = $VictoryModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsLabel
@onready var play_again_button: Button = $VictoryModal/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayAgainButton
@onready var confetti_particles: CPUParticles2D = $VictoryModal/ConfettiParticles

var pulse_tween: Tween

func _ready() -> void:
	victory_modal.visible = false
	roll_button.pressed.connect(_on_roll_button_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	
	_start_button_pulse()
	
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		var gc = get_node("/root/GameController")
		gc.turn_changed.connect(_on_turn_changed)
		gc.roll_started.connect(_on_roll_started)
		gc.dice_rolled.connect(_on_dice_rolled)
		gc.player_turn_finished.connect(_on_player_turn_finished)
		gc.special_tile_triggered.connect(_on_special_tile_triggered)
		gc.log_message.connect(_on_log_message)
		gc.game_won.connect(_on_game_won)
		gc.game_restarted.connect(_on_game_restarted)

func _start_button_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(roll_button, "scale", Vector2(1.05, 1.05), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(roll_button, "scale", Vector2(1.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_roll_button_pressed() -> void:
	# Bouncy button click pop
	var click_pop := create_tween()
	click_pop.tween_property(roll_button, "scale", Vector2(0.92, 0.92), 0.06)
	click_pop.chain().tween_property(roll_button, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		get_node("/root/GameController").request_roll()

func _on_play_again_pressed() -> void:
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		get_node("/root/GameController").restart_game()

func _on_turn_changed(player_id: int, current_cell: int) -> void:
	roll_button.disabled = false
	_start_button_pulse()
	
	if player_id == 1:
		turn_label.text = "🎯 TEDDY RED'S TURN!"
		turn_label.modulate = Color(1.0, 0.35, 0.42, 1.0)
		
		# Animate active card highlight
		var t1 := create_tween()
		t1.tween_property(p1_card, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK)
		var t2 := create_tween()
		t2.tween_property(p2_card, "scale", Vector2(0.95, 0.95), 0.25)
	else:
		turn_label.text = "🎯 BUNNY BLUE'S TURN!"
		turn_label.modulate = Color(0.2, 0.75, 1.0, 1.0)
		
		var t1 := create_tween()
		t1.tween_property(p2_card, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK)
		var t2 := create_tween()
		t2.tween_property(p1_card, "scale", Vector2(0.95, 0.95), 0.25)

func _on_roll_started(player_id: int) -> void:
	roll_button.disabled = true
	if pulse_tween:
		pulse_tween.kill()
	roll_button.scale = Vector2.ONE
	roll_result_label.text = "🎲 Rolling..."

func _on_dice_rolled(player_id: int, steps: int) -> void:
	roll_result_label.text = "🎲 ROLLED %d! ⭐" % steps
	
	# Juicy punch bounce on result badge
	var badge_pop := create_tween()
	badge_pop.tween_property(roll_result_badge, "scale", Vector2(1.25, 1.25), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_pop.chain().tween_property(roll_result_badge, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_player_turn_finished(player_id: int, final_cell: int) -> void:
	if player_id == 1:
		p1_cell_label.text = "Tile %d" % final_cell
	else:
		p2_cell_label.text = "Tile %d" % final_cell

func _on_special_tile_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int) -> void:
	var name_str := "Teddy Red" if player_id == 1 else "Bunny Blue"
	if is_ladder:
		_show_popup_banner("🌈 WHEEEE! %s CLIMBED A RAINBOW LADDER TO %d! 🚀" % [name_str, to_cell], Color(0.3, 0.95, 0.55, 1.0))
	else:
		_show_popup_banner("🐍 WHOOPSIE! %s SLID DOWN TO %d! 🎈" % [name_str, to_cell], Color(1.0, 0.45, 0.55, 1.0))

func _show_popup_banner(msg: String, color: Color) -> void:
	log_label.text = msg
	log_label.modulate = color
	
	var pop := create_tween()
	pop.tween_property(log_banner, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK)
	pop.chain().tween_property(log_banner, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_ELASTIC)

func _on_log_message(text: String, message_type: String) -> void:
	if message_type != "ladder" and message_type != "snake":
		log_label.text = text
		log_label.modulate = Color(1.0, 0.95, 0.85, 1.0)

func _on_game_won(winner_id: int, game_stats: Dictionary) -> void:
	victory_modal.visible = true
	roll_button.disabled = true
	if pulse_tween:
		pulse_tween.kill()
	
	var name_str := "🐻 TEDDY RED" if winner_id == 1 else "🐰 BUNNY BLUE"
	victory_title.text = "🏆 YAAAY! %s WINS! 🌟" % name_str
	if winner_id == 1:
		victory_title.modulate = Color(1.0, 0.35, 0.45, 1.0)
	else:
		victory_title.modulate = Color(0.2, 0.75, 1.0, 1.0)
	
	var turns: int = game_stats.get("total_turns", 0)
	var p_stats: Dictionary = game_stats.get("player_stats", {})
	var ladders: int = p_stats.get("ladders", 0)
	var snakes: int = p_stats.get("snakes", 0)
	var rolls: int = p_stats.get("rolls", 0)
	
	victory_stats.text = "🎉 Star Performance! 🎉\n\n⭐ Total Turns: %d\n🎲 Total Rolls: %d\n🌈 Rainbow Ladders: %d\n🐍 Snake Slides: %d" % [turns, rolls, ladders, snakes]
	
	if confetti_particles:
		confetti_particles.emitting = true
	
	# Modal pop-in animation
	var modal_box = $VictoryModal/CenterContainer/PanelContainer
	modal_box.scale = Vector2(0.5, 0.5)
	var win_pop := create_tween()
	win_pop.tween_property(modal_box, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_game_restarted() -> void:
	victory_modal.visible = false
	if confetti_particles:
		confetti_particles.emitting = false
	p1_cell_label.text = "Tile 1"
	p2_cell_label.text = "Tile 1"
	roll_result_label.text = "🎲 Ready!"
	roll_button.disabled = false
	_start_button_pulse()
