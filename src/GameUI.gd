class_name GameUI
extends CanvasLayer

@onready var turn_label: Label = $TopBar/MarginContainer/HBoxContainer/TurnContainer/Margin/TurnLabel
@onready var p1_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P1Card
@onready var p2_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P2Card
@onready var p3_card: PanelContainer = $TopBar/MarginContainer/HBoxContainer/P3Card

@onready var p1_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P1Card/Margin/HBox/P1CellLabel
@onready var p2_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P2Card/Margin/HBox/P2CellLabel
@onready var p3_cell_label: Label = $TopBar/MarginContainer/HBoxContainer/P3Card/Margin/HBox/P3CellLabel

@onready var roll_button: Button = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollButton
@onready var roll_result_badge: PanelContainer = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollResultBadge
@onready var roll_result_label: Label = $BottomPanel/MarginContainer/VBoxContainer/HBoxControls/RollResultBadge/RollResultLabel
@onready var log_banner: PanelContainer = $BottomPanel/MarginContainer/VBoxContainer/LogBanner
@onready var log_label: Label = $BottomPanel/MarginContainer/VBoxContainer/LogBanner/LogLabel
@onready var volume_button: Button = $TopBar/MarginContainer/HBoxContainer/VolumeButton

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
	if volume_button:
		volume_button.pressed.connect(_toggle_volume)

	# Initially disable rolling until players are configured
	roll_button.disabled = true

	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.turn_changed.connect(_on_turn_changed)
		gc.roll_started.connect(_on_roll_started)
		gc.dice_rolled.connect(_on_dice_rolled)
		gc.player_turn_finished.connect(_on_player_turn_finished)
		gc.special_tile_triggered.connect(_on_special_tile_triggered)
		gc.log_message.connect(_on_log_message)
		gc.game_won.connect(_on_game_won)
		gc.game_restarted.connect(_on_game_restarted)
		gc.players_configured.connect(_on_players_configured)

func _on_players_configured(count: int) -> void:
	# Show/hide player cards based on selected player count
	if p1_card: p1_card.visible = count >= 1
	if p2_card: p2_card.visible = count >= 2
	if p3_card: p3_card.visible = count >= 3

	roll_button.disabled = false
	_start_button_pulse()

func _start_button_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(roll_button, "scale", Vector2(1.05, 1.05), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(roll_button, "scale", Vector2(1.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_roll_button_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx(AudioManager.SFX.BUTTON_CLICK, 0.1)
	var click_pop := create_tween()
	click_pop.tween_property(roll_button, "scale", Vector2(0.92, 0.92), 0.06)
	click_pop.chain().tween_property(roll_button, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.request_roll()

func _on_play_again_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx(AudioManager.SFX.BUTTON_CLICK, 0.1)
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.restart_game()

func _toggle_volume() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.toggle_mute()
		volume_button.text = "🔊" if not am.is_muted else "🔇"

func _on_turn_changed(player_id: int, current_cell: int) -> void:
	roll_button.disabled = false
	_start_button_pulse()

	var cards := [p1_card, p2_card, p3_card]
	for i in range(cards.size()):
		var card = cards[i]
		if card and card.visible:
			var t := create_tween()
			if (i + 1) == player_id:
				t.tween_property(card, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK)
			else:
				t.tween_property(card, "scale", Vector2(0.95, 0.95), 0.25)

	match player_id:
		1:
			turn_label.text = "🔴 IRON MAN'S TURN!"
			turn_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
		2:
			turn_label.text = "🕷️ SPIDER-MAN'S TURN!"
			turn_label.modulate = Color(0.3, 0.7, 1.0, 1.0)
		3:
			turn_label.text = "⭐ WONDER WOMAN'S TURN!"
			turn_label.modulate = Color(1.0, 0.85, 0.3, 1.0)

func _on_roll_started(player_id: int) -> void:
	roll_button.disabled = true
	if pulse_tween:
		pulse_tween.kill()
	roll_button.scale = Vector2.ONE
	roll_result_label.text = "🎲 Rolling..."

func _on_dice_rolled(player_id: int, steps: int) -> void:
	roll_result_label.text = "🎲 ROLLED %d! ⭐" % steps
	var badge_pop := create_tween()
	badge_pop.tween_property(roll_result_badge, "scale", Vector2(1.25, 1.25), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_pop.chain().tween_property(roll_result_badge, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_player_turn_finished(player_id: int, final_cell: int) -> void:
	match player_id:
		1:
			if p1_cell_label: p1_cell_label.text = "Tile %d" % final_cell
		2:
			if p2_cell_label: p2_cell_label.text = "Tile %d" % final_cell
		3:
			if p3_cell_label: p3_cell_label.text = "Tile %d" % final_cell

func _on_special_tile_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int) -> void:
	var hero_name := "Iron Man"
	if player_id == 2: hero_name = "Spider-Man"
	elif player_id == 3: hero_name = "Wonder Woman"

	if is_ladder:
		_show_popup_banner("🌈 POWER UP! %s FLEW UP A LADDER TO %d! 🚀" % [hero_name, to_cell], Color(0.3, 0.95, 0.55, 1.0))
	else:
		_show_popup_banner("🐍 WHOOPSIE! %s SLID DOWN A SNAKE TO %d! 🎈" % [hero_name, to_cell], Color(1.0, 0.45, 0.55, 1.0))

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

	var hero_name: String = str(game_stats.get("winner_name", "Superhero"))
	victory_title.text = "🏆 %s WINS THE GAME! 🌟" % hero_name

	match winner_id:
		1: victory_title.modulate = Color(1.0, 0.35, 0.35, 1.0)
		2: victory_title.modulate = Color(0.3, 0.7, 1.0, 1.0)
		3: victory_title.modulate = Color(1.0, 0.85, 0.3, 1.0)

	var turns: int = game_stats.get("total_turns", 0)
	var p_stats: Dictionary = game_stats.get("player_stats", {})
	var ladders: int = p_stats.get("ladders", 0)
	var snakes: int = p_stats.get("snakes", 0)
	var rolls: int = p_stats.get("rolls", 0)

	victory_stats.text = "🎉 Superhero Championship! 🎉\n\n⭐ Total Turns: %d\n🎲 Dice Rolls: %d\n🌈 Rainbow Ladders: %d\n🐍 Snake Traps: %d" % [turns, rolls, ladders, snakes]

	if confetti_particles:
		confetti_particles.emitting = true

	var modal_box = $VictoryModal/CenterContainer/PanelContainer
	modal_box.scale = Vector2(0.5, 0.5)
	var win_pop := create_tween()
	win_pop.tween_property(modal_box, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_game_restarted() -> void:
	victory_modal.visible = false
	if confetti_particles:
		confetti_particles.emitting = false
	if p1_cell_label: p1_cell_label.text = "Tile 1"
	if p2_cell_label: p2_cell_label.text = "Tile 1"
	if p3_cell_label: p3_cell_label.text = "Tile 1"
	roll_result_label.text = "🎲 Ready!"
	roll_button.disabled = false
	_start_button_pulse()
