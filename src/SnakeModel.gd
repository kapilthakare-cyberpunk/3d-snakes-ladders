@tool
class_name SnakeModel
extends Node3D

var green_material: StandardMaterial3D
var yellow_material: StandardMaterial3D
var eye_white_material: StandardMaterial3D
var pupil_material: StandardMaterial3D
var tongue_material: StandardMaterial3D
var body_multimesh: MultiMeshInstance3D

const OPTIMIZED_SEGMENT_COUNT: int = 18

func _ready() -> void:
	if not green_material:
		green_material = StandardMaterial3D.new()
		green_material.albedo_color = Color(0.12, 0.68, 0.28, 1.0)
		green_material.roughness = 0.25

	if not yellow_material:
		yellow_material = StandardMaterial3D.new()
		yellow_material.albedo_color = Color(0.98, 0.82, 0.15, 1.0)
		yellow_material.roughness = 0.25

	if not eye_white_material:
		eye_white_material = StandardMaterial3D.new()
		eye_white_material.albedo_color = Color(0.98, 0.98, 0.98, 1.0)
		eye_white_material.roughness = 0.1

	if not pupil_material:
		pupil_material = StandardMaterial3D.new()
		pupil_material.albedo_color = Color(0.05, 0.05, 0.08, 1.0)
		pupil_material.roughness = 0.1

	if not tongue_material:
		tongue_material = StandardMaterial3D.new()
		tongue_material.albedo_color = Color(0.95, 0.15, 0.25, 1.0)
		tongue_material.roughness = 0.2

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

	var head_forward := -dir

	var head_container := Node3D.new()
	head_container.position = Vector3(0.0, 0.35, 0.0)
	snake_root.add_child(head_container)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.38
	head_mesh.height = 0.65
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = green_material
	head_node.scale = Vector3(1.15, 0.75, 1.35)
	head_container.add_child(head_node)

	var snout_mesh := SphereMesh.new()
	snout_mesh.radius = 0.22
	snout_mesh.height = 0.35
	var snout_node := MeshInstance3D.new()
	snout_node.mesh = snout_mesh
	snout_node.material_override = yellow_material
	snout_node.position = Vector3(0.0, -0.05, 0.35)
	head_container.add_child(snout_node)

	var tongue_main := MeshInstance3D.new()
	var tongue_mesh := BoxMesh.new()
	tongue_mesh.size = Vector3(0.08, 0.02, 0.3)
	tongue_main.mesh = tongue_mesh
	tongue_main.material_override = tongue_material
	tongue_main.position = Vector3(0.0, -0.1, 0.52)
	head_container.add_child(tongue_main)

	var fork_mesh := BoxMesh.new()
	fork_mesh.size = Vector3(0.04, 0.02, 0.15)
	var fork_l := MeshInstance3D.new()
	fork_l.mesh = fork_mesh
	fork_l.material_override = tongue_material
	fork_l.position = Vector3(-0.04, -0.1, 0.72)
	fork_l.rotation_degrees = Vector3(0.0, -25.0, 0.0)
	head_container.add_child(fork_l)

	var fork_r := MeshInstance3D.new()
	fork_r.mesh = fork_mesh
	fork_r.material_override = tongue_material
	fork_r.position = Vector3(0.04, -0.1, 0.72)
	fork_r.rotation_degrees = Vector3(0.0, 25.0, 0.0)
	head_container.add_child(fork_r)

	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.14
	eye_mesh.height = 0.24
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.07
	pupil_mesh.height = 0.14

	for side in [-1.0, 1.0]:
		var eye_node := MeshInstance3D.new()
		eye_node.mesh = eye_mesh
		eye_node.material_override = eye_white_material
		eye_node.position = Vector3(side * 0.22, 0.2, 0.15)
		head_container.add_child(eye_node)

		var pupil_node := MeshInstance3D.new()
		pupil_node.mesh = pupil_mesh
		pupil_node.material_override = pupil_material
		pupil_node.position = Vector3(side * 0.22, 0.24, 0.25)
		head_container.add_child(pupil_node)

	body_multimesh = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = SphereMesh.new()
	mm.mesh.radius = 1.0
	mm.mesh.height = 2.2
	mm.instance_count = OPTIMIZED_SEGMENT_COUNT
	mm.visible_instance_count = OPTIMIZED_SEGMENT_COUNT
	body_multimesh.multimesh = mm
	body_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTER_SETTINGS_OFF
	snake_root.add_child(body_multimesh)

	for i in range(OPTIMIZED_SEGMENT_COUNT):
		var t := float(i + 1) / float(OPTIMIZED_SEGMENT_COUNT)
		var base_pos := diff * t
		var wave_freq := 3.0
		var wave := sin(t * PI * wave_freq) * 0.55 * (1.0 - t * 0.2)
		var height_arch := sin(t * PI) * 0.35 + (1.0 - t) * 0.25 + 0.12
		var seg_pos := base_pos + right * wave + Vector3.UP * height_arch
		var radius := lerp(0.32, 0.06, t)
		var xform := Transform3D(Basis(), seg_pos)
		xform = xform.scaled_local(Vector3(radius, radius * 2.2, radius))
		mm.set_instance_transform(i, xform)
		var mat := yellow_material if int(i / 3) % 2 == 1 else green_material
		mm.set_instance_color(i, mat.albedo_color)

	mm.instance_count = OPTIMIZED_SEGMENT_COUNT

	head_container.look_at(head_container.global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
