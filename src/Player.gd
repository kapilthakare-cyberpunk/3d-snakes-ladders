class_name Player
extends Node3D

const SnLScript = preload("res://singleton/SnLData.gd")

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false

signal move_finished(player_id: int, final_cell: int)
signal special_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)

var idle_tween: Tween
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	setup_player(player_id)
	_start_idle_bobbing()

func setup_player(p_id: int) -> void:
	player_id = p_id
	_build_superhero_miniature()

func _build_superhero_miniature() -> void:
	# Clear existing children of Visuals
	if not visuals:
		visuals = Node3D.new()
		visuals.name = "Visuals"
		add_child(visuals)
	
	for child in visuals.get_children():
		child.queue_free()
	
	if player_id == 1:
		_build_iron_man()
	elif player_id == 2:
		_build_spider_man()
	else:
		_build_wonder_woman()

func _build_iron_man() -> void:
	# Materials
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.78, 0.12, 0.15, 1.0) # Metallic Crimson
	mat_red.metallic = 0.8
	mat_red.roughness = 0.2
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.95, 0.78, 0.18, 1.0) # Metallic Gold
	mat_gold.metallic = 0.85
	mat_gold.roughness = 0.18
	
	var mat_arc := StandardMaterial3D.new()
	mat_arc.albedo_color = Color(0.2, 0.95, 1.0, 1.0) # Cyan Glowing Arc Reactor
	mat_arc.emission_enabled = true
	mat_arc.emission = Color(0.2, 0.95, 1.0, 1.0)
	mat_arc.emission_energy_multiplier = 2.0
	
	var mat_eyes := StandardMaterial3D.new()
	mat_eyes.albedo_color = Color(0.9, 0.98, 1.0, 1.0) # Glowing Eye Slits
	mat_eyes.emission_enabled = true
	mat_eyes.emission = Color(0.9, 0.98, 1.0, 1.0)
	mat_eyes.emission_energy_multiplier = 2.0
	
	# Base / Armored Boots
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = base_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	# Torso Armor
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.28
	body_mesh.bottom_radius = 0.22
	body_mesh.height = 0.38
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.32, 0)
	visuals.add_child(body_node)
	
	# Glowing Arc Reactor on Chest
	var arc_mesh := CylinderMesh.new()
	arc_mesh.top_radius = 0.08
	arc_mesh.bottom_radius = 0.08
	arc_mesh.height = 0.04
	var arc_node := MeshInstance3D.new()
	arc_node.mesh = arc_mesh
	arc_node.material_override = mat_arc
	arc_node.position = Vector3(0, 0.38, 0.26)
	arc_node.rotation_degrees = Vector3(90, 0, 0)
	visuals.add_child(arc_node)
	
	# Shoulder Pauldrons (Gold)
	var pauldron_mesh := SphereMesh.new()
	pauldron_mesh.radius = 0.1
	pauldron_mesh.height = 0.18
	for side in [-1.0, 1.0]:
		var p_node := MeshInstance3D.new()
		p_node.mesh = pauldron_mesh
		p_node.material_override = mat_gold
		p_node.position = Vector3(side * 0.3, 0.44, 0)
		visuals.add_child(p_node)
	
	# Helmet (Red Dome)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_red
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	# Faceplate (Gold)
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(0.24, 0.28, 0.1)
	var face_node := MeshInstance3D.new()
	face_node.mesh = face_mesh
	face_node.material_override = mat_gold
	face_node.position = Vector3(0, 0.64, 0.22)
	visuals.add_child(face_node)
	
	# Glowing Eye Slits
	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.07, 0.025, 0.02)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = mat_eyes
		eye.position = Vector3(side * 0.06, 0.67, 0.27)
		visuals.add_child(eye)

func _build_spider_man() -> void:
	# Materials
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.88, 0.15, 0.18, 1.0) # Comic Spider Red
	mat_red.roughness = 0.3
	
	var mat_blue := StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.12, 0.35, 0.88, 1.0) # Comic Spider Blue
	mat_blue.roughness = 0.3
	
	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.05, 0.05, 0.08, 1.0) # Black Webbing / Spider / Eye Rim
	mat_black.roughness = 0.2
	
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.98, 0.98, 1.0, 1.0) # White Mask Lenses
	mat_lens.roughness = 0.15
	
	# Base / Boots (Red)
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = base_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	# Lower Torso / Legs (Blue)
	var lower_mesh := CylinderMesh.new()
	lower_mesh.top_radius = 0.24
	lower_mesh.bottom_radius = 0.26
	lower_mesh.height = 0.18
	var lower_node := MeshInstance3D.new()
	lower_node.mesh = lower_mesh
	lower_node.material_override = mat_blue
	lower_node.position = Vector3(0, 0.21, 0)
	visuals.add_child(lower_node)
	
	# Upper Torso (Red)
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.28
	body_mesh.bottom_radius = 0.24
	body_mesh.height = 0.24
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.38, 0)
	visuals.add_child(body_node)
	
	# Black Spider Emblem on Chest
	var spider_mesh := SphereMesh.new()
	spider_mesh.radius = 0.06
	spider_mesh.height = 0.1
	var spider_node := MeshInstance3D.new()
	spider_node.mesh = spider_mesh
	spider_node.material_override = mat_black
	spider_node.position = Vector3(0, 0.38, 0.26)
	spider_node.scale = Vector3(1.2, 1.4, 0.3)
	visuals.add_child(spider_node)
	
	# Head / Mask (Red)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_red
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	# Iconic Spider-Man Triangular Mask Eyes (Black rim + White lens)
	var eye_outer_mesh := BoxMesh.new()
	eye_outer_mesh.size = Vector3(0.12, 0.16, 0.04)
	var eye_inner_mesh := BoxMesh.new()
	eye_inner_mesh.size = Vector3(0.09, 0.13, 0.05)
	
	for side in [-1.0, 1.0]:
		var outer := MeshInstance3D.new()
		outer.mesh = eye_outer_mesh
		outer.material_override = mat_black
		outer.position = Vector3(side * 0.11, 0.66, 0.24)
		outer.rotation_degrees = Vector3(0, 0, side * -18.0)
		visuals.add_child(outer)
		
		var inner := MeshInstance3D.new()
		inner.mesh = eye_inner_mesh
		inner.material_override = mat_lens
		inner.position = Vector3(side * 0.11, 0.66, 0.25)
		inner.rotation_degrees = Vector3(0, 0, side * -18.0)
		visuals.add_child(inner)

