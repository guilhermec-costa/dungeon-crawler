extends CanvasLayer

@onready var transition_rect: ColorRect = $TransitionRect

func _ready() -> void:
	transition_rect.visible = false
	
func fade_out(duration: float = 0.2) -> void:
	transition_rect.visible = true
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, duration)
	await tween.finished
	transition_rect.visible = false
