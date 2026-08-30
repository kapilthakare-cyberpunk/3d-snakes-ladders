class_name Player
extends Node3D

const SnLScript = preload("res://singleton/SnLData.gd")

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false
var is_active_turn: bool = false

signal move_finished(player_id: int, final_cell: int)
signal special_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)

var token_material: StandardMaterial3D
var ear_material: StandardMaterial3D
var idle_tween: Tween

@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	setup_player(player_id)
	_start_idle_bobbing()

func setup_player(p_id: int) -> void:
	player_id = p_id
	token_material = StandardMaterial3D.new()
	token_material.roughness = 0.15
	token_material.metallic = 0.2
	
	ear_material = StandardMaterial3D.new()
	ear_material.roughness = 0.3
	
	if player_id == 1:
		# Teddy Red (Vibrant Candy Red + Soft Pink Ears)
		token_material.albedo_color = Color(1.0, 0.28, 0.36, 1.0)
		token_material.emission_enabled = true
		token_material.emission = Color(1.0, 0.28, 0.36, 1.0)
		token_material.emission_energy_multiplier = 0.2
		
		ear_material.albedo_color = Color(1.0, 0.72, 0.78, 1.0)
	else:
		# Bunny Blue (Vibrant Cyan Blue + Pastel Aqua Ears)
		token_material.albedo_color = Color(0.12, 0.68, 1.0, 1.0)
		token_material.emission_enabled = true
		token_material.emission = Color(0.12, 0.68, 1.0, 1.0)
		token_material.emission_energy_multiplier = 0.2
		
		ear_material.albedo_color = Color(0.72, 0.92, 1.0, 1.0)
	
	_apply_materials(self)

func _apply_materials(node: Node) -> void:
	if node is MeshInstance3D:
		if node.name.contains("Ear"):
			node.material_override = ear_material
		else:
			node.material_override = token_material
	for child in node.get_children():
		_apply_materials(child)

func _start_idle_bobbing() -> void:
	if idle_tween:
		idle_tween.kill()
	idle_tween = create_tween().set_loops()
	
	# Gentle breathing scale + slight vertical float
	idle_tween.tween_property($Visuals, "scale", Vector3(1.04, 0.96, 1.04), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property($Visuals, "position:y", 0.05, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	idle_tween.tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property($Visuals, "position:y", 0.0, 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func reset_to_start() -> void:
	current_cell = 1
	is_moving = false
	if visuals:
		visuals.scale = Vector3.ONE
		visuals.position = Vector3.ZERO
	_start_idle_bobbing()

func move_steps(steps: int) -> void:
	if is_moving or steps <= 0:
		return
	is_moving = true
	
	if idle_tween:
		idle_tween.kill()
	
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
	
	var move_tween := create_tween()
	move_tween.set_parallel(false)
	
	# Parabolic bouncy hop with squash-and-stretch
	for cell_idx in path:
		var target_pos := board.get_cell_position(cell_idx)
		
		# Step sequence
		var hop_time := 0.22
		var step_tween := create_tween()
		step_tween.set_parallel(true)
		
		# Horizontal move
		step_tween.tween_property(self, "global_position:x", target_pos.x, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		step_tween.tween_property(self, "global_position:z", target_pos.z, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Vertical hop (jump high, land down)
		var hop_y: float = target_pos.y + 0.65
		var v_hop := create_tween()
		v_hop.tween_property(self, "global_position:y", hop_y, hop_time * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		v_hop.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.55) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# Squash and Stretch during hop
		var squash_tween := create_tween()
		# Takeoff stretch
		squash_tween.tween_property($Visuals, "scale", Vector3(0.82, 1.25, 0.82), hop_time * 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Landing squash
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.22, 0.78, 1.22), hop_time * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Elastic return
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.08) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		move_tween.tween_interval(hop_time + 0.04)
	
	var landing_cell: int = path[-1]
	
	# Special tile handling: Rainbow Ladder or Cute Snake
	if SnLScript.connections.has(landing_cell):
		var destination_cell: int = SnLScript.connections[landing_cell]
		var is_ladder: bool = landing_cell < destination_cell
		
		move_tween.tween_callback(func():
			special_triggered.emit(player_id, is_ladder, landing_cell, destination_cell)
		)
		
		var dest_pos := board.get_cell_position(destination_cell)
		
		if is_ladder:
			# Ascending bouncy rainbow ladder glide with happy spinning
			move_tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 0.65) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			move_tween.parallel().tween_property($Visuals, "rotation_degrees:y", 360.0, 0.65) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			# Descending swooping snake slide with playful wobble
			move_tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 0.75) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		landing_cell = destination_cell
	
	move_tween.finished.connect(_on_move_completed.bind(landing_cell))

func _on_move_completed(final_cell: int) -> void:
	current_cell = final_cell
	is_moving = false
	if visuals:
		visuals.rotation_degrees = Vector3.ZERO
		visuals.scale = Vector3.ONE
	_start_idle_bobbing()
	move_finished.emit(player_id, final_cell)
