class_name DiceRoll
extends RefCounted         # stateless roller – lighter than a Node

@export var dice_faces: int = 6

func roll() -> int:
    return randi() % dice_faces + 1      # 1..dice_faces
