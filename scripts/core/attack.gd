class_name AttackConfig
extends RefCounted

var animation_name: String
var stamina_cost: float
var damage: float
var attack_hit_frame: int
var attack_end_frame: int
var attack_interval_min: float
var attack_interval_max: float
var audio_stream: AudioStream
var audio_volume_db: float = 1.0
var audio_pitch: float = 1.0

func  _init(
	_animation_name: String, 
	_damage: float,
	_stamina_cost: float,
	_attack_hit_frame: int,
	_attack_end_frame: int,
	_attack_interval_min = 0.3,
	_attack_interval_max = 0.5,
) -> void:
	self.animation_name = _animation_name
	self.damage = _damage
	self.stamina_cost = _stamina_cost
	self.attack_hit_frame = _attack_hit_frame
	self.attack_end_frame = _attack_end_frame
	self.attack_interval_min = _attack_interval_min
	self.attack_interval_max = _attack_interval_max

func set_audio_config(stream: AudioStream, volume_db: float, pitch: float):
	audio_stream = stream
	audio_volume_db = volume_db
	audio_pitch = pitch
	return self
