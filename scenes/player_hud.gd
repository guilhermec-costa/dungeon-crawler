class_name PlayerHUD

extends CanvasLayer

@onready var healthbar: TextureProgressBar = $Control/HealthBar
@onready var staminabar: TextureProgressBar = $Control/StaminaBar

@export var player: Player

func _ready() -> void:
	healthbar.min_value = 0
	staminabar.min_value = 0

func update_max_health() -> void:
	self.healthbar.max_value = player.max_health

func update_max_stamina() -> void:
	self.staminabar.max_value = player.max_stamina
	
func update_health():
	self.healthbar.value = player.health
	
func update_stamina():
	self.staminabar.value = player.stamina
