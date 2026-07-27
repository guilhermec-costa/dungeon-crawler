extends CanvasLayer

class_name GameMenu

@onready var game_name: Label = $GameName
@onready var play_button_label: Label = $PlayButton/Label
@onready var small_particles : GPUParticles2D = $Particles/MapParticlesBig
@onready var big_particles : GPUParticles2D = $Particles/MapParticlesBig
@onready var music: AudioStreamPlayer2D = $Music


signal start_game
signal quit_game

func _ready() -> void:
	play_button_label.add_theme_font_size_override("font_size", 22)
	play_button_label.add_theme_color_override("font_color", Color("#F3E6B3"))
	play_button_label.add_theme_color_override("font_hover_color", Color("#FFF3C4"))
	play_button_label.add_theme_color_override("font_pressed_color", Color("#D9C178"))
	
	play_button_label.add_theme_constant_override("outline_size", 2)
	play_button_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	play_button_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	


func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	start_game.emit()

func _on_quit_button_pressed() -> void:
	quit_game.emit()

func show_menu():
	show()
	small_particles.emitting = true
	big_particles.emitting = true

func hide_menu():
	hide()
	music.stop()
	small_particles.emitting = false
	big_particles.emitting = false
	
