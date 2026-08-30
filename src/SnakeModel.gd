@tool
class_name SnakeModel
extends Node3D

@export var body_material: StandardMaterial3D
@export var belly_material: StandardMaterial3D
@export var eye_material: StandardMaterial3D

func _ready() -> void:
	if not body_material:
		body_material = StandardMaterial3D.new()
		body_material.albedo_color = Color(0.18, 0.68, 0.28, 1.0) # Emerald Green
		body_material.roughness = 0.3
		body_material.metallic = 0.1
	
	if not eye_material:
		eye_material = StandardMaterial3D.new()
		eye_material.albedo_color = Color(0.95, 0.2, 0.1, 1.0) # Ruby Red glowing eyes
		eye_material.emission_enabled = true
		eye_material.emission = Color(0.95, 0.2, 0.1, 1.0)
		eye_material.emission_energy_multiplier = 1.5

func setup(head_pos: Vector3, tail_pos: Vector3) -> void:
	for child in get_children():
		child.queue_free()
	
	_ready()
	
	global_position = head_pos
	var diff := tail_pos - head_pos
	var total_dist := diff.length()
	if total_dist < 0.1:
		return
	
	var snake_root := Node3D.new()
	add_child(snake_root)
	
	var dir := diff.normalized()
	var right := dir.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	
	var segment_count: int = int(maxf(8.0, total_dist * 3.5))
	
	# Head
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.38
	head_mesh.height = 0.65
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = body_material
	head_node.position = Vector3(0.0, 0.35, 0.0)
	snake_root.add_child(head_node)
	
	# Eyes
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.08
	eye_mesh.height = 0.12
	
	var left_eye := MeshInstance3D.new()
	left_eye.mesh = eye_mesh
	left_eye.material_override = eye_material
	left_eye.position = Vector3(-0.16, 0.48, 0.12)
	snake_root.add_child(left_eye)
	
	var right_eye := MeshInstance3D.new()
	right_eye.mesh = eye_mesh
	right_eye.material_override = eye_material
	right_eye.position = Vector3(0.16, 0.48, 0.12)
	snake_root.add_child(right_eye)
	
	# Slithering body segments
	for i in range(1, segment_count + 1):
		var t := float(i) / float(segment_count)
		var base_pos := diff * t
		
		# Lateral wave + vertical elevation arch
		var wave := sin(t * PI * 3.0) * 0.45 * (1.0 - t * 0.3)
		var arch := sin(t * PI) * 0.5 + (1.0 - t) * 0.25 + 0.1
		
		var seg_pos := base_pos + right * wave + Vector3.UP * arch
		
		# Taper segment radius
		var radius: float = lerp(0.32, 0.12, t)
		var seg_mesh := SphereMesh.new()
		seg_mesh.radius = radius
		seg_mesh.height = radius * 2.0
		
		var seg_node := MeshInstance3D.new()
		seg_node.mesh = seg_mesh
		seg_node.material_override = body_material
		seg_node.position = seg_pos
		snake_root.add_child(seg_node)
