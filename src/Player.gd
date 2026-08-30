class_name Player
extends Node3D

const SnLScript = preload("res://singleton/SnLData.gd")

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false

signal move_finished(player_id: int, final_cell: int)
signal special_triggered(player_id: int, is_ladder: bool, from_cell: int, to_cell: int)

var idle_tween: Tween
var power_particles: CPUParticles3D
var power_light: OmniLight3D
@onready var visuals: Node3D = $Visuals

func _ready() -> void:
	setup_player(player_id)
	_start_idle_bobbing()

func setup_player(p_id: int) -> void:
	player_id = p_id
	_build_superhero_miniature()
	_setup_power_effects()

func _setup_power_effects() -> void:
	if power_particles:
		power_particles.queue_free()
	if power_light:
		power_light.queue_free()
	
	power_particles = CPUParticles3D.new()
	power_particles.emitting = false
	power_particles.amount = 36
	power_particles.lifetime = 0.8
	power_particles.speed_scale = 1.2
	power_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	power_particles.emission_sphere_radius = 0.3
	power_particles.gravity = Vector3(0, -2.5, 0)
	power_particles.scale_amount_min = 0.1
	power_particles.scale_amount_max = 0.22
	
	var part_mat := StandardMaterial3D.new()
	part_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	part_mat.vertex_color_use_as_albedo = true
	
	var part_mesh := SphereMesh.new()
	part_mesh.radius = 0.09
	part_mesh.height = 0.18
	part_mesh.material = part_mat
	power_particles.mesh = part_mesh
	
	power_light = OmniLight3D.new()
	power_light.light_energy = 0.0
	power_light.omni_range = 4.0
	
	match player_id:
		1:
			# Iron Man: Jet Repulsor Flames (Cyan / Orange)
			power_particles.color = Color(0.2, 0.95, 1.0, 0.95)
			power_particles.direction = Vector3(0, -1, -0.6)
			power_particles.spread = 25.0
			power_particles.initial_velocity_min = 2.5
			power_particles.initial_velocity_max = 4.5
			power_light.light_color = Color(0.25, 0.95, 1.0, 1.0)
		2:
			# Spider-Man: Web Trails (Crisp White / Silver)
			power_particles.color = Color(0.98, 0.98, 1.0, 0.92)
			power_particles.direction = Vector3(0, 0.6, -1)
			power_particles.spread = 50.0
			power_particles.initial_velocity_min = 1.5
			power_particles.initial_velocity_max = 3.0
			power_light.light_color = Color(0.9, 0.95, 1.0, 1.0)
		3:
			# Wonder Woman: Golden Lasso Aura (Radiant Gold)
			power_particles.color = Color(1.0, 0.88, 0.25, 0.95)
			power_particles.direction = Vector3(0, 1, 0)
			power_particles.spread = 180.0
			power_particles.initial_velocity_min = 1.8
			power_particles.initial_velocity_max = 3.5
			power_light.light_color = Color(1.0, 0.88, 0.25, 1.0)
	
	add_child(power_particles)
	add_child(power_light)

func _build_superhero_miniature() -> void:
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
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.82, 0.1, 0.14, 1.0)
	mat_red.metallic = 0.85
	mat_red.roughness = 0.18
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.98, 0.8, 0.15, 1.0)
	mat_gold.metallic = 0.9
	mat_gold.roughness = 0.15
	
	var mat_arc := StandardMaterial3D.new()
	mat_arc.albedo_color = Color(0.25, 0.95, 1.0, 1.0)
	mat_arc.emission_enabled = true
	mat_arc.emission = Color(0.25, 0.95, 1.0, 1.0)
	mat_arc.emission_energy_multiplier = 2.5
	
	var boot_mesh := CylinderMesh.new()
	boot_mesh.top_radius = 0.32
	boot_mesh.bottom_radius = 0.36
	boot_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = boot_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.28
	body_mesh.bottom_radius = 0.22
	body_mesh.height = 0.38
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.32, 0)
	visuals.add_child(body_node)
	
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
	
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.07
	arm_mesh.bottom_radius = 0.07
	arm_mesh.height = 0.28
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = mat_red
		arm.position = Vector3(side * 0.34, 0.32, 0.04)
		arm.rotation_degrees = Vector3(15, 0, side * -12)
		visuals.add_child(arm)
		
		var palm := MeshInstance3D.new()
		palm.mesh = arc_mesh
		palm.material_override = mat_arc
		palm.position = Vector3(side * 0.34, 0.17, 0.08)
		palm.scale = Vector3(0.5, 0.5, 0.5)
		visuals.add_child(palm)
	
	var pauldron_mesh := SphereMesh.new()
	pauldron_mesh.radius = 0.11
	pauldron_mesh.height = 0.18
	for side in [-1.0, 1.0]:
		var p_node := MeshInstance3D.new()
		p_node.mesh = pauldron_mesh
		p_node.material_override = mat_gold
		p_node.position = Vector3(side * 0.3, 0.44, 0)
		visuals.add_child(p_node)
	
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_red
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(0.24, 0.28, 0.1)
	var face_node := MeshInstance3D.new()
	face_node.mesh = face_mesh
	face_node.material_override = mat_gold
	face_node.position = Vector3(0, 0.64, 0.22)
	visuals.add_child(face_node)
	
	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.07, 0.025, 0.02)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = mat_arc
		eye.position = Vector3(side * 0.06, 0.67, 0.27)
		visuals.add_child(eye)

