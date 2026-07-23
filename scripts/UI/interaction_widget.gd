class_name InteractionWidget
extends Node2D

@onready var label := $Panel/Label

#TRANS interpolation curve (how values evolve).
#EASE where accelerate vs decelerate
func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "position:y", position.y - 3, 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.7, 1.0)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.05, 1.0)

	tween.tween_property(self, "position:y", position.y, 1.0)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 1.0)
