class_name PlayerAnimatedSprite
extends AnimatedSprite2D

var sword_area: SwordArea

func setup(_sword_area: SwordArea):
	sword_area = _sword_area

func is_facing_left():
	return flip_h
	
func is_facing_right():
	return not flip_h
	
func update_flip(direction: Vector2) -> void:
	if direction.x > 0:
		if is_facing_left():
			sword_area.set_facing_right()
		flip_h = false
	elif direction.x < 0:
		if is_facing_right():
			sword_area.set_facing_left()
		flip_h = true
			
func update_animation(new_animation: String) -> void:
	if animation != new_animation:
		play(new_animation)
