class_name DashBehavior
extends RefCounted

var chance: float
var force: float
var duration: float
var cooldown: float

var duration_timer := 0.0
var cooldown_timer := 0.0
var dash_velocity := Vector2.ZERO

func _init(chance: float, force: float, duration: float, cooldown: float):
	self.chance = chance
	self.force = force
	self.duration = duration
	self.cooldown = cooldown
	
func process(delta: float) -> bool:
	if duration_timer > 0:
		duration_timer -= delta
		return true

	if cooldown_timer > 0:
		cooldown_timer -= delta

	return false

func can_dash() -> bool:
	return cooldown_timer <= 0

func try_dash(origin: Vector2, target: Vector2):
	cooldown_timer = cooldown

	if randf() > chance:
		return

	duration_timer = duration
	dash_velocity = origin.direction_to(target) * force
