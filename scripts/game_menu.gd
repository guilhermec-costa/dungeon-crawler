extends CanvasLayer

class_name GameMenu

@onready var play_button: Button = $PlayButton
@onready var exit_button: Button = $PlayButton

signal start_game

var font: Font = preload("res://assets/fonts/Tiny RPG - Necro Romance.ttf")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button.add_theme_font_override("font", font)
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color("#F3E6B3"))          # dourado claro
	play_button.add_theme_color_override("font_hover_color", Color("#FFF3C4"))    # mais brilhante
	play_button.add_theme_color_override("font_pressed_color", Color("#D9C178"))
	
	play_button.add_theme_constant_override("outline_size", 2)
	play_button.add_theme_color_override("font_outline_color", Color.BLACK)
	
	play_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	play_button.text = "Start Game"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	start_game.emit()
