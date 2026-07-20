extends Node

const phase1Scene = preload("res://scenes/phases/phase_1.tscn")
const phase2Scene = preload("res://scenes/phases/phase_2.tscn")

@onready var game_menu: GameMenu = $GameMenu
@onready var pause_menu = $PauseMenu
@onready var resume_button: Button = $PauseMenu/ResumeButton

var current_phase: Node
	
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	game_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_menu.hide()
	
func _on_resume_button_pressed():
	pause_menu.hide()
	current_phase.get_tree().paused = false
	
func _on_player_died():
	get_tree().call_deferred("reload_current_scene")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		var tree = current_phase.get_tree()
		tree.paused = !tree.paused
		if tree.paused:
			pause_menu.show()
		else:
			pause_menu.hide()
		
func start_game():
	var phase1: Phase1 = phase1Scene.instantiate()
	current_phase = phase1
	current_phase.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(phase1)
	var player: Player = phase1.player
	player.player_dead.connect(_on_player_died)
	phase1.start()


func _on_game_menu_start_game() -> void:
	game_menu.hide()
	start_game()

func _on_game_quit() -> void:
	get_tree().quit()
