class_name PlayerSelect
extends CanvasLayer

signal players_selected(count: int)

@onready var modal: Control = $Modal
@onready var btn1: Button = $Modal/CenterContainer/PanelContainer/MarginContainer/VBox/Btn1
@onready var btn2: Button = $Modal/CenterContainer/PanelContainer/MarginContainer/VBox/Btn2
@onready var btn3: Button = $Modal/CenterContainer/PanelContainer/MarginContainer/VBox/Btn3

func _ready() -> void:
	modal.visible = true
	btn1.pressed.connect(func(): _select(1))
	btn2.pressed.connect(func(): _select(2))
	btn3.pressed.connect(func(): _select(3))

	# Animated entrance
	var panel = $Modal/CenterContainer/PanelContainer
	panel.scale = Vector2(0.4, 0.4)
	panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.35)

func _select(count: int) -> void:
	# Button click pop
	var clicked: Button = btn1
	if count == 2: clicked = btn2
	elif count == 3: clicked = btn3
	var pop := create_tween()
	pop.tween_property(clicked, "scale", Vector2(0.9, 0.9), 0.06)
	pop.chain().tween_property(clicked, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Exit animation
	var panel = $Modal/CenterContainer/PanelContainer
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(0.5, 0.5), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "modulate:a", 0.0, 0.25)
	tw.finished.connect(func():
		modal.visible = false
		players_selected.emit(count)
	)
