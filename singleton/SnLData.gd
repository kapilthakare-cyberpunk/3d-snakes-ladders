extends Node

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

# Returns the cell a token lands on after a snake/ladder at `cell`.
func get_destination(cell: int) -> int:
    return connections.get(cell, cell)
