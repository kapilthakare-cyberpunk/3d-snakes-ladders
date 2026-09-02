class_name Dice3D
extends Node3D

@onready var mesh_instance: MeshInstance3D = $DieMesh

var is_rolling: bool = false
var base_pos: Vector3

signal roll_animation_done(value: int)

var face_rotations: Dictionary = {
	1: Vector3(0, 0, 0),
	2: Vector3(-90, 0, 0),
	3: Vector3(0, 0, 90),
	4: Vector3(0, 0, -90),
	5: Vector3(90, 0, 0),
	6: Vector3(180, 0, 0),
}

var dot_positions: Dictionary = {
	1: [Vector3(0, 0, 0)],
	2: [Vector3(-0.28, 0, -0.28), Vector3(0.28, 0, 0.28)],
	3: [Vector3(-0.28, 0, -0.28), Vector3(0, 0, 0), Vector3(0.28, 0, 0.28)],
	4: [Vector3(-0.28, 0, -0.28), Vector3(0.28, 0, -0.28), Vector3(-0.28, 0, 0.28), Vector3(0.28, 0, 0.28)],
	5: [Vector3(-0.28, 0, -0.28), Vector3(0.28, 0, -0.28), Vector3(0, 0, 0), Vector3(-0.28, 0, 0.28), Vector3(0.28, 0, 0.28)],
	6: [Vector3(-0.28, 0, -0.28), Vector3(0.28, 0, -0.28), Vector3(-0.28, 0, 0), Vector3(0.28, 0, 0), Vector3(-0.28, 0, 0.28), Vector3(0.28, 0, 0.28)],
}

func _ready() -> void:
	base_pos = position
	_create_dice_faces()

	if Engine.has_singleton("GameController") or get_node_or_null("/root/GameController"):
		var gc = get_node("/root/GameController")
		gc.dice_rolled.connect(_on_dice_rolled)

func _create_dice_faces() -> void:
	var faces = [
		{"val": 1, "pos": Vector3(0, 0.82, 0), "rot": Vector3(-90, 0, 0)},
		{"val": 2, "pos": Vector3(0, 0, 0.82), "rot": Vector3(0, 0, 0)},
		{"val": 3, "pos": Vector3(0.82, 0, 0), "rot": Vector3(0, 90, 0)},
		{"val": 4, "pos": Vector3(-0.82, 0, 0), "rot": Vector3(0, -90, 0)},
		{"val": 5, "pos": Vector3(0, 0, -0.82), "rot": Vector3(0, 180, 0)},
		{"val": 6, "pos": Vector3(0, -0.82, 0), "rot": Vector3(90, 0, 0)},
	]

	for f in faces:
		var face_node := Node3D.new()
		face_node.position = f["pos"]
		face_node.rotation_degrees = f["rot"]
		$DieMesh.add_child(face_node)

		var positions: Array = dot_positions.get(f["val"], [])
		for dot_pos in positions:
			var dot := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.09
			sphere.height = 0.18
			dot.mesh = sphere
			var mat := StandardMaterial3D.new()
			mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			match f["val"]:
				1: mat.albedo_color = Color(0.95, 0.25, 0.35)
				2: mat.albedo_color = Color(0.2, 0.7, 1.0)
				3: mat.albedo_color = Color(0.3, 0.85, 0.45)
				4: mat.albedo_color = Color(1.0, 0.6, 0.2)
				5: mat.albedo_color = Color(0.7, 0.4, 0.9)
				6: mat.albedo_color = Color(1.0, 0.8, 0.1)
			dot.material_override = mat
			dot.position = dot_pos
			face_node.add_child(dot)

func _on_dice_rolled(player_id: int, steps: int) -> void:
	roll_to_value(steps)

func roll_to_value(value: int) -> void:
	if is_rolling:
		return
	is_rolling = true

	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_sfx(AudioManager.SFX.DICE_ROLL, 0.1)

	var target_rot: Vector3 = face_rotations.get(value, Vector3.ZERO)
	var spin_x: float = target_rot.x + 360.0 * 2.0
	var spin_y: float = target_rot.y + 360.0 * 3.0
	var spin_z: float = target_rot.z + 360.0 * 2.0

	var tween := create_tween()
	tween.set_parallel(true)

	var jump_tween := create_tween()
	jump_tween.tween_property(self, "position:y", base_pos.y + 3.5, 0.30) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump_tween.chain().tween_property(self, "position:y", base_pos.y, 0.45) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	tween.tween_property($DieMesh, "rotation_degrees", Vector3(spin_x, spin_y, spin_z), 0.70) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		$DieMesh.rotation_degrees = target_rot
		var pop := create_tween()
		pop.tween_property($DieMesh, "scale", Vector3(1.3, 0.75, 1.3), 0.09)
		pop.chain().tween_property($DieMesh, "scale", Vector3(0.9, 1.15, 0.9), 0.09)
		pop.chain().tween_property($DieMesh, "scale", Vector3(1.0, 1.0, 1.0), 0.22) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		pop.finished.connect(func():
			is_rolling = false
			roll_animation_done.emit(value)
		)
	)