func _build_wonder_woman() -> void:
	# Materials
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.85, 0.12, 0.28, 1.0) # Amazonian Crimson Bodice
	mat_red.roughness = 0.25
	
	var mat_blue := StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.12, 0.28, 0.75, 1.0) # Royal Blue Skirt/Legs
	mat_blue.roughness = 0.3
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.98, 0.82, 0.18, 1.0) # Golden Tiara & Armor
	mat_gold.metallic = 0.85
	mat_gold.roughness = 0.2
	
	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.98, 0.84, 0.72, 1.0) # Peach Skin
	mat_skin.roughness = 0.4
	
	var mat_hair := StandardMaterial3D.new()
	mat_hair.albedo_color = Color(0.1, 0.1, 0.14, 1.0) # Dark Black Hair
	mat_hair.roughness = 0.3
	
	var mat_star := StandardMaterial3D.new()
	mat_star.albedo_color = Color(0.95, 0.15, 0.2, 1.0) # Red Star on Tiara
	mat_star.roughness = 0.2
	
	# Base / Boots (Red with gold trim)
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = base_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	# Skirt (Royal Blue)
	var skirt_mesh := CylinderMesh.new()
	skirt_mesh.top_radius = 0.26
	skirt_mesh.bottom_radius = 0.28
	skirt_mesh.height = 0.16
	var skirt_node := MeshInstance3D.new()
	skirt_node.mesh = skirt_mesh
	skirt_node.material_override = mat_blue
	skirt_node.position = Vector3(0, 0.2, 0)
	visuals.add_child(skirt_node)
	
	# Golden Belt
	var belt_mesh := CylinderMesh.new()
	belt_mesh.top_radius = 0.26
	belt_mesh.bottom_radius = 0.26
	belt_mesh.height = 0.05
	var belt_node := MeshInstance3D.new()
	belt_node.mesh = belt_mesh
	belt_node.material_override = mat_gold
	belt_node.position = Vector3(0, 0.28, 0)
	visuals.add_child(belt_node)
	
	# Red Bodice / Torso
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.27
	body_mesh.bottom_radius = 0.24
	body_mesh.height = 0.22
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.38, 0)
	visuals.add_child(body_node)
	
	# Golden Eagle 'W' Armor on Chest
	var eagle_mesh := BoxMesh.new()
	eagle_mesh.size = Vector3(0.26, 0.08, 0.05)
	var eagle_node := MeshInstance3D.new()
	eagle_node.mesh = eagle_mesh
	eagle_node.material_override = mat_gold
	eagle_node.position = Vector3(0, 0.44, 0.25)
	visuals.add_child(eagle_node)
	
	# Head (Skin tone)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_skin
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	# Dark Flowing Hair
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.27
	hair_mesh.height = 0.52
	var hair_node := MeshInstance3D.new()
	hair_node.mesh = hair_mesh
	hair_node.material_override = mat_hair
	hair_node.position = Vector3(0, 0.66, -0.06)
	visuals.add_child(hair_node)
	
	# Golden Amazonian Tiara across Forehead
	var tiara_mesh := BoxMesh.new()
	tiara_mesh.size = Vector3(0.3, 0.08, 0.12)
	var tiara_node := MeshInstance3D.new()
	tiara_node.mesh = tiara_mesh
	tiara_node.material_override = mat_gold
	tiara_node.position = Vector3(0, 0.72, 0.18)
	visuals.add_child(tiara_node)
	
	# Red Star in the Center of the Tiara
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	var star_node := MeshInstance3D.new()
	star_node.mesh = star_mesh
	star_node.material_override = mat_star
	star_node.position = Vector3(0, 0.74, 0.25)
	visuals.add_child(star_node)

func _start_idle_bobbing() -> void:
	if idle_tween:
		idle_tween.kill()
	idle_tween = create_tween().set_loops()
	
	idle_tween.tween_property($Visuals, "scale", Vector3(1.03, 0.97, 1.03), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property($Visuals, "position:y", 0.04, 1.2) \
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
		squash_tween.tween_property($Visuals, "scale", Vector3(0.82, 1.25, 0.82), hop_time * 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.22, 0.78, 1.22), hop_time * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.08) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		move_tween.tween_interval(hop_time + 0.04)
	
	var landing_cell: int = path[-1]
	
	# Special tile handling: Rainbow Ladder or Snake
	if SnLScript.connections.has(landing_cell):
		var destination_cell: int = SnLScript.connections[landing_cell]
		var is_ladder: bool = landing_cell < destination_cell
		
		move_tween.tween_callback(func():
			special_triggered.emit(player_id, is_ladder, landing_cell, destination_cell)
		)
		
		var dest_pos := board.get_cell_position(destination_cell)
		
		if is_ladder:
			# Ascending bouncy superhero fly with 360 spin
			move_tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 0.65) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			move_tween.parallel().tween_property($Visuals, "rotation_degrees:y", 360.0, 0.65) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			# Descending swooping snake slide
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
