extends CanvasLayer

class_name GameMenu

@onready var play_button: TextureButton = $PlayButton
@onready var exit_button: TextureButton = $ExitButton
@onready var play_button_label: Label = $PlayButton/Label
@onready var exit_button_label: Label = $ExitButton/Label
@onready var language_button: TextureButton = $LanguageButton
@onready var language_button_label: Label = $LanguageButton/Label
@onready var knight: Sprite2D = $Knight
@onready var small_particles: GPUParticles2D = $Particles/MapParticlesSmall
@onready var big_particles: GPUParticles2D = $Particles/MapParticlesBig
@onready var music: AudioStreamPlayer2D = $Music

var knight_rest_y := 0.0

signal start_game
signal quit_game

func _ready() -> void:
	knight_rest_y = knight.position.y
	play_button.grab_focus()
	_configure_button(play_button, play_button_label)
	_configure_button(exit_button, exit_button_label)
	_configure_button(language_button, language_button_label)
	LocalizationManager.locale_changed.connect(_update_language_button)
	_update_language_button()

func _process(_delta: float) -> void:
	knight.position.y = knight_rest_y + sin(Time.get_ticks_msec() * 0.0012) * 4.0

func _configure_button(button: TextureButton, label: Label) -> void:
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_set_button_emphasis.bind(button, label, true))
	button.mouse_exited.connect(_set_button_emphasis.bind(button, label, false))
	button.focus_entered.connect(_set_button_emphasis.bind(button, label, true))
	button.focus_exited.connect(_set_button_emphasis.bind(button, label, false))

func _set_button_emphasis(button: TextureButton, label: Label, emphasized: bool) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.035, 1.035) if emphasized else Vector2.ONE, 0.12)
	label.modulate = Color(1.08, 0.92, 0.7, 1.0) if emphasized else Color.WHITE

func _on_play_button_pressed() -> void:
	start_game.emit()

func _on_quit_button_pressed() -> void:
	quit_game.emit()


func _on_language_button_pressed() -> void:
	LocalizationManager.toggle_locale()


func _update_language_button() -> void:
	language_button_label.text = "%s: %s" % [tr("LANGUAGE"), LocalizationManager.get_language_name()]

func show_menu() -> void:
	show()
	if not music.playing:
		music.play()
	small_particles.emitting = true
	big_particles.emitting = true

func hide_menu() -> void:
	hide()
	music.stop()
	small_particles.emitting = false
	big_particles.emitting = false
