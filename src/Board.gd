class_name Board
extends Node3D

const BOARD_SIZE := 10
const CELL_SIZE := 2.0
const BOARD_ORIGIN := Vector3(-9.0, 0.0, -9.0) # Center of cell 1 at bottom-left

const SnLScript = preload("res://singleton/SnLData.gd")

var cells: Array[Vector3] = [] # 1-based world positions (index 0 unused)
var tiles_container: Node3D
var objects_container: Node3D

# ── 8 vivid tile colors matching classic Snakes & Ladders boards ──
const TILE_COLORS: Array[Color] = [
	Color(0.95, 0.20, 0.25),  # Red
	Color(0.15, 0.55, 0.95),  # Blue
	Color(0.20, 0.80, 0.30),  # Green
	Color(1.00, 0.88, 0.10),  # Yellow
	Color(1.00, 0.55, 0.10),  # Orange
	Color(0.60, 0.22, 0.85),  # Purple
	Color(1.00, 0.35, 0.75),  # Pink / Magenta
	Color(0.10, 0.85, 0.80),  # Cyan / Teal
]

func _ready() -> void:
	generate_cells()
	create_visual_board()
	place_snakes_and_ladders()

func generate_cells() -> void:
	cells.resize(BOARD_SIZE * BOARD_SIZE + 1)
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var idx := y * BOARD_SIZE + x + 1
			# Boustrophedon winding
			var grid_x := x if (y % 2 == 0) else (BOARD_SIZE - 1 - x)
			cells[idx] = BOARD_ORIGIN + Vector3(grid_x * CELL_SIZE, 0.0, y * CELL_SIZE)

func get_cell_position(idx: int, player_index: int = 0, total_players_on_cell: int = 1) -> Vector3:
	if idx < 1 or idx >= cells.size():
		return Vector3.ZERO

	var base_pos := cells[idx]
	if total_players_on_cell <= 1:
		return base_pos

	if total_players_on_cell == 2:
		var offset_x: float = -0.45 if player_index == 0 else 0.45
		return base_pos + Vector3(offset_x, 0.0, 0.0)
	else:
		var angles := [-90.0, 30.0, 150.0]
		var angle_rad: float = deg_to_rad(angles[player_index % 3])
		var radius := 0.48
		return base_pos + Vector3(cos(angle_rad) * radius, 0.0, sin(angle_rad) * radius)

func _get_tile_color(idx: int) -> Color:
	# Deterministic "random-looking" color per cell using a hash
	# This gives a cheerful, scattered look like the reference image
	var hash_val := ((idx * 7 + 13) * 31) % TILE_COLORS.size()
	return TILE_COLORS[hash_val]

func create_visual_board() -> void:
	tiles_container = Node3D.new()
	tiles_container.name = "TilesContainer"
	add_child(tiles_container)

	# Special tile materials
	var mat_start := StandardMaterial3D.new()
	mat_start.albedo_color = Color(0.10, 0.82, 0.40)
	mat_start.roughness = 0.3
	mat_start.emission_enabled = true
	mat_start.emission = Color(0.10, 0.82, 0.40)
	mat_start.emission_energy_multiplier = 0.35

	var mat_win := StandardMaterial3D.new()
	mat_win.albedo_color = Color(0.98, 0.78, 0.12)
	mat_win.roughness = 0.22
	mat_win.metallic = 0.35
	mat_win.emission_enabled = true
	mat_win.emission = Color(0.98, 0.78, 0.12)
	mat_win.emission_energy_multiplier = 0.4

	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(CELL_SIZE - 0.06, 0.20, CELL_SIZE - 0.06)

	for idx in range(1, BOARD_SIZE * BOARD_SIZE + 1):
		var pos: Vector3 = cells[idx]
		var tile := MeshInstance3D.new()
		tile.mesh = tile_mesh
		tile.position = pos + Vector3(0.0, -0.10, 0.0)

		# Pick tile material
		if idx == 1:
			tile.material_override = mat_start
		elif idx == 100:
			tile.material_override = mat_win
		else:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = _get_tile_color(idx)
			mat.roughness = 0.35
			tile.material_override = mat

		tiles_container.add_child(tile)

		# ── Large bold number label — white text, thick black outline ──
		var label := Label3D.new()
		if idx == 1:
			label.text = "⭐ 1"
		elif idx == 100:
			label.text = "👑 100"
		else:
			label.text = str(idx)

		label.font_size = 52
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = pos + Vector3(0.0, 0.12, 0.0)

		# Flat on tile surface, angled slightly toward camera for readability
		label.rotation_degrees = Vector3(-55.0, 0.0, 0.0)

		# White text with thick black outline — readable on ANY color tile
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.outline_size = 14

		tiles_container.add_child(label)

	# ── Thick dark border frame ──
	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.10, 0.10, 0.18)
	border_mat.roughness = 0.4

	var total_span := float(BOARD_SIZE) * CELL_SIZE
	var frame_w := 0.8
	var frame_h := 0.32

	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(total_span + frame_w * 2.0, frame_h, frame_w)

	var border_s := MeshInstance3D.new()
	border_s.mesh = h_mesh
	border_s.material_override = border_mat
	border_s.position = Vector3(0.0, -frame_h * 0.5, -total_span * 0.5 - frame_w * 0.5)
	tiles_container.add_child(border_s)

	var border_n := MeshInstance3D.new()
	border_n.mesh = h_mesh
	border_n.material_override = border_mat
	border_n.position = Vector3(0.0, -frame_h * 0.5, total_span * 0.5 + frame_w * 0.5)
	tiles_container.add_child(border_n)

	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(frame_w, frame_h, total_span)

	var border_w := MeshInstance3D.new()
	border_w.mesh = v_mesh
	border_w.material_override = border_mat
	border_w.position = Vector3(-total_span * 0.5 - frame_w * 0.5, -frame_h * 0.5, 0.0)
	tiles_container.add_child(border_w)

	var border_e := MeshInstance3D.new()
	border_e.mesh = v_mesh
	border_e.material_override = border_mat
	border_e.position = Vector3(total_span * 0.5 + frame_w * 0.5, -frame_h * 0.5, 0.0)
	tiles_container.add_child(border_e)

	# Base plate
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(total_span + frame_w * 2.0, 0.28, total_span + frame_w * 2.0)
	var base_plate := MeshInstance3D.new()
	base_plate.mesh = base_mesh
	base_plate.material_override = border_mat
	base_plate.position = Vector3(0.0, -0.24, 0.0)
	tiles_container.add_child(base_plate)

func place_snakes_and_ladders() -> void:
	objects_container = Node3D.new()
	objects_container.name = "ObjectsContainer"
	add_child(objects_container)

	var ladder_prefab := preload("res://models/LadderModel.tscn")
	var snake_prefab := preload("res://models/SnakeModel.tscn")

	for start_cell in SnLScript.connections.keys():
		var end_cell: int = SnLScript.connections[start_cell]
		var start_pos: Vector3 = cells[start_cell]
		var end_pos: Vector3 = cells[end_cell]
		var is_ladder: bool = start_cell < end_cell

		if is_ladder:
			var ladder = ladder_prefab.instantiate()
			objects_container.add_child(ladder)
			if ladder.has_method("setup"):
				ladder.setup(start_pos, end_pos)
		else:
			var snake = snake_prefab.instantiate()
			objects_container.add_child(snake)
			if snake.has_method("setup"):
				snake.setup(start_pos, end_pos)
