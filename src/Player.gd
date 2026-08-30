@class_name Player
extends Node3D

@export var player_id: int = 1
var current_cell: int = 1
var is_moving: bool = false

signal move_finished(player_id: int, final_cell: int)

func move_steps(steps: int) -> void:
    if is_moving or steps <= 0:
        return
    is_moving = true

    # Build the exact path the token will follow, including a bounce-back
    # if it overshoots cell 100 (overshoot bounces downward from 100).
    var raw_target := current_cell + steps
    var path: Array[int] = []
    if raw_target <= 100:
        for i in range(current_cell + 1, raw_target + 1):
            path.append(i)
    else:
        # Bounce-back rule: overshoot the goal and bounce downward.
        for i in range(current_cell + 1, 101):
            path.append(i)
        var bounced := 100 - (raw_target - 100)
        bounced = max(bounced, 1)          # guard against absurd overshoot -> cell 0
        for i in range(99, bounced - 1, -1):
            path.append(i)

    var board := get_node("/root/Board") as Board

    # Node.create_tween() auto-plays on the next frame and is auto-killed
    # when this node is freed, so there is no ownership/GC bookkeeping.
    var tween := self.create_tween()
    tween.set_parallel(false)              # make each step run one after another

    for cell in path:
        tween.tween_property(self, "global_position", board.get_cell_position(cell), 0.12) \
            .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    var final_cell := path[-1]

    # Resolve a snake or ladder on the landing cell.
    if SnLData.connections.has(final_cell):
        var after := SnLData.connections[final_cell]
        tween.tween_property(self, "global_position", board.get_cell_position(after), 0.30) \
            .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        final_cell = after

    tween.finished.connect(_on_move_finished.bind(final_cell))

func _on_move_finished(final_cell: int) -> void:
    current_cell = final_cell
    is_moving = false
    move_finished.emit(player_id, final_cell)
