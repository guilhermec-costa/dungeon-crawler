class_name PortraitContainer
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_hurt_animation():
	animation_player.play("hurt") 
