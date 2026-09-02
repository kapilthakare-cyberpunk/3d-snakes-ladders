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
var glow_ring: MeshInstance3D
var glow_tween: Tween
var trail_particles: CPUParticles3D
var landing_burst: CPUParticles3D

@onready var visuals: Node3D = $Visuals
@onready var trail_origin: Node3D = $Visuals

func _ready() -> void:
	setup_player(player_id)
	_start_idle_bobbing()
	_create_trail()
	_create_landing_burst()

func setup_player(p_id: int) -> void:
	player_id = p_id
	_build_superhero_miniature()
	_setup_power_effects()
	_build_glow_ring()

func _create_trail() -> void:
	if trail_particles:
		trail_particles.queue_free()
	trail_particles = CPUParticles3D.new()
	trail_particles.emitting = false
	trail_particles.amount = 24
	trail_particles.lifetime = 0.55
	trail_particles.speed_scale = 0.9
	trail_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail_particles.emission_sphere_radius = 0.25
	trail_particles.gravity = Vector3(0, -1.8, 0)
	trail_particles.scale_amount_min = 0.06
	trail_particles.scale_amount_max = 0.14

	var trail_mat := StandardMaterial3D.new()
	trail_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.albedo_color = Color(1, 1, 1, 0.0)

	var trail_mesh := SphereMesh.new()
	trail_mesh.radius = 0.06
	trail_mesh.height = 0.12
	trail_particles.mesh = trail_mesh
	trail_particles.material = trail_mat

	match player_id:
		1: trail_particles.color = Color(0.2, 0.95, 1.0, 0.85)
		2: trail_particles.color = Color(0.98, 0.98, 1.0, 0.82)
		3: trail_particles.color = Color(1.0, 0.88, 0.25, 0.85)

	trail_particles.position = Vector3(0, 0.08, 0)
	add_child(trail_particles)

func _create_landing_burst() -> void:
	if landing_burst:
		landing_burst.queue_free()
	landing_burst = CPUParticles3D.new()
	landing_burst.emitting = false
	landing_burst.amount = 18
	landing_burst.lifetime = 0.45
	landing_burst.speed_scale = 1.4
	landing_burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	landing_burst.emission_sphere_radius = 0.15
	landing_burst.gravity = Vector3(0, -4.5, 0)
	landing_burst.scale_amount_min = 0.05
	landing_burst.scale_amount_max = 0.12

	var burst_mat := StandardMaterial3D.new()
	burst_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	burst_mat.vertex_color_use_as_albedo = true
	burst_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var burst_mesh := SphereMesh.new()
	burst_mesh.radius = 0.05
	burst_mesh.height = 0.1
	landing_burst.mesh = burst_mesh
	landing_burst.material = burst_mat

	match player_id:
		1: landing_burst.color = Color(0.25, 0.95, 1.0, 0.95)
		2: landing_burst.color = Color(0.98, 0.98, 1.0, 0.92)
		3: landing_burst.color = Color(1.0, 0.88, 0.25, 0.95)

	landing_burst.position = Vector3(0, 0.04, 0)
	add_child(landing_burst)

func _emit_landing_burst() -> void:
	if not landing_burst:
		return
	landing_burst.emitting = false
	landing_burst.restart()
	landing_burst.emitting = true
	var gc = get_node_or_null("/root/AudioManager")
	if gc:
		gc.play_sfx(AudioManager.SFX.LANDING_BURST, 0.15)

func _build_glow_ring() -> void:
	if glow_ring:
		glow_ring.queue_free()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.28
	ring_mesh.outer_radius = 0.42
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 16
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.emission_enabled = true
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(1, 1, 1, 0.0)
	match player_id:
		1:
			ring_mat.emission = Color(0.25, 0.9, 1.0)
			ring_mat.albedo_color = Color(0.25, 0.9, 1.0, 0.55)
		2:
			ring_mat.emission = Color(0.6, 0.85, 1.0)
			ring_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.55)
		3:
			ring_mat.emission = Color(1.0, 0.85, 0.2)
			ring_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.55)
	ring_mat.emission_energy_multiplier = 2.2
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mesh.material = ring_mat
	glow_ring = MeshInstance3D.new()
	glow_ring.mesh = ring_mesh
	glow_ring.position = Vector3(0, 0.015, 0)
	glow_ring.rotation_degrees = Vector3(90, 0, 0)
	add_child(glow_ring)
	_pulse_glow_ring()

