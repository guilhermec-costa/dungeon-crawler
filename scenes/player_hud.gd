class_name PlayerHUD

extends CanvasLayer

@onready var healthbar: TextureProgressBar = $Control/HealthBar
@export var player: Player

func _ready() -> void:
	healthbar.min_value = 0

func update_max_health() -> void:
	self.healthbar.max_value = player.max_health

func update_health():
	self.healthbar.value = player.health
