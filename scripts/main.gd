extends Node

const phase1Scene = preload("res://scenes/phases/phase_1.tscn")
const phase2Scene = preload("res://scenes/phases/phase_2.tscn")

func _ready():
	var phase1: Phase1 = phase1Scene.instantiate()
	add_child(phase1)
	var player: Player = phase1.get_node("Entities/Player")
	player.player_dead.connect(_on_player_died)
	phase1.start()
	
func _on_player_died():
	get_tree().call_deferred("reload_current_scene")
