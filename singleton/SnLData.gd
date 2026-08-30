extends Node

## SnLData - Snakes and Ladders board layout data & helpers (AutoLoad)

# start_cell -> end_cell  (start > end = snake, start < end = ladder)
var connections: Dictionary = {
	16: 6,
	48: 30,
	62: 19,
	64: 60,
	71: 91,
	79: 99,
	93: 73,
	95: 75,
	97: 78,
	98: 84,
}

# Inverted dictionary: end_cell -> Array of start_cells
var reverse_connections: Dictionary = {}

func _ready() -> void:
	for start_cell in connections.keys():
		var end_cell: int = connections[start_cell]
		if not reverse_connections.has(end_cell):
			reverse_connections[end_cell] = []
		reverse_connections[end_cell].append(start_cell)

func get_destination(cell: int) -> int:
	return connections.get(cell, cell)

func is_special_cell(cell: int) -> bool:
	return connections.has(cell)

func is_ladder_base(cell: int) -> bool:
	return connections.has(cell) and connections[cell] > cell

func is_snake_head(cell: int) -> bool:
	return connections.has(cell) and connections[cell] < cell
