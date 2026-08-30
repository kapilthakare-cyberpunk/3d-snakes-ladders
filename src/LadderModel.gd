@tool
class_name LadderModel
extends Node3D

@export var rail_material: StandardMaterial3D
@export var rung_material: StandardMaterial3D

func _ready() -> void:
	if not rail_material:
		rail_material = StandardMaterial3D.new()
		rail_material.albedo_color = Color(0.72, 0.48, 0.22, 1.0) # Golden Oak Wood
		rail_material.roughness = 0.5
		rail_material.metallic = 0.1
	
	if not rung_material:
		rung_material = StandardMaterial3D.new()
		rung_material.albedo_color = Color(0.85, 0.65, 0.35, 1.0) # Polished Wood
		rung_material.roughness = 0.4

func setup(start_pos: Vector3, end_pos: Vector3) -> void:
	# Clear any existing children
	for child in get_children():
		child.queue_free()
	
	_ready()
	
	global_position = start_pos
	var diff := end_pos - start_pos
	var length := diff.length()
	if length < 0.1:
		return
	
	# Create a local container that aligns with direction
	var ladder_root := Node3D.new()
	add_child(ladder_root)
	
	# Rails
	var rail_width := 0.8
	var rail_thickness := 0.08
	var rail_height := 0.12
	
	# Left rail
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(rail_thickness, rail_height, length)
	
	var left_rail := MeshInstance3D.new()
	left_rail.mesh = rail_mesh
	left_rail.material_override = rail_material
	left_rail.position = Vector3(-rail_width * 0.5, 0.15, -length * 0.5)
	ladder_root.add_child(left_rail)
	
	# Right rail
	var right_rail := MeshInstance3D.new()
	right_rail.mesh = rail_mesh
	right_rail.material_override = rail_material
	right_rail.position = Vector3(rail_width * 0.5, 0.15, -length * 0.5)
	ladder_root.add_child(right_rail)
	
	# Rungs
	var rung_spacing := 0.7
	var rung_count := int(length / rung_spacing)
	var rung_mesh := BoxMesh.new()
	rung_mesh.size = Vector3(rail_width - 0.04, 0.06, 0.08)
	
	for i in range(1, rung_count):
		var dist := float(i) * rung_spacing
		var rung := MeshInstance3D.new()
		rung.mesh = rung_mesh
		rung.material_override = rung_material
		rung.position = Vector3(0.0, 0.15, -dist)
		ladder_root.add_child(rung)
	
	# Orient towards end_pos with vertical tilt
	var up_vec := Vector3.UP
	if abs(diff.normalized().dot(Vector3.UP)) > 0.99:
		up_vec = Vector3.FORWARD
	ladder_root.look_at(ladder_root.global_position + diff, up_vec)
