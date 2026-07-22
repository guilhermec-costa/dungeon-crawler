class_name SecretRoom
extends Node2D

@onready var return_area: Area2D = $ReturnArea
@onready var player_start_position: Marker2D = $PlayerStartPosition

func _ready() -> void:
	return_area.body_entered.connect(_on_return_area_body_entered)
	

func _on_return_area_body_entered(body: Node2D) -> void:
	if body is Player:
		body.enter_room(body.last_leaved_room, body.position_on_last_room)