func _build_spider_man() -> void:
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.9, 0.12, 0.15, 1.0)
	mat_red.roughness = 0.25
	
	var mat_blue := StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.1, 0.32, 0.9, 1.0)
	mat_blue.roughness = 0.25
	
	var mat_black := StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.04, 0.04, 0.06, 1.0)
	mat_black.roughness = 0.15
	
	var mat_lens := StandardMaterial3D.new()
	mat_lens.albedo_color = Color(0.98, 0.98, 1.0, 1.0)
	mat_lens.roughness = 0.1
	
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = base_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	var lower_mesh := CylinderMesh.new()
	lower_mesh.top_radius = 0.24
	lower_mesh.bottom_radius = 0.26
	lower_mesh.height = 0.18
	var lower_node := MeshInstance3D.new()
	lower_node.mesh = lower_mesh
	lower_node.material_override = mat_blue
	lower_node.position = Vector3(0, 0.21, 0)
	visuals.add_child(lower_node)
	
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.28
	body_mesh.bottom_radius = 0.24
	body_mesh.height = 0.24
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.38, 0)
	visuals.add_child(body_node)
	
	var spider_mesh := SphereMesh.new()
	spider_mesh.radius = 0.06
	spider_mesh.height = 0.1
	var spider_node := MeshInstance3D.new()
	spider_node.mesh = spider_mesh
	spider_node.material_override = mat_black
	spider_node.position = Vector3(0, 0.38, 0.26)
	spider_node.scale = Vector3(1.2, 1.4, 0.3)
	visuals.add_child(spider_node)
	
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.065
	arm_mesh.bottom_radius = 0.065
	arm_mesh.height = 0.28
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = mat_red
		arm.position = Vector3(side * 0.32, 0.32, 0.04)
		arm.rotation_degrees = Vector3(20, 0, side * -18)
		visuals.add_child(arm)
		
		var shooter := MeshInstance3D.new()
		shooter.mesh = BoxMesh.new()
		(shooter.mesh as BoxMesh).size = Vector3(0.04, 0.04, 0.04)
		shooter.material_override = mat_black
		shooter.position = Vector3(side * 0.32, 0.17, 0.08)
		visuals.add_child(shooter)
	
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_red
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	var eye_outer := BoxMesh.new()
	eye_outer.size = Vector3(0.12, 0.16, 0.04)
	var eye_inner := BoxMesh.new()
	eye_inner.size = Vector3(0.09, 0.13, 0.05)
	for side in [-1.0, 1.0]:
		var outer := MeshInstance3D.new()
		outer.mesh = eye_outer
		outer.material_override = mat_black
		outer.position = Vector3(side * 0.11, 0.66, 0.24)
		outer.rotation_degrees = Vector3(0, 0, side * -18.0)
		visuals.add_child(outer)
		
		var inner := MeshInstance3D.new()
		inner.mesh = eye_inner
		inner.material_override = mat_lens
		inner.position = Vector3(side * 0.11, 0.66, 0.25)
		inner.rotation_degrees = Vector3(0, 0, side * -18.0)
		visuals.add_child(inner)

