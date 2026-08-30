class_name Player
extends Node3D

const SnLScript = preload("res://singleton/SnLData.gd")

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false

signal move_finished(player_id: int, final_cell: int)
signal special_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)

var token_material: StandardMaterial3D
var base_mesh_node: MeshInstance3D

func _ready() -> void:
	setup_player(player_id)

func setup_player(p_id: int) -> void:
	player_id = p_id
	token_material = StandardMaterial3D.new()
	token_material.roughness = 0.2
	token_material.metallic = 0.6
	
	if player_id == 1:
		token_material.albedo_color = Color(0.92, 0.22, 0.28, 1.0) # Ruby Red
		token_material.emission_enabled = true
		token_material.emission = Color(0.92, 0.22, 0.28, 1.0)
		token_material.emission_energy_multiplier = 0.25
	else:
		token_material.albedo_color = Color(0.08, 0.68, 0.92, 1.0) # Cyan Azure
		token_material.emission_enabled = true
		token_material.emission = Color(0.08, 0.68, 0.92, 1.0)
		token_material.emission_energy_multiplier = 0.25
	
	_apply_material_to_children(self)

func _apply_material_to_children(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = token_material
	for child in node.get_children():
		_apply_material_to_children(child)

func reset_to_start() -> void:
	current_cell = 1
	is_moving = false

func move_steps(steps: int) -> void:
	if is_moving or steps <= 0:
		return
	is_moving = true
	
	var raw_target := current_cell + steps
	var path: Array[int] = []
	if raw_target <= 100:
		for i in range(current_cell + 1, raw_target + 1):
			path.append(i)
	else:
		# Overshoot bounce-back from cell 100
		for i in range(current_cell + 1, 101):
			path.append(i)
		var bounced := 100 - (raw_target - 100)
		bounced = maxi(bounced, 1)
		for i in range(99, bounced - 1, -1):
			path.append(i)
	
	var board = get_tree().root.find_child("Board", true, false) as Board
	if not board:
		is_moving = false
		return
	
	var tween := self.create_tween()
	tween.set_parallel(false)
	
	# Parabolic hopping step-by-step
	for cell_idx in path:
		var target_pos := board.get_cell_position(cell_idx)
		var step_tween := self.create_tween()
		step_tween.set_parallel(true)
		
		# Horizontal move
		step_tween.tween_property(self, "global_position:x", target_pos.x, 0.16) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		step_tween.tween_property(self, "global_position:z", target_pos.z, 0.16) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Vertical hop arc (jump up and land down)
		var hop_y: float = target_pos.y + 0.45
		step_tween.tween_property(self, "global_position:y", hop_y, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		step_tween.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		tween.tween_interval(0.16)
	
	var landing_cell: int = path[-1]
	
	# Check if landing cell triggers snake or ladder
	if SnLScript.connections.has(landing_cell):
		var destination_cell: int = SnLScript.connections[landing_cell]
		var is_ladder: bool = landing_cell < destination_cell
		
		# Trigger event callback before animation
		tween.tween_callback(func():
			special_triggered.emit(player_id, is_ladder, landing_cell, destination_cell)
		)
		
		var dest_pos := board.get_cell_position(destination_cell)
		
		if is_ladder:
			# Ascending smooth ladder glide with scale excitement
			tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 0.5) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			# Descending swooping snake slide
			tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 0.6) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		landing_cell = destination_cell
	
	tween.finished.connect(_on_move_completed.bind(landing_cell))

func _on_move_completed(final_cell: int) -> void:
	current_cell = final_cell
	is_moving = false
	move_finished.emit(player_id, final_cell)
