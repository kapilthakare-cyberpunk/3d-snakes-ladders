class_name CameraController
extends Camera3D

@export var overview_position := Vector3(0.5, 18.5, 16.5)
@export var overview_rotation := Vector3(-45.0, 0.0, 0.0)
@export var overview_fov: float = 54.0

@export var action_fov: float = 40.0
@export var follow_offset := Vector3(0.0, 5.0, 5.5)

var target_player: Player = null
var is_following: bool = false

func _ready() -> void:
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov
	
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		var gc = get_node("/root/GameController")
		gc.state_changed.connect(_on_state_changed)
		gc.player_turn_finished.connect(_on_turn_finished)
		gc.game_restarted.connect(_on_game_restarted)

func _on_state_changed(new_state: int) -> void:
	# GameState.MOVING = 2
	if new_state == 2:
		var gc = get_node_or_null("/root/GameController")
		if gc and gc.player_tokens.has(gc.active_player_id):
			target_player = gc.player_tokens[gc.active_player_id]
			is_following = true
	elif new_state == 0 or new_state == 4 or new_state == 5: # IDLE, TURN_END, GAME_OVER
		is_following = false
		target_player = null

func _on_turn_finished(player_id: int, final_cell: int) -> void:
	# Smoothly return to overview
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", overview_position, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees", overview_rotation, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "fov", overview_fov, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_game_restarted() -> void:
	is_following = false
	target_player = null
	position = overview_position
	rotation_degrees = overview_rotation
	fov = overview_fov

func _process(delta: float) -> void:
	if is_following and target_player and is_instance_valid(target_player):
		var target_cam_pos := target_player.global_position + follow_offset
		global_position = global_position.lerp(target_cam_pos, delta * 4.5)
		
		# Look at character's upper torso
		var look_target := target_player.global_position + Vector3(0.0, 0.6, 0.0)
		var current_transform := global_transform
		var desired_transform := current_transform.looking_at(look_target, Vector3.UP)
		global_transform = global_transform.interpolate_with(desired_transform, delta * 5.0)
		
		fov = lerpf(fov, action_fov, delta * 3.5)
