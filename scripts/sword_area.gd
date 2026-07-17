class_name SwordArea

extends Area2D

@export var base_damage: float = 5
@export var critical_chance: float # %
@export var critical_multiplier: float
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is BaseEnemy:
		var damage = base_damage
		var damage_type = DamageTypes.Type.NORMAL
		if randf() * 100 < critical_chance:
			damage *= critical_multiplier
			damage_type = DamageTypes.Type.CRITICAL
		
		if not hit_sound.playing:
			hit_sound.play()
		body.take_damage(damage, damage_type)
		
