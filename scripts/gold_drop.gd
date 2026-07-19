class_name GoldDrop

extends Node2D

@export var item: ItemData
var gold_amount: float = 0.0

func _on_collect_range_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect_gold(item, gold_amount)
		AudioManager.play_sfx($CollectSound.stream)
		queue_free()
