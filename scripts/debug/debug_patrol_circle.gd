class_name DebugPatrolCircle
extends Node2D

@export var radius := 0.0

func _draw() -> void:
	var color = Color.YELLOW
	color.a = 0.3
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color)
