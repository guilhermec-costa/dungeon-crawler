# TweenManager
extends Node

func animate_floating_label(label: Label, text: String, duration := 0.5, move_y := 30.0) -> void:
	label.text = text
	label.modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(label, "position:y", label.position.y - move_y, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)

	await tween.finished
	label.queue_free()
