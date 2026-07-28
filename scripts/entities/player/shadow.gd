extends Node2D

func _ready() -> void:
	self.z_index = -1
	
func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.95, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.15
	var position = Vector2(2, 25)
	draw_circle(position, 10, shadow_color)

func _physics_process(delta: float) -> void:
	global_position = get_parent().global_position
