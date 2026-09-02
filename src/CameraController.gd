class_name CameraController
extends Camera3D

@export var overview_position := Vector3(0.5, 18.5, 16.5)
@export var overview_rotation := Vector3(-45.0, 0.0, 0.0)
@export var overview_fov: float = 54.0

@export var action_fov: float = 38.0
@export var follow_offset := Vector3(0.0, 4.5, 5.2)

@export var dice_fov: float = 42.0
@export var dice_offset := Vector3(1.8, 4.0, 3.5)

@export var shake_intensity: float = 0.35
@export var shake_decay: float = 5.0
@export var slow_mo_scale: float = 0.45

var target_player: Player = null
var dice_node: Node3D = null
var is_following: bool = false
var is_watching_dice: bool = false
var reset_tween: Tween

var shake_amount: float = 0.0
var shake_tween: Tween
var original_position: Vector3
var is_victory_orbiting: bool = false
var victory_orbit_elapsed: float = 0.0

func _ready() -> void:
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov
	original_position = position
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var gc = get_node_or_null("/root/GameController")
	if gc:
		gc.state_changed.connect(_on_state_changed)
		gc.player_turn_finished.connect(_on_turn_finished)
		gc.game_restarted.connect(_on_game_restarted)
		gc.special_tile_triggered.connect(_on_special_tile_triggered)
		gc.game_won.connect(_on_game_won)

	dice_node = get_tree().root.find_child("Dice3D", true, false)
	if dice_node and dice_node.has_signal("roll_animation_done"):
		dice_node.roll_animation_done.connect(_on_dice_roll_done)

func _process(delta: float) -> void:
	if shake_amount > 0.001:
		var shake_vec := Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		position += shake_vec
		shake_amount = move_toward(shake_amount, 0.0, shake_decay * delta)

	if is_victory_orbiting and target_player and is_instance_valid(target_player):
		victory_orbit_elapsed += delta
		var center: Vector3 = target_player.global_position + Vector3(0, 3.5, 0)
		var radius: float = 6.5
		var orbit_duration: float = 8.0
		var angle := victory_orbit_elapsed / orbit_duration * TAU
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		global_position = center + Vector3(x, 3.0 + sin(victory_orbit_elapsed * 1.5) * 0.6, z)
		look_at(center, Vector3.UP)
		fov = 38.0 + sin(victory_orbit_elapsed * 0.8) * 6.0
		return

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
		global_transform = global_transform.interpolate_with(desired, delta * 5.0)
		fov = move_toward(fov, action_fov, delta * 4.0)

func _on_state_changed(new_state: int) -> void:
	if reset_tween:
		reset_tween.kill()

	if new_state == GameState.ROLLING:
		_focus_on_dice()
	elif new_state == GameState.IDLE or new_state == GameState.GAME_OVER:
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

	reset_tween.finished.connect(func():
		if dice_node and is_watching_dice:
			look_at(dice_look, Vector3.UP)
	)

func _on_dice_roll_done(_value: int) -> void:
	is_watching_dice = false
	_zoom_into_active_player()

func _zoom_into_active_player() -> void:
	var gc = get_node_or_null("/root/GameController")
	if not gc or not gc.player_tokens.has(gc.active_player_id):
		return
	target_player = gc.player_tokens[gc.active_player_id]
	if not target_player:
		return

	is_following = true
	var p := target_player.global_position
	var close_pos := p + Vector3(0.0, 2.8, 3.2)
	if reset_tween:
		reset_tween.kill()
	reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(self, "global_position", close_pos, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reset_tween.tween_property(self, "fov", 32.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	reset_tween.finished.connect(func():
		look_at(p + Vector3(0, 0.5, 0), Vector3.UP)
	)

func _on_turn_finished(player_id: int, final_cell: int) -> void:
	if final_cell == 100:
		_trigger_slow_motion()
	get_tree().create_timer(0.65).timeout.connect(func():
		is_following = false
		is_watching_dice = false
		target_player = null
		_reset_camera_to_overview()
	)

func _trigger_slow_motion() -> void:
	Engine.time_scale = slow_mo_scale
	var tween := create_tween()
	tween.tween_property(self, "fov", 28.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_restore_time_scale", 1.0, 0.0)
	tween.chain().tween_property(self, "fov", overview_fov, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

var _restore_time_scale: float = 1.0:
	set(v):
		Engine.time_scale = v

func _reset_camera_to_overview() -> void:
	is_victory_orbiting = false
	victory_orbit_elapsed = 0.0
	if reset_tween:
		reset_tween.kill()
	reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(self, "position", overview_position, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reset_tween.tween_property(self, "rotation_degrees", overview_rotation, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reset_tween.tween_property(self, "fov", overview_fov, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_game_restarted() -> void:
	if reset_tween:
		reset_tween.kill()
	is_following = false
	is_watching_dice = false
	is_victory_orbiting = false
	victory_orbit_elapsed = 0.0
	target_player = null
	shake_amount = 0.0
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov
	Engine.time_scale = 1.0

func trigger_shake(intensity: float = 1.0, duration: float = 0.4) -> void:
	shake_amount = shake_intensity * intensity
	if shake_tween:
		shake_tween.kill()
	shake_tween = create_tween()
	shake_tween.tween_property(self, "_shake_temp", 0.0, duration)
	await shake_tween.finished
	shake_amount = 0.0

var _shake_temp: float = 0.0

func _on_special_tile_triggered(p_id: int, is_ladder: bool, from_cell: int, to_cell: int) -> void:
	if is_ladder:
		trigger_shake(0.6, 0.25)
	else:
		trigger_shake(1.2, 0.5)

func _on_game_won(winner_id: int, game_stats: Dictionary) -> void:
	is_following = false
	is_watching_dice = false
	target_player = null
	var gc = get_node_or_null("/root/GameController")
	if gc and gc.player_tokens.has(winner_id):
		target_player = gc.player_tokens[winner_id]
	_start_victory_orbit()

func _start_victory_orbit() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	is_victory_orbiting = true
	victory_orbit_elapsed = 0.0
	is_following = false
	is_watching_dice = false
	if reset_tween:
		reset_tween.kill()
	get_tree().create_timer(10.0).timeout.connect(func():
		is_victory_orbiting = false
		_reset_camera_to_overview()
	)
