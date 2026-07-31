extends Node

const phase1_scene: PackedScene = preload("res://scenes/phases/phase_1.tscn")
const secret_room: PackedScene = preload("res://scenes/secret_room.tscn")

@onready var game_menu: GameMenu = $GameMenu
@onready var pause_menu = $PauseMenu
@onready var resume_button: Button = $PauseMenu/ResumeButton
@onready var opening_story: OpeningStory = $OpeningStory

var current_phase: Node
var is_starting_game := false
	
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	game_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	pause_menu.hide()
	
func _on_resume_button_pressed():
	pause_menu.hide()
	current_phase.get_tree().paused = false
	
func _on_player_died() -> void:
	if current_phase is Phase1 and current_phase.is_boss_battle_active():
		await current_phase.respawn_after_boss_death()
		return

	await restart_phase()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		var tree = current_phase.get_tree()
		tree.paused = !tree.paused
		if tree.paused:
			pause_menu.show()
		else:
			pause_menu.hide()
		
func start_game():
	var phase1 := create_phase()

	await TransitionManager.fade_out()
	game_menu.hide_menu()
	phase1.start()
	await TransitionManager.fade_in(2)


func create_phase() -> Phase1:
	var phase1: Phase1 = phase1_scene.instantiate()
	current_phase = phase1
	current_phase.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(phase1)
	phase1.player.player_dead.connect(_on_player_died)
	return phase1


func restart_phase() -> void:
	await TransitionManager.fade_out(0.35)

	var previous_phase := current_phase
	current_phase = null
	previous_phase.queue_free()
	await previous_phase.tree_exited

	var phase1 := create_phase()
	game_menu.hide_menu()
	phase1.start()
	await TransitionManager.fade_in(0.65)


func _on_game_menu_start_game() -> void:
	if is_starting_game:
		return

	is_starting_game = true
	game_menu.hide_menu()
	await opening_story.play_story()
	await start_game()
	is_starting_game = false

func _on_game_quit() -> void:
	get_tree().quit()
