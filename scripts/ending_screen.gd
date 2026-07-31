extends CanvasLayer

class_name EndingScreen

signal return_to_title

@onready var return_button: TextureButton = $ReturnButton
@onready var knight: Sprite2D = $Knight

var knight_rest_y := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	knight_rest_y = knight.position.y
	return_button.pressed.connect(_on_return_button_pressed)
	return_button.mouse_entered.connect(_set_button_emphasis.bind(true))
	return_button.mouse_exited.connect(_set_button_emphasis.bind(false))
	return_button.focus_entered.connect(_set_button_emphasis.bind(true))
	return_button.focus_exited.connect(_set_button_emphasis.bind(false))
	hide()


func _process(_delta: float) -> void:
	if visible:
		knight.position.y = knight_rest_y + sin(Time.get_ticks_msec() * 0.0011) * 3.0


func show_ending() -> void:
	show()
	return_button.grab_focus()


func hide_ending() -> void:
	hide()


func _set_button_emphasis(emphasized: bool) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		return_button,
		"scale",
		Vector2(1.035, 1.035) if emphasized else Vector2.ONE,
		0.12
	)


func _on_return_button_pressed() -> void:
	return_to_title.emit()
