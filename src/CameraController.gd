class_name CameraController
extends Camera3D

@export var overview_position := Vector3(0.5, 18.5, 16.5)
@export var overview_rotation := Vector3(-45.0, 0.0, 0.0)
@export var overview_fov: float = 54.0

@export var action_fov: float = 38.0
@export var follow_offset := Vector3(0.0, 4.5, 5.2)

# Dice camera settings
@export var dice_fov: float = 42.0
@export var dice_offset := Vector3(1.8, 4.0, 3.5)

var target_player: Player = null
var dice_node: Node3D = null
var is_following: bool = false
var is_watching_dice: bool = false
var reset_tween: Tween

func _ready() -> void:
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov

	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.state_changed.connect(_on_state_changed)
		gc.player_turn_finished.connect(_on_turn_finished)
		gc.game_restarted.connect(_on_game_restarted)

	# Find the dice node for camera focus
	dice_node = get_tree().root.find_child("Dice3D", true, false)
	if dice_node and dice_node.has_signal("roll_animation_done"):
		dice_node.roll_animation_done.connect(_on_dice_roll_done)

func _on_state_changed(new_state: int) -> void:
	if reset_tween:
		reset_tween.kill()

	# GameState.ROLLING = 1
	if new_state == 1:
		_focus_on_dice()
	# GameState.MOVING = 2 handled by _on_dice_roll_done
	elif new_state == 0 or new_state == 5: # IDLE or GAME_OVER
		if not is_following and not is_watching_dice:
			target_player = null

func _focus_on_dice() -> void:
	if not dice_node:
		return
	is_watching_dice = true
	is_following = false
	target_player = null

	var dice_cam_pos := dice_node.global_position + dice_offset
	var dice_look := dice_node.global_position + Vector3(0, 0.8, 0)

	if reset_tween:
		reset_tween.kill()
	reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(self, "global_position", dice_cam_pos, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reset_tween.tween_property(self, "fov", dice_fov, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Look-at via rotation tween
	reset_tween.finished.connect(func():
		if dice_node and is_watching_dice:
			look_at(dice_look, Vector3.UP)
	)

func _on_dice_roll_done(_value: int) -> void:
	# Dice settled → transition to following the active player
	is_watching_dice = false

	var gc = get_node_or_null("/root/GameController")
	if gc and gc.player_tokens.has(gc.active_player_id):
		target_player = gc.player_tokens[gc.active_player_id]
		is_following = true

func _on_turn_finished(player_id: int, final_cell: int) -> void:
	# Dramatic pause on destination tile before gliding back to overview
	get_tree().create_timer(0.65).timeout.connect(func():
		is_following = false
		is_watching_dice = false
		target_player = null

		if reset_tween:
			reset_tween.kill()
		reset_tween = create_tween().set_parallel(true)
		reset_tween.tween_property(self, "position", overview_position, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		reset_tween.tween_property(self, "rotation_degrees", overview_rotation, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		reset_tween.tween_property(self, "fov", overview_fov, 1.1) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)

func _on_game_restarted() -> void:
	if reset_tween:
		reset_tween.kill()
	is_following = false
	is_watching_dice = false
	target_player = null
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov

func _process(delta: float) -> void:
	if is_watching_dice and dice_node and is_instance_valid(dice_node):
		var dice_cam_pos := dice_node.global_position + dice_offset
		global_position = global_position.lerp(dice_cam_pos, delta * 6.0)
		var look_target := dice_node.global_position + Vector3(0, 0.8, 0)
		var desired := global_transform.looking_at(look_target, Vector3.UP)
		global_transform = global_transform.interpolate_with(desired, delta * 6.0)

	elif is_following and target_player and is_instance_valid(target_player):
		var target_cam_pos := target_player.global_position + follow_offset
		global_position = global_position.lerp(target_cam_pos, delta * 5.0)

		var look_target := target_player.global_position + Vector3(0.0, 0.6, 0.0)
		var desired := global_transform.looking_at(look_target, Vector3.UP)
		global_transform = global_transform.interpolate_with(desired, delta * 5.5)

		fov = lerpf(fov, action_fov, delta * 4.0)
