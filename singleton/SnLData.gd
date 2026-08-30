extends Node

## SnLData - Snakes and Ladders board layout data & helpers (AutoLoad)

const connections: Dictionary = {
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

static func get_destination(cell: int) -> int:
	return connections.get(cell, cell)

static func is_special_cell(cell: int) -> bool:
	return connections.has(cell)

static func is_ladder_base(cell: int) -> bool:
	return connections.has(cell) and connections[cell] > cell

static func is_snake_head(cell: int) -> bool:
	return connections.has(cell) and connections[cell] < cell
