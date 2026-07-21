class_name StaminaController
extends RefCounted

@export var sprint_stamina_cost_per_second: float = 15.0
@export var stamina_recovery_rate: float = 22.0
@export var stamina_recovery_delay: float = 0.75
var stamina_recovery_timer := 0.0
