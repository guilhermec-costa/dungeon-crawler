extends ProgressBar
	
class_name HealthBar

func set_health_bar_value(_value: float) -> void:
	self.value = _value

func hide_health_ui():
	hide()
