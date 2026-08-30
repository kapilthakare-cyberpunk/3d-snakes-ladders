extends Node

# NOTE: GameController is an AutoLoad (autoload) singleton, which Godot compiles
# during the filesystem scan — BEFORE @class_name globals (Player, DiceRoll) are
# fully registered. Referencing those classes as compile-time TYPES (e.g.
# `Array[Player]`, `as Player`, `DiceRoll.new()` with type inference) fails with
# "Could not find type / not declared in the current scope". The robust fix is to
# keep storage untyped (dynamic dispatch) and resolve the dice class at RUNTIME
# via `load()`, which happens after the scan completes.

signal dice_rolled(player_id: int, steps: int)

var players: Array = []          # Player token nodes (add to group "players")
var current_player_index: int = 0
var dice = null                  # DiceRoll instance, created at runtime in _ready

func _ready() -> void:
    dice = load("res://src/DiceRoll.gd").new()
    for node in get_tree().get_nodes_in_group("players"):
        if node.has_method("move_steps"):
            players.append(node)
            node.connect("move_finished", Callable(self, "_on_player_moved"))

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("roll_dice"):
        if players.size() > 0 and not _current_player_is_moving():
            _roll_for_current_player()

func _current_player_is_moving() -> bool:
    return players[current_player_index].is_moving if players.size() else false

func _roll_for_current_player() -> void:
    var steps: int = dice.roll()
    var player = players[current_player_index]
    dice_rolled.emit(player.player_id, steps)
    player.move_steps(steps)

func _on_player_moved(player_id: int, final_cell: int) -> void:
    if final_cell >= 100:
        print("Player %d wins!" % player_id)
        get_tree().quit()   # or open a Game Over screen
        return
    current_player_index = (current_player_index + 1) % players.size()
