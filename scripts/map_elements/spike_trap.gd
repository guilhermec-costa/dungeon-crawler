class_name SpikeTrap
extends Node2D

@export var damage: float = 10
@onready var area2d: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spike_sound: AudioStreamPlayer2D = $SpikeSound

var player_on_range := false
var start_attack_frame := 2
var end_attack_frame := 3
var player_can_take_damage := true
var player: Player

func _ready() -> void:
	area2d.body_entered.connect(_on_body_entered)
	area2d.body_exited.connect(_on_body_exited)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_looped.connect(_on_animation_looped)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_on_range = true
		player = body
		
func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_on_range = false
		player = null
		
func _on_frame_changed() -> void:
	if animated_sprite.frame >= start_attack_frame \
	and animated_sprite.frame <= end_attack_frame:
		spike_sound.play()
		if player_on_range and player_can_take_damage:
			player.take_damage(damage)
			player_can_take_damage = false

func _on_animation_looped():
	player_can_take_damage = true
