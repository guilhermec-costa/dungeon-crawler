# AudioManager
extends Node

class AudioPlayerConfig:
	var volume_db: float
	var pitch: float
	
	func  _init(_volume: float, _pitch: float) -> void:
		self.volume_db = _volume
		self.pitch = _pitch
	
var DEFAULT_AUDIO_PLAYER_CONFIG = AudioPlayerConfig.new(1.0, 1.0)

func play_sfx(stream: AudioStream, config: AudioPlayerConfig = DEFAULT_AUDIO_PLAYER_CONFIG) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.volume_db = config.volume_db
	player.pitch_scale = config.pitch
	player.stream = stream
	add_child(player)
	
	player.play()
	player.finished.connect(player.queue_free)
	return player