func _build_wonder_woman() -> void:
	var mat_red := StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.88, 0.1, 0.28, 1.0)
	mat_red.roughness = 0.25
	
	var mat_blue := StandardMaterial3D.new()
	mat_blue.albedo_color = Color(0.1, 0.26, 0.8, 1.0)
	mat_blue.roughness = 0.25
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.98, 0.82, 0.15, 1.0)
	mat_gold.metallic = 0.9
	mat_gold.roughness = 0.15
	
	var mat_silver := StandardMaterial3D.new()
	mat_silver.albedo_color = Color(0.92, 0.94, 0.98, 1.0)
	mat_silver.metallic = 0.95
	mat_silver.roughness = 0.1
	
	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.98, 0.84, 0.72, 1.0)
	mat_skin.roughness = 0.4
	
	var mat_hair := StandardMaterial3D.new()
	mat_hair.albedo_color = Color(0.08, 0.08, 0.12, 1.0)
	mat_hair.roughness = 0.3
	
	var mat_star := StandardMaterial3D.new()
	mat_star.albedo_color = Color(0.95, 0.12, 0.2, 1.0)
	
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.32
	base_mesh.bottom_radius = 0.38
	base_mesh.height = 0.12
	var base_node := MeshInstance3D.new()
	base_node.mesh = base_mesh
	base_node.material_override = mat_red
	base_node.position = Vector3(0, 0.06, 0)
	visuals.add_child(base_node)
	
	var skirt_mesh := CylinderMesh.new()
	skirt_mesh.top_radius = 0.26
	skirt_mesh.bottom_radius = 0.28
	skirt_mesh.height = 0.16
	var skirt_node := MeshInstance3D.new()
	skirt_node.mesh = skirt_mesh
	skirt_node.material_override = mat_blue
	skirt_node.position = Vector3(0, 0.2, 0)
	visuals.add_child(skirt_node)
	
	var belt_mesh := CylinderMesh.new()
	belt_mesh.top_radius = 0.26
	belt_mesh.bottom_radius = 0.26
	belt_mesh.height = 0.05
	var belt_node := MeshInstance3D.new()
	belt_node.mesh = belt_mesh
	belt_node.material_override = mat_gold
	belt_node.position = Vector3(0, 0.28, 0)
	visuals.add_child(belt_node)
	
	var lasso_mesh := TorusMesh.new()
	lasso_mesh.inner_radius = 0.06
	lasso_mesh.outer_radius = 0.1
	var lasso_node := MeshInstance3D.new()
	lasso_node.mesh = lasso_mesh
	lasso_node.material_override = mat_gold
	lasso_node.position = Vector3(0.24, 0.26, 0.05)
	lasso_node.rotation_degrees = Vector3(90, 0, 0)
	visuals.add_child(lasso_node)
	
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.27
	body_mesh.bottom_radius = 0.24
	body_mesh.height = 0.22
	var body_node := MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = mat_red
	body_node.position = Vector3(0, 0.38, 0)
	visuals.add_child(body_node)
	
	var eagle_mesh := BoxMesh.new()
	eagle_mesh.size = Vector3(0.26, 0.08, 0.05)
	var eagle_node := MeshInstance3D.new()
	eagle_node.mesh = eagle_mesh
	eagle_node.material_override = mat_gold
	eagle_node.position = Vector3(0, 0.44, 0.25)
	visuals.add_child(eagle_node)
	
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.06
	arm_mesh.bottom_radius = 0.06
	arm_mesh.height = 0.26
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = mat_skin
		arm.position = Vector3(side * 0.32, 0.34, 0.02)
		arm.rotation_degrees = Vector3(15, 0, side * -15)
		visuals.add_child(arm)
		
		var bracelet := MeshInstance3D.new()
		bracelet.mesh = CylinderMesh.new()
		(bracelet.mesh as CylinderMesh).top_radius = 0.075
		(bracelet.mesh as CylinderMesh).bottom_radius = 0.075
		(bracelet.mesh as CylinderMesh).height = 0.09
		bracelet.material_override = mat_silver
		bracelet.position = Vector3(side * 0.32, 0.22, 0.04)
		visuals.add_child(bracelet)
	
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = mat_skin
	head_node.position = Vector3(0, 0.65, 0)
	visuals.add_child(head_node)
	
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.27
	hair_mesh.height = 0.52
	var hair_node := MeshInstance3D.new()
	hair_node.mesh = hair_mesh
	hair_node.material_override = mat_hair
	hair_node.position = Vector3(0, 0.66, -0.06)
	visuals.add_child(hair_node)
	
	var tiara_mesh := BoxMesh.new()
	tiara_mesh.size = Vector3(0.3, 0.08, 0.12)
	var tiara_node := MeshInstance3D.new()
	tiara_node.mesh = tiara_mesh
	tiara_node.material_override = mat_gold
	tiara_node.position = Vector3(0, 0.72, 0.18)
	visuals.add_child(tiara_node)
	
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
		visuals.rotation_degrees = Vector3.ZERO
	if power_particles:
		power_particles.emitting = false
	if power_light:
		power_light.light_energy = 0.0
	_start_idle_bobbing()

