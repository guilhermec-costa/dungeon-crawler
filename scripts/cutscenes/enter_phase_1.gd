extends Node2D

@onready var player = $Player

func _ready() -> void:
	play()
	
func play() -> void:
	player.set_process_input(false)
	await TransitionManager.fade_out()
	
	await TransitionManager.fade_in(3)
	player.set_process_input(true)
