class_name StaminaController
extends RefCounted

signal update_stamina

var max_stamina: float
var stamina_recovery_timer := 0.0
var stamina_recovery_delay := 0.0
	
var stamina: float = 0.0:
	get:
		return stamina
	set(value):
		stamina = clamp(value, 0, max_stamina)
		update_stamina.emit()
		
		

func _init(_max_stamina: float, _stamina_recovery_delay: float):
	max_stamina = _max_stamina
	stamina_recovery_delay = _stamina_recovery_delay
	
func consume_stamina(amount: float):
	stamina -= amount
	stamina_recovery_timer = stamina_recovery_delay