func move_steps(steps: int) -> void:
	if is_moving or steps <= 0:
		return
	is_moving = true
	
	if idle_tween:
		idle_tween.kill()
	
	# Activate superpower VFX
	if power_particles:
		power_particles.emitting = true
	if power_light:
		var light_tween := create_tween()
		light_tween.tween_property(power_light, "light_energy", 2.2, 0.3)
	
	var raw_target := current_cell + steps
	var path: Array[int] = []
	if raw_target <= 100:
		for i in range(current_cell + 1, raw_target + 1):
			path.append(i)
	else:
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
	
	# Slow, graceful, cinematic travel time per tile (0.58s)
	var hop_time := 0.58
	
	for cell_idx in path:
		var target_pos := board.get_cell_position(cell_idx)
		var step_tween := create_tween()
		step_tween.set_parallel(true)
		
		# Smooth horizontal glide
		step_tween.tween_property(self, "global_position:x", target_pos.x, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		step_tween.tween_property(self, "global_position:z", target_pos.z, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Distinct superpower movements in slow motion
		match player_id:
			1:
				# Iron Man: Sustained Repulsor Supersonic Jet Flight
				var hop_y: float = target_pos.y + 1.1
				var v_hop := create_tween()
				v_hop.tween_property(self, "global_position:y", hop_y, hop_time * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				v_hop.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				
				# Aerodynamic banking forward pitch
				var flight_pitch := create_tween()
				flight_pitch.tween_property($Visuals, "rotation_degrees:x", -38.0, hop_time * 0.35).set_trans(Tween.TRANS_QUAD)
				flight_pitch.chain().tween_property($Visuals, "rotation_degrees:x", 0.0, hop_time * 0.65).set_trans(Tween.TRANS_BACK)
			2:
				# Spider-Man: High Web-Swing Arc with Acrobatic Flip
				var hop_y: float = target_pos.y + 1.45
				var v_hop := create_tween()
				v_hop.tween_property(self, "global_position:y", hop_y, hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				v_hop.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				
				# Full acrobatic 360 flip
				var flip := create_tween()
				flip.tween_property($Visuals, "rotation_degrees:x", 360.0, hop_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			3:
				# Wonder Woman: Divine Amazonian Leap & Spinning Lasso Aura
				var hop_y: float = target_pos.y + 1.25
				var v_hop := create_tween()
				v_hop.tween_property(self, "global_position:y", hop_y, hop_time * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				v_hop.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				
				# Graceful 360 pirouette spin
				var spin := create_tween()
				spin.tween_property($Visuals, "rotation_degrees:y", 360.0, hop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		# Gentle landing squash and spring
		var squash_tween := create_tween()
		squash_tween.tween_property($Visuals, "scale", Vector3(0.88, 1.18, 0.88), hop_time * 0.4).set_trans(Tween.TRANS_QUAD)
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.15, 0.85, 1.15), hop_time * 0.45).set_trans(Tween.TRANS_QUAD)
		squash_tween.chain().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_ELASTIC)
		
		move_tween.tween_interval(hop_time + 0.06)
	
	var landing_cell: int = path[-1]
	
	if SnLScript.connections.has(landing_cell):
		var destination_cell: int = SnLScript.connections[landing_cell]
		var is_ladder: bool = landing_cell < destination_cell
		
		move_tween.tween_callback(func():
			special_triggered.emit(player_id, is_ladder, landing_cell, destination_cell)
		)
		
		var dest_pos := board.get_cell_position(destination_cell)
		
		if is_ladder:
			# Majestic high-speed ascent with spinning victory aura
			move_tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 1.1) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			move_tween.parallel().tween_property($Visuals, "rotation_degrees:y", 720.0, 1.1) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			# Swooping snake slide
			move_tween.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), 1.1) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		landing_cell = destination_cell
	
	move_tween.finished.connect(_on_move_completed.bind(landing_cell))

func _on_move_completed(final_cell: int) -> void:
	current_cell = final_cell
	is_moving = false
	
	if visuals:
		visuals.rotation_degrees = Vector3.ZERO
		visuals.scale = Vector3.ONE
	
	# Power down superpower VFX smoothly
	if power_particles:
		power_particles.emitting = false
	if power_light:
		var light_off := create_tween()
		light_off.tween_property(power_light, "light_energy", 0.0, 0.4)
	
	_start_idle_bobbing()
	move_finished.emit(player_id, final_cell)
