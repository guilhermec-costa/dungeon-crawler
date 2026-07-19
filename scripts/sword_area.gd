class_name SwordArea

extends Area2D

@export var config: WeaponData
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is BaseEnemy:
		var damage = config.base_damage
		var damage_type = DamageTypes.Type.NORMAL
		if randf() < config.critical_chance:
			damage *= config.critical_multiplier
			damage_type = DamageTypes.Type.CRITICAL
		
		if not hit_sound.playing:
			hit_sound.play()
		body.take_damage(damage, damage_type)
		
