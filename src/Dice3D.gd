class_name Dice3D
extends Node3D

@onready var mesh_instance: MeshInstance3D = $DieMesh

var is_rolling: bool = false
var base_pos: Vector3

# Face rotations in degrees for faces 1 through 6
var face_rotations: Dictionary = {
	1: Vector3(0, 0, 0),        # Top face (+Y)
	2: Vector3(-90, 0, 0),      # Front face (+Z)
	3: Vector3(0, 0, 90),       # Right face (+X)
	4: Vector3(0, 0, -90),      # Left face (-X)
	5: Vector3(90, 0, 0),       # Back face (-Z)
	6: Vector3(180, 0, 0),      # Bottom face (-Y)
}

func _ready() -> void:
	base_pos = position
	_create_dice_faces()
	
	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		var gc = get_node("/root/GameController")
		gc.dice_rolled.connect(_on_dice_rolled)

func _create_dice_faces() -> void:
	# Add big friendly 3D labels on all 6 faces of the cube with emoji dice or bold numbers
	var faces = [
		{"val": "1 ⭐", "pos": Vector3(0, 0.52, 0), "rot": Vector3(-90, 0, 0), "color": Color(0.95, 0.25, 0.35, 1.0)},
		{"val": "2 🎈", "pos": Vector3(0, 0, 0.52), "rot": Vector3(0, 0, 0), "color": Color(0.2, 0.7, 1.0, 1.0)},
		{"val": "3 🍭", "pos": Vector3(0.52, 0, 0), "rot": Vector3(0, 90, 0), "color": Color(0.3, 0.85, 0.45, 1.0)},
		{"val": "4 🚀", "pos": Vector3(-0.52, 0, 0), "rot": Vector3(0, -90, 0), "color": Color(1.0, 0.6, 0.2, 1.0)},
		{"val": "5 🌟", "pos": Vector3(0, 0, -0.52), "rot": Vector3(0, 180, 0), "color": Color(0.7, 0.4, 0.9, 1.0)},
		{"val": "6 👑", "pos": Vector3(0, -0.52, 0), "rot": Vector3(90, 0, 0), "color": Color(1.0, 0.8, 0.1, 1.0)},
	]
	
	for f in faces:
		var lbl := Label3D.new()
		lbl.text = f["val"]
		lbl.font_size = 46
		lbl.modulate = f["color"]
		lbl.outline_render_priority = 1
		lbl.outline_modulate = Color(1.0, 1.0, 1.0, 1.0)
		lbl.outline_size = 8
		lbl.position = f["pos"]
		lbl.rotation_degrees = f["rot"]
		$DieMesh.add_child(lbl)

func _on_dice_rolled(player_id: int, steps: int) -> void:
	roll_to_value(steps)

func roll_to_value(value: int) -> void:
	if is_rolling:
		return
	is_rolling = true
	
	var target_rot: Vector3 = face_rotations.get(value, Vector3.ZERO)
	var spin_x: float = target_rot.x + 360.0 * 2.0
	var spin_y: float = target_rot.y + 360.0 * 3.0
	var spin_z: float = target_rot.z + 360.0 * 2.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# High bouncy jump
	var jump_tween := create_tween()
	jump_tween.tween_property(self, "position:y", base_pos.y + 2.4, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.chain().tween_property(self, "position:y", base_pos.y, 0.42) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Rapid energetic spin
	tween.tween_property($DieMesh, "rotation_degrees", Vector3(spin_x, spin_y, spin_z), 0.65) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():
		$DieMesh.rotation_degrees = target_rot
		# Elastic punch scale on landing
		var pop := create_tween()
		pop.tween_property($DieMesh, "scale", Vector3(1.3, 0.8, 1.3), 0.08)
		pop.chain().tween_property($DieMesh, "scale", Vector3(1.0, 1.0, 1.0), 0.25) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		is_rolling = false
	)
