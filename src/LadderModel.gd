@tool
class_name LadderModel
extends Node3D

# Rainbow palette for rungs
const RAINBOW_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.38),   # Coral Red
	Color(1.0, 0.58, 0.28),   # Sunny Orange
	Color(1.0, 0.82, 0.22),   # Bright Yellow
	Color(0.52, 0.82, 0.28),  # Lime Green
	Color(0.24, 0.68, 0.95),  # Sky Blue
	Color(0.68, 0.42, 0.88),  # Lavender Purple
]

var rail_material: StandardMaterial3D

func _ready() -> void:
	if not rail_material:
		rail_material = StandardMaterial3D.new()
		rail_material.albedo_color = Color(1.0, 0.84, 0.32, 1.0) # Golden Yellow Rails
		rail_material.roughness = 0.3
		rail_material.metallic = 0.4

func setup(start_pos: Vector3, end_pos: Vector3) -> void:
	for child in get_children():
		child.queue_free()
	
	_ready()
	
	global_position = start_pos
	var diff := end_pos - start_pos
	var length := diff.length()
	if length < 0.1:
		return
	
	var ladder_root := Node3D.new()
	add_child(ladder_root)
	
	# Rails
	var rail_width := 0.85
	var rail_thickness := 0.1
	var rail_height := 0.14
	
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(rail_thickness, rail_height, length)
	
	var left_rail := MeshInstance3D.new()
	left_rail.mesh = rail_mesh
	left_rail.material_override = rail_material
	left_rail.position = Vector3(-rail_width * 0.5, 0.18, -length * 0.5)
	ladder_root.add_child(left_rail)
	
	var right_rail := MeshInstance3D.new()
	right_rail.mesh = rail_mesh
	right_rail.material_override = rail_material
	right_rail.position = Vector3(rail_width * 0.5, 0.18, -length * 0.5)
	ladder_root.add_child(right_rail)
	
	# Rounded Golden End Caps on rails
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = rail_thickness * 0.8
	cap_mesh.height = rail_thickness * 1.6
	
	for side in [-1.0, 1.0]:
		var cap_bottom := MeshInstance3D.new()
		cap_bottom.mesh = cap_mesh
		cap_bottom.material_override = rail_material
		cap_bottom.position = Vector3(side * rail_width * 0.5, 0.18, 0.0)
		ladder_root.add_child(cap_bottom)
		
		var cap_top := MeshInstance3D.new()
		cap_top.mesh = cap_mesh
		cap_top.material_override = rail_material
		cap_top.position = Vector3(side * rail_width * 0.5, 0.18, -length)
		ladder_root.add_child(cap_top)
	
	# Rainbow Rungs
	var rung_spacing := 0.65
	var rung_count := int(length / rung_spacing)
	var rung_mesh := CylinderMesh.new()
	rung_mesh.top_radius = 0.05
	rung_mesh.bottom_radius = 0.05
	rung_mesh.height = rail_width - 0.04
	
	for i in range(1, rung_count):
		var dist := float(i) * rung_spacing
		var rung := MeshInstance3D.new()
		rung.mesh = rung_mesh
		
		# Rainbow material per rung
		var color_idx := (i - 1) % RAINBOW_COLORS.size()
		var rung_mat := StandardMaterial3D.new()
		rung_mat.albedo_color = RAINBOW_COLORS[color_idx]
		rung_mat.roughness = 0.25
		rung_mat.emission_enabled = true
		rung_mat.emission = RAINBOW_COLORS[color_idx]
		rung_mat.emission_energy_multiplier = 0.15
		
		rung.material_override = rung_mat
		rung.position = Vector3(0.0, 0.18, -dist)
		rung.rotation_degrees = Vector3(0.0, 0.0, 90.0) # Horizontal cylinder
		ladder_root.add_child(rung)
	
	# Orient towards end_pos with vertical tilt
	var up_vec := Vector3.UP
	if abs(diff.normalized().dot(Vector3.UP)) > 0.99:
		up_vec = Vector3.FORWARD
	ladder_root.look_at(ladder_root.global_position + diff, up_vec)
