@class_name Board
extends Node3D

const BOARD_SIZE := 10
const CELL_SIZE := 2.0
const BOARD_ORIGIN := Vector3(-9.0, 0.0, -9.0)   # bottom-left corner

var cells: Array[Vector3] = []   # world positions, 1-based (index 0 unused)

func _ready() -> void:
    generate_cells()
    place_snakes_and_ladders()
    # optional: generate a baked lightmap after placing objects

func generate_cells() -> void:
    cells.resize(BOARD_SIZE * BOARD_SIZE + 1)    # index 0 unused
    for y in BOARD_SIZE:
        for x in BOARD_SIZE:
            var idx := y * BOARD_SIZE + x + 1
            # Boustrophedon winding: reverse direction on odd rows.
            var grid_x := x if (y % 2 == 0) else (BOARD_SIZE - 1 - x)
            cells[idx] = BOARD_ORIGIN + Vector3(grid_x * CELL_SIZE, 0.0, y * CELL_SIZE)

func get_cell_position(idx: int) -> Vector3:
    if idx >= 1 and idx < cells.size():
        return cells[idx]
    return Vector3.ZERO

func place_snakes_and_ladders() -> void:
    # Spawn a visual model at every snake/ladder start cell, aimed at its end cell.
    # `connections` is a start_cell -> end_cell dict (start > end = snake, start < end = ladder).
    for start_cell in SnLData.connections.keys():
        var end_cell := SnLData.connections[start_cell]
        var start_pos := get_cell_position(start_cell)
        var end_pos := get_cell_position(end_cell)
        var is_ladder := start_cell < end_cell
        var prefab := preload("res://models/LadderModel.tscn") if is_ladder else preload("res://models/SnakeModel.tscn")
        var instance := prefab.instantiate()
        instance.global_position = start_pos
        instance.look_at(end_pos, Vector3.UP)     # orient start -> end
        add_child(instance)
