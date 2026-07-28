class_name BaseDrop
extends Node2D

@export var item: ItemData
var amount: float = 0.0

func _on_collect_range_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect_item(item, amount)
		queue_free()
