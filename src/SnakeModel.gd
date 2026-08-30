@tool
class_name SnakeModel
extends Node3D

var body_material: StandardMaterial3D
var spot_material: StandardMaterial3D
var eye_white_material: StandardMaterial3D
var pupil_material: StandardMaterial3D
var cheek_material: StandardMaterial3D

func _ready() -> void:
	if not body_material:
		body_material = StandardMaterial3D.new()
		body_material.albedo_color = Color(0.25, 0.78, 0.35, 1.0) # Bright Candy Green
		body_material.roughness = 0.3
	
	if not spot_material:
		spot_material = StandardMaterial3D.new()
		spot_material.albedo_color = Color(1.0, 0.85, 0.28, 1.0) # Sunny Yellow Polka Dots
		spot_material.roughness = 0.3
	
	if not eye_white_material:
		eye_white_material = StandardMaterial3D.new()
		eye_white_material.albedo_color = Color(0.98, 0.98, 0.98, 1.0) # Bright White Eye
		eye_white_material.roughness = 0.1
	
	if not pupil_material:
		pupil_material = StandardMaterial3D.new()
		pupil_material.albedo_color = Color(0.08, 0.08, 0.12, 1.0) # Shiny Black Pupil
		pupil_material.roughness = 0.1
	
	if not cheek_material:
		cheek_material = StandardMaterial3D.new()
		cheek_material.albedo_color = Color(1.0, 0.45, 0.55, 1.0) # Rosy Cheeks
		cheek_material.roughness = 0.4

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
	
	var segment_count: int = int(maxf(10.0, total_dist * 4.0))
	
	# --- Big Cute Cartoon Head ---
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.48
	head_mesh.height = 0.80
	var head_node := MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = body_material
	head_node.position = Vector3(0.0, 0.42, 0.0)
	snake_root.add_child(head_node)
	
	# Friendly Snout (soft rounded front sphere)
	var snout_mesh := SphereMesh.new()
	snout_mesh.radius = 0.28
	snout_mesh.height = 0.45
	var snout_node := MeshInstance3D.new()
	snout_node.mesh = snout_mesh
	snout_node.material_override = spot_material
	snout_node.position = Vector3(0.0, 0.32, -dir.z * 0.18)
	snake_root.add_child(snout_node)
	
	# Rosy Cheeks
	for side in [-1.0, 1.0]:
		var cheek_mesh := SphereMesh.new()
		cheek_mesh.radius = 0.14
		cheek_mesh.height = 0.22
		var cheek := MeshInstance3D.new()
		cheek.mesh = cheek_mesh
		cheek.material_override = cheek_material
		cheek.position = Vector3(side * 0.34, 0.32, 0.0)
		snake_root.add_child(cheek)
	
	# Giant Cartoon Googly Eyes (Eyeball + Pupil + White Highlight Catchlight)
	var eye_radius := 0.18
	var eyeball_mesh := SphereMesh.new()
	eyeball_mesh.radius = eye_radius
	eyeball_mesh.height = eye_radius * 2.0
	
	var pupil_radius := 0.09
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = pupil_radius
	pupil_mesh.height = pupil_radius * 1.6
	
	var catchlight_mesh := SphereMesh.new()
	catchlight_mesh.radius = 0.035
	catchlight_mesh.height = 0.07
	
	for side in [-1.0, 1.0]:
		var eye_center := Vector3(side * 0.22, 0.62, 0.12)
		
		var eyeball := MeshInstance3D.new()
		eyeball.mesh = eyeball_mesh
		eyeball.material_override = eye_white_material
		eyeball.position = eye_center
		snake_root.add_child(eyeball)
		
		# Black Pupil looking slightly forward-upward
		var pupil := MeshInstance3D.new()
		pupil.mesh = pupil_mesh
		pupil.material_override = pupil_material
		pupil.position = eye_center + Vector3(0.0, 0.04, 0.12)
		snake_root.add_child(pupil)
		
		# White twinkle shine on pupil
		var shine := MeshInstance3D.new()
		shine.mesh = catchlight_mesh
		shine.material_override = eye_white_material
		shine.position = pupil.position + Vector3(side * 0.02, 0.03, 0.06)
		snake_root.add_child(shine)
	
	# --- Slithering Rounded Body Segments with Alternating Spots ---
	for i in range(1, segment_count + 1):
		var t := float(i) / float(segment_count)
		var base_pos := diff * t
		
		# Cheerful wavy curve and playful arch
		var wave := sin(t * PI * 3.5) * 0.42 * (1.0 - t * 0.25)
		var arch := sin(t * PI) * 0.55 + (1.0 - t) * 0.25 + 0.12
		
		var seg_pos := base_pos + right * wave + Vector3.UP * arch
		
		var radius: float = lerp(0.38, 0.14, t)
		var seg_mesh := SphereMesh.new()
		seg_mesh.radius = radius
		seg_mesh.height = radius * 2.0
		
		var seg_node := MeshInstance3D.new()
		seg_node.mesh = seg_mesh
		# Alternating pattern: candy green body with sunny yellow segments every 3rd step
		seg_node.material_override = spot_material if (i % 3 == 0) else body_material
		seg_node.position = seg_pos
		snake_root.add_child(seg_node)
