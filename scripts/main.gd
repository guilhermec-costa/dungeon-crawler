extends Node

const phase1Scene = preload("res://scenes/phases/phase_1.tscn")
const phase2Scene = preload("res://scenes/phases/phase_2.tscn")

func _ready() -> void:
	var phase1 = phase1Scene.instantiate()
	add_child(phase1)