func _pulse_glow_ring() -> void:
	if glow_tween:
		glow_tween.kill()
	if not glow_ring:
		return
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(glow_ring, "scale", Vector3(1.12, 1.0, 1.12), 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.chain().tween_property(glow_ring, "scale", Vector3(0.9, 1.0, 0.9), 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_power_effects() -> void:
	if power_particles:
		power_particles.queue_free()
	if power_light:
		power_light.queue_free()

	power_particles = CPUParticles3D.new()
	power_particles.emitting = false
	power_particles.amount = 48
	power_particles.lifetime = 0.9
	power_particles.speed_scale = 1.2
	power_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	power_particles.emission_sphere_radius = 0.35
	power_particles.gravity = Vector3(0, -2.5, 0)
	power_particles.scale_amount_min = 0.08
	power_particles.scale_amount_max = 0.2

	var part_mat := StandardMaterial3D.new()
	part_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	part_mat.vertex_color_use_as_albedo = true

	var part_mesh := SphereMesh.new()
	part_mesh.radius = 0.08
	part_mesh.height = 0.16
	part_mesh.material = part_mat
	power_particles.mesh = part_mesh

	power_light = OmniLight3D.new()
	power_light.light_energy = 0.0
	power_light.omni_range = 4.5

	match player_id:
		1:
			power_particles.color = Color(0.2, 0.95, 1.0, 0.95)
			power_particles.direction = Vector3(0, -1, -0.6)
			power_particles.spread = 25.0
			power_particles.initial_velocity_min = 2.5
			power_particles.initial_velocity_max = 4.5
			power_light.light_color = Color(0.25, 0.95, 1.0)
		2:
			power_particles.color = Color(0.98, 0.98, 1.0, 0.92)
			power_particles.direction = Vector3(0, 0.6, -1)
			power_particles.spread = 50.0
			power_particles.initial_velocity_min = 1.5
			power_particles.initial_velocity_max = 3.0
			power_light.light_color = Color(0.9, 0.95, 1.0)
		3:
			power_particles.color = Color(1.0, 0.88, 0.25, 0.95)
			power_particles.direction = Vector3(0, 1, 0)
			power_particles.spread = 180.0
			power_particles.initial_velocity_min = 1.8
			power_particles.initial_velocity_max = 3.5
			power_light.light_color = Color(1.0, 0.88, 0.25)

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

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _emissive_mat(color: Color, energy: float = 2.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _mesh_inst(mesh: Mesh, mat: Material, pos: Vector3, rot_deg := Vector3.ZERO, s := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	if rot_deg != Vector3.ZERO:
		n.rotation_degrees = rot_deg
	if s != Vector3.ONE:
		n.scale = s
	visuals.add_child(n)
	return n

func _build_iron_man() -> void:
	var red  := _mat(Color(0.82, 0.10, 0.14), 0.85, 0.18)
	var gold := _mat(Color(0.98, 0.80, 0.15), 0.92, 0.12)
	var arc  := _emissive_mat(Color(0.25, 0.95, 1.0), 3.0)
	var dark := _mat(Color(0.12, 0.12, 0.18), 0.1, 0.5)

	var base := CylinderMesh.new()
	base.top_radius = 0.34; base.bottom_radius = 0.4; base.height = 0.1
	_mesh_inst(base, gold, Vector3(0, 0.05, 0))

	var legs := CylinderMesh.new()
	legs.top_radius = 0.22; legs.bottom_radius = 0.28; legs.height = 0.22
	_mesh_inst(legs, red, Vector3(0, 0.21, 0))

	var torso := CylinderMesh.new()
	torso.top_radius = 0.30; torso.bottom_radius = 0.24; torso.height = 0.30
	_mesh_inst(torso, red, Vector3(0, 0.41, 0))

	_mesh_inst(SphereMesh.new(), arc, Vector3(0, 0.46, 0.28), Vector3.ZERO, Vector3(0.13, 0.13, 0.07))

	for side in [-1.0, 1.0]:
		var p := SphereMesh.new(); p.radius = 0.13; p.height = 0.22
		_mesh_inst(p, gold, Vector3(side * 0.34, 0.50, 0.0))

	var arm := CylinderMesh.new()
	arm.top_radius = 0.07; arm.bottom_radius = 0.07; arm.height = 0.24
	for side in [-1.0, 1.0]:
		_mesh_inst(arm, red, Vector3(side * 0.37, 0.34, 0.02), Vector3(12, 0, side * -10))
		_mesh_inst(SphereMesh.new(), arc, Vector3(side * 0.37, 0.22, 0.05), Vector3.ZERO, Vector3(0.07, 0.07, 0.04))

	var head := SphereMesh.new(); head.radius = 0.30; head.height = 0.56
	_mesh_inst(head, red, Vector3(0, 0.73, 0))

	var face := BoxMesh.new(); face.size = Vector3(0.28, 0.32, 0.12)
	_mesh_inst(face, gold, Vector3(0, 0.72, 0.24))

	for side in [-1.0, 1.0]:
		var eye := BoxMesh.new(); eye.size = Vector3(0.08, 0.022, 0.02)
		_mesh_inst(eye, arc, Vector3(side * 0.065, 0.76, 0.31))

	var jaw := BoxMesh.new(); jaw.size = Vector3(0.22, 0.06, 0.10)
	_mesh_inst(jaw, gold, Vector3(0, 0.60, 0.24))

func _build_spider_man() -> void:
	var red   := _mat(Color(0.90, 0.12, 0.15), 0.0, 0.28)
	var blue  := _mat(Color(0.10, 0.30, 0.90), 0.0, 0.28)
	var black := _mat(Color(0.05, 0.05, 0.08), 0.0, 0.18)
	var white := _mat(Color(0.96, 0.97, 1.00), 0.0, 0.10)

	var base := CylinderMesh.new()
	base.top_radius = 0.34; base.bottom_radius = 0.4; base.height = 0.1
	_mesh_inst(base, blue, Vector3(0, 0.05, 0))

	var legs := CylinderMesh.new()
	legs.top_radius = 0.22; legs.bottom_radius = 0.28; legs.height = 0.22
	_mesh_inst(legs, blue, Vector3(0, 0.21, 0))

	var torso := CylinderMesh.new()
	torso.top_radius = 0.30; torso.bottom_radius = 0.24; torso.height = 0.30
	_mesh_inst(torso, red, Vector3(0, 0.41, 0))

	var spider_body := BoxMesh.new()
	spider_body.size = Vector3(0.06, 0.08, 0.02)
	_mesh_inst(spider_body, black, Vector3(0, 0.44, 0.29))
	for side in [-1.0, 1.0]:
		var leg_upper := BoxMesh.new(); leg_upper.size = Vector3(0.10, 0.015, 0.015)
		_mesh_inst(leg_upper, black, Vector3(side * 0.06, 0.46, 0.29), Vector3(0, 0, side * 20))
		var leg_lower := BoxMesh.new(); leg_lower.size = Vector3(0.10, 0.015, 0.015)
		_mesh_inst(leg_lower, black, Vector3(side * 0.06, 0.42, 0.29), Vector3(0, 0, side * -20))

	var arm := CylinderMesh.new()
	arm.top_radius = 0.068; arm.bottom_radius = 0.068; arm.height = 0.24
	for side in [-1.0, 1.0]:
		_mesh_inst(arm, red, Vector3(side * 0.36, 0.34, 0.02), Vector3(18, 0, side * -16))
		var s := BoxMesh.new(); s.size = Vector3(0.05, 0.04, 0.04)
		_mesh_inst(s, black, Vector3(side * 0.37, 0.22, 0.06))

	var head := SphereMesh.new(); head.radius = 0.32; head.height = 0.60
	_mesh_inst(head, red, Vector3(0, 0.75, 0))

	for side in [-1.0, 1.0]:
		var outer := SphereMesh.new()
		_mesh_inst(outer, black, Vector3(side * 0.115, 0.78, 0.27), Vector3(0, 0, side * -22), Vector3(0.20, 0.24, 0.08))
		var inner := SphereMesh.new()
		_mesh_inst(inner, white, Vector3(side * 0.112, 0.78, 0.30), Vector3(0, 0, side * -22), Vector3(0.16, 0.20, 0.06))
		_mesh_inst(SphereMesh.new(), white, Vector3(side * 0.09, 0.82, 0.32), Vector3.ZERO, Vector3(0.04, 0.04, 0.04))

func _build_wonder_woman() -> void:
	var red    := _mat(Color(0.88, 0.10, 0.28), 0.0, 0.28)
	var blue   := _mat(Color(0.12, 0.24, 0.80), 0.0, 0.28)
	var gold   := _mat(Color(0.98, 0.82, 0.15), 0.92, 0.12)
	var silver := _mat(Color(0.90, 0.93, 0.98), 0.95, 0.08)
	var skin   := _mat(Color(0.98, 0.84, 0.72), 0.0, 0.42)
	var hair   := _mat(Color(0.09, 0.09, 0.14), 0.0, 0.32)

	var base := CylinderMesh.new()
	base.top_radius = 0.34; base.bottom_radius = 0.4; base.height = 0.1
	_mesh_inst(base, gold, Vector3(0, 0.05, 0))

	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.26; skirt.bottom_radius = 0.30; skirt.height = 0.20
	_mesh_inst(skirt, blue, Vector3(0, 0.20, 0))

	var belt := CylinderMesh.new()
	belt.top_radius = 0.27; belt.bottom_radius = 0.27; belt.height = 0.055
	_mesh_inst(belt, gold, Vector3(0, 0.30, 0))

	var lasso := TorusMesh.new()
	lasso.inner_radius = 0.055; lasso.outer_radius = 0.10
	_mesh_inst(lasso, gold, Vector3(0.26, 0.28, 0.04), Vector3(88, 0, 0))

	var torso := CylinderMesh.new()
	torso.top_radius = 0.28; torso.bottom_radius = 0.26; torso.height = 0.26
	_mesh_inst(torso, red, Vector3(0, 0.43, 0))

	var eagle := BoxMesh.new(); eagle.size = Vector3(0.28, 0.09, 0.05)
	_mesh_inst(eagle, gold, Vector3(0, 0.50, 0.27))

	var arm := CylinderMesh.new()
	arm.top_radius = 0.065; arm.bottom_radius = 0.065; arm.height = 0.24
	for side in [-1.0, 1.0]:
		_mesh_inst(arm, skin, Vector3(side * 0.34, 0.36, 0.02), Vector3(14, 0, side * -14))
		var b := CylinderMesh.new(); b.top_radius = 0.08; b.bottom_radius = 0.08; b.height = 0.08
		_mesh_inst(b, silver, Vector3(side * 0.35, 0.24, 0.04))

	var head := SphereMesh.new(); head.radius = 0.30; head.height = 0.56
	_mesh_inst(head, skin, Vector3(0, 0.74, 0))

	var hair_dome := SphereMesh.new(); hair_dome.radius = 0.33; hair_dome.height = 0.58
	_mesh_inst(hair_dome, hair, Vector3(0, 0.76, -0.06))

	var tiara := BoxMesh.new(); tiara.size = Vector3(0.32, 0.09, 0.14)
	_mesh_inst(tiara, gold, Vector3(0, 0.83, 0.18))

	_mesh_inst(SphereMesh.new(), _emissive_mat(Color(1.0, 0.15, 0.15), 1.8),
		Vector3(0, 0.87, 0.26), Vector3.ZERO, Vector3(0.065, 0.065, 0.065))

	for side in [-1.0, 1.0]:
		_mesh_inst(SphereMesh.new(), _mat(Color(0.12, 0.12, 0.18)), Vector3(side * 0.10, 0.76, 0.28),
			Vector3.ZERO, Vector3(0.08, 0.10, 0.06))
		_mesh_inst(SphereMesh.new(), _mat(Color(1.0, 1.0, 1.0)), Vector3(side * 0.09, 0.78, 0.30),
			Vector3.ZERO, Vector3(0.03, 0.03, 0.03))

func _start_idle_bobbing() -> void:
	if idle_tween:
		idle_tween.kill()
	idle_tween = create_tween().set_loops()

	idle_tween.tween_property($Visuals, "position:y", 0.06, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property($Visuals, "scale", Vector3(1.04, 0.97, 1.04), 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	idle_tween.tween_property($Visuals, "position:y", 0.0, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.parallel().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 1.3) \
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
	if trail_particles:
		trail_particles.emitting = false
	_start_idle_bobbing()
	_pulse_glow_ring()

func move_steps(steps: int) -> void:
	if is_moving or steps <= 0:
		return
	is_moving = true

	if idle_tween:
		idle_tween.kill()
	if glow_tween:
		glow_tween.kill()

	if power_particles:
		power_particles.emitting = true
	if power_light:
		var lt := create_tween()
		lt.tween_property(power_light, "light_energy", 2.5, 0.3)

	if trail_particles:
		trail_particles.restart()
		trail_particles.emitting = true

	var entry_tw := create_tween()
	entry_tw.tween_property($Visuals, "scale", Vector3(1.25, 0.78, 1.25), 0.12).set_trans(Tween.TRANS_BACK)
	entry_tw.chain().tween_property($Visuals, "scale", Vector3(0.95, 1.08, 0.95), 0.10)
	entry_tw.chain().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.08)

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

	var hop_time := 0.60

	for cell_idx in path:
		var target_pos := board.get_cell_position(cell_idx)

		var hz := create_tween().set_parallel(true)
		hz.tween_property(self, "global_position:x", target_pos.x, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hz.tween_property(self, "global_position:z", target_pos.z, hop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		match player_id:
			1:
				var vy := create_tween()
				vy.tween_property(self, "global_position:y", target_pos.y + 1.2, hop_time * 0.42) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				vy.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.58) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				var rot := create_tween()
				rot.tween_property($Visuals, "rotation_degrees:x", -40.0, hop_time * 0.35).set_trans(Tween.TRANS_QUAD)
				rot.chain().tween_property($Visuals, "rotation_degrees:x", 0.0, hop_time * 0.65).set_trans(Tween.TRANS_BACK)

			2:
				var vy := create_tween()
				vy.tween_property(self, "global_position:y", target_pos.y + 1.5, hop_time * 0.50) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				vy.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.50) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				var flip := create_tween()
				flip.tween_property($Visuals, "rotation_degrees:x", 360.0, hop_time) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

			3:
				var vy := create_tween()
				vy.tween_property(self, "global_position:y", target_pos.y + 1.3, hop_time * 0.45) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				vy.chain().tween_property(self, "global_position:y", target_pos.y + 0.35, hop_time * 0.55) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				var spin := create_tween()
				spin.tween_property($Visuals, "rotation_degrees:y", 360.0, hop_time) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		var squash := create_tween()
		squash.tween_interval(hop_time * 0.75)
		squash.chain().tween_property($Visuals, "scale", Vector3(1.18, 0.78, 1.18), 0.08).set_trans(Tween.TRANS_QUAD)
		squash.chain().tween_property($Visuals, "scale", Vector3(0.92, 1.12, 0.92), 0.08)
		squash.chain().tween_property($Visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.10).set_trans(Tween.TRANS_ELASTIC)

		var gc := get_node_or_null("/root/AudioManager")
		if gc:
			gc.play_sfx(AudioManager.SFX.HOP, 0.2)

		await get_tree().create_timer(hop_time + 0.06).timeout

	var landing_cell: int = path[-1]
	if SnLScript.connections.has(landing_cell):
		var destination_cell: int = SnLScript.connections[landing_cell]
		var is_ladder: bool = landing_cell < destination_cell
		special_triggered.emit(player_id, is_ladder, landing_cell, destination_cell)

		var dest_pos := board.get_cell_position(destination_cell)
		var travel_time := 1.15

		if is_ladder:
			var ascend := create_tween().set_parallel(true)
			ascend.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), travel_time) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			ascend.tween_property($Visuals, "rotation_degrees:y", 720.0, travel_time) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if trail_particles:
				trail_particles.emitting = false
		else:
			var descend := create_tween().set_parallel(true)
			descend.tween_property(self, "global_position", dest_pos + Vector3(0, 0.35, 0), travel_time) \
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			descend.tween_property($Visuals, "rotation_degrees:x", 360.0, travel_time) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		await get_tree().create_timer(travel_time + 0.1).timeout
		landing_cell = destination_cell

	_on_move_completed(landing_cell)

func _on_move_completed(final_cell: int) -> void:
	current_cell = final_cell
	is_moving = false

	if visuals:
		var snap := create_tween().set_parallel(true)
		snap.tween_property(visuals, "rotation_degrees", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_SINE)
		snap.tween_property(visuals, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_SINE)

	if power_particles:
		power_particles.emitting = false
	if power_light:
		var lt := create_tween()
		lt.tween_property(power_light, "light_energy", 0.0, 0.5)
	if trail_particles:
		trail_particles.emitting = false

	_emit_landing_burst()
	_start_idle_bobbing()
	_pulse_glow_ring()
	move_finished.emit(player_id, final_cell)
