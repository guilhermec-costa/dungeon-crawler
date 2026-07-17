# AudioManager
extends Node


func play_sfx(stream: AudioStream) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	add_child(player)
	
	player.play()
	player.finished.connect(player.queue_free)
	return player
