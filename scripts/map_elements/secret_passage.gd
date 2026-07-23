class_name SecretPassage
extends Interactable

@export var secret_room: SecretRoom

func interact(player: Player):
	player.enter_room(secret_room, secret_room.player_start_position.global_position)
