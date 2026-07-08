extends Label

class_name DamageLabel
 
func show_damage_label(damage: float, duration: float) -> void:
	text = str(damage)
	modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_parallel()
	
	tween.tween_property(self, "position:y", position.y - 30, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	
	await tween.finished
	queue_free()
