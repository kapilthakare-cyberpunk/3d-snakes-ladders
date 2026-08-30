class_name Board
extends Node3D

const BOARD_SIZE := 10
const CELL_SIZE := 2.0
const BOARD_ORIGIN := Vector3(-9.0, 0.0, -9.0) # Center of cell 1 at bottom-left

const SnLScript = preload("res://singleton/SnLData.gd")

var cells: Array[Vector3] = [] # 1-based world positions (index 0 unused)
var tiles_container: Node3D
var objects_container: Node3D

func _ready() -> void:
	generate_cells()
	create_visual_board()
	place_snakes_and_ladders()

func generate_cells() -> void:
	cells.resize(BOARD_SIZE * BOARD_SIZE + 1)
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var idx := y * BOARD_SIZE + x + 1
			# Boustrophedon winding: row 0 goes left->right, row 1 goes right->left, etc.
			var grid_x := x if (y % 2 == 0) else (BOARD_SIZE - 1 - x)
			cells[idx] = BOARD_ORIGIN + Vector3(grid_x * CELL_SIZE, 0.0, y * CELL_SIZE)

func get_cell_position(idx: int, player_index: int = 0, total_players_on_cell: int = 1) -> Vector3:
	if idx < 1 or idx >= cells.size():
		return Vector3.ZERO
	
	var base_pos := cells[idx]
	if total_players_on_cell <= 1:
		return base_pos
	
	# Side-by-side offset when multiple tokens share a tile
	var offset_x: float = -0.4 if player_index == 0 else 0.4
	return base_pos + Vector3(offset_x, 0.0, 0.0)

func create_visual_board() -> void:
	tiles_container = Node3D.new()
	tiles_container.name = "TilesContainer"
	add_child(tiles_container)
	
	# Materials for tiles
	var mat_light := StandardMaterial3D.new()
	mat_light.albedo_color = Color(0.92, 0.90, 0.86, 1.0) # Warm Ivory
	mat_light.roughness = 0.4
	
	var mat_dark := StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.24, 0.28, 0.36, 1.0) # Slate Navy
	mat_dark.roughness = 0.4
	
	var mat_start := StandardMaterial3D.new()
	mat_start.albedo_color = Color(0.18, 0.72, 0.45, 1.0) # Emerald Start
	mat_start.roughness = 0.3
	mat_start.emission_enabled = true
	mat_start.emission = Color(0.18, 0.72, 0.45, 1.0)
	mat_start.emission_energy_multiplier = 0.3
	
	var mat_win := StandardMaterial3D.new()
	mat_win.albedo_color = Color(0.98, 0.75, 0.15, 1.0) # Golden Finish
	mat_win.roughness = 0.2
	mat_win.metallic = 0.3
	mat_win.emission_enabled = true
	mat_win.emission = Color(0.98, 0.75, 0.15, 1.0)
	mat_win.emission_energy_multiplier = 0.4
	
	var mat_ladder_base := StandardMaterial3D.new()
	mat_ladder_base.albedo_color = Color(0.35, 0.65, 0.95, 1.0) # Sky Blue ladder marker
	mat_ladder_base.roughness = 0.3
	
	var mat_snake_head := StandardMaterial3D.new()
	mat_snake_head.albedo_color = Color(0.88, 0.28, 0.25, 1.0) # Crimson snake head marker
	mat_snake_head.roughness = 0.3
	
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(CELL_SIZE - 0.08, 0.15, CELL_SIZE - 0.08)
	
	for idx in range(1, BOARD_SIZE * BOARD_SIZE + 1):
		var pos: Vector3 = cells[idx]
		var tile := MeshInstance3D.new()
		tile.mesh = tile_mesh
		tile.position = pos + Vector3(0.0, -0.075, 0.0)
		
		# Select appropriate material
		if idx == 1:
			tile.material_override = mat_start
		elif idx == 100:
			tile.material_override = mat_win
		elif SnLScript.is_ladder_base(idx):
			tile.material_override = mat_ladder_base
		elif SnLScript.is_snake_head(idx):
			tile.material_override = mat_snake_head
		elif (idx % 2 == 0):
			tile.material_override = mat_light
		else:
			tile.material_override = mat_dark
		
		tiles_container.add_child(tile)
		
		# Add 3D cell number label
		var label := Label3D.new()
		label.text = str(idx)
		if idx == 1:
			label.text = "1\nSTART"
		elif idx == 100:
			label.text = "100\n🏆 WIN"
		
		label.font_size = 32
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		label.outline_render_priority = 1
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		label.outline_size = 6
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = pos + Vector3(0.0, 0.01, 0.0)
		label.rotation_degrees = Vector3(-90.0, 0.0, 0.0) # Lay flat on tile facing up
		tiles_container.add_child(label)
	
	# Board perimeter frame
	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.12, 0.14, 0.18, 1.0) # Dark Ebony Wood frame
	border_mat.roughness = 0.5
	
	var total_span := float(BOARD_SIZE) * CELL_SIZE
	var frame_thickness := 0.6
	var frame_height := 0.25
	
	# Bottom & Top border beams
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(total_span + frame_thickness * 2.0, frame_height, frame_thickness)
	
	var border_s := MeshInstance3D.new()
	border_s.mesh = h_mesh
	border_s.material_override = border_mat
	border_s.position = Vector3(0.0, -frame_height * 0.5, -total_span * 0.5 - frame_thickness * 0.5)
	tiles_container.add_child(border_s)
	
	var border_n := MeshInstance3D.new()
	border_n.mesh = h_mesh
	border_n.material_override = border_mat
	border_n.position = Vector3(0.0, -frame_height * 0.5, total_span * 0.5 + frame_thickness * 0.5)
	tiles_container.add_child(border_n)
	
	# Left & Right border beams
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(frame_thickness, frame_height, total_span)
	
	var border_w := MeshInstance3D.new()
	border_w.mesh = v_mesh
	border_w.material_override = border_mat
	border_w.position = Vector3(-total_span * 0.5 - frame_thickness * 0.5, -frame_height * 0.5, 0.0)
	tiles_container.add_child(border_w)
	
	var border_e := MeshInstance3D.new()
	border_e.mesh = v_mesh
	border_e.material_override = border_mat
	border_e.position = Vector3(total_span * 0.5 + frame_thickness * 0.5, -frame_height * 0.5, 0.0)
	tiles_container.add_child(border_e)
	
	# Under-board base plate
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(total_span + frame_thickness * 2.0, 0.2, total_span + frame_thickness * 2.0)
	var base_plate := MeshInstance3D.new()
	base_plate.mesh = base_mesh
	base_plate.material_override = border_mat
	base_plate.position = Vector3(0.0, -0.2, 0.0)
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
