class_name SlamEffect
extends Node2D

@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	sprite.visible = false
	
func play():
	sprite.visible = true
	dust_particles.restart()
	
	sprite.modulate.a = 0.6
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(sprite, "scale", Vector2(0.16, 0.16), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
