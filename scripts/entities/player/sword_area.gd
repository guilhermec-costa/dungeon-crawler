class_name SwordArea

extends Area2D

@export var config: WeaponData
@export var attack2_damage: float = 20
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var collider: CollisionShape2D = $CollisionShape2D
@export var SWORD_COLLIDER_OFFSET = 35
var last_damage_time: float

func _ready():
	last_damage_time = Time.get_unix_time_from_system()
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
		
		var current_time = Time.get_unix_time_from_system()
		var time_passed = current_time - last_damage_time
		last_damage_time = current_time
		body.take_damage(damage, damage_type)
		
func set_facing_right():
	collider.position.x += SWORD_COLLIDER_OFFSET
	
func set_facing_left():
	collider.position.x -= SWORD_COLLIDER_OFFSET

func set_disabled(enabled: bool):
	collider.call_deferred("set_disabled", enabled)

func is_disabled() -> bool:
	return collider.disabled
