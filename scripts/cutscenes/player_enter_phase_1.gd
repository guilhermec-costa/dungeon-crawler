class_name PlayerEnterPhase1
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play() -> void:
	animation_player.play("player_standup")
	await animation_player.animation_finished
