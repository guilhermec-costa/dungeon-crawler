class_name SecretPassage
extends Interactable

@export var secret_room: Node2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body is Player:
		body.enter_interectable(self)

func _on_body_exited(body):
	if body is Player:
		body.exit_interactable(self)

func interact(player: Player):
	player.enter_room(secret_room)
