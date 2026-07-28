class_name AttackConfig
extends RefCounted

var animation_name: String
var stamina_cost: float
var attack_frame: int
var attack_interval_min: float
var attack_interval_max: float

func  _init(
	_animation_name: String, 
	_stamina_cost: float,
	_attack_frame: int,
	_attack_interval_min = 0.3,
	_attack_interval_max = 0.5
) -> void:
	self.animation_name = _animation_name
	self.stamina_cost = _stamina_cost
	self.attack_frame = _attack_frame
	self.attack_interval_min = _attack_interval_min
	self.attack_interval_max = _attack_interval_max
