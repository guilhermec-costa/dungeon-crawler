class_name PlayerAnimatedSprite
extends AnimatedSprite2D

const PLAYER_ATTACK_VERTICAL_OFFSET = 3

var sword_area: SwordArea
var movement_direction := Vector2.RIGHT

func setup(_sword_area: SwordArea):
	sword_area = _sword_area
	animation_changed.connect(_on_animation_changed)
	animation_finished.connect(_on_animation_finished)

func is_facing_left():
	return flip_h
	
func is_facing_right():
	return not flip_h
	
func update_flip(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		movement_direction = direction

	if direction.x > 0:
		if is_facing_left():
			sword_area.set_facing_right()
		flip_h = false
	elif direction.x < 0:
		if is_facing_right():
			sword_area.set_facing_left()
		flip_h = true
			
func update_animation(new_animation: String) -> void:
	var target_animation := get_directional_animation(new_animation)
	if animation != target_animation:
		play(target_animation)

func get_directional_animation(base_animation: String) -> String:
	if base_animation != "run" and base_animation != "walk":
		return base_animation

	if abs(movement_direction.y) > abs(movement_direction.x):
		var vertical_direction := "down" if movement_direction.y > 0 else "up"
		return "%s_%s" % [base_animation, vertical_direction]

	return base_animation

func _on_animation_changed():
	offset.y = 0
	if animation == "attack1" or animation == "attack2":
		offset.y += PLAYER_ATTACK_VERTICAL_OFFSET

func _on_animation_finished():
	if animation == "attack1" or animation == "attack2":
		offset.y -= PLAYER_ATTACK_VERTICAL_OFFSET
