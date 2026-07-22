# TweenManager
extends Node

func animate_floating_label(label: MessageLabel) -> void:
	var config := label.config
	label.modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(
		label,
		"position:y",
		label.position.y - config.move_distance,
		config.duration
	)

	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		config.duration
	)

	await tween.finished
	label.queue_free()
