extends CanvasLayer

@onready var commands: Node2D = $Commands

func _ready() -> void:
	await fade_out()
	await fade_in()
	queue_free()
	
func fade_out():
	var tween = create_tween()
	commands.modulate.a = 1
	tween.tween_property(commands, "modulate:a", 1.0, 10)
	await tween.finished
	
func fade_in():
	var tween = create_tween()
	tween.tween_property(commands, "modulate:a", 0.0, 0.5)
	await tween.finished
