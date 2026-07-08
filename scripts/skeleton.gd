extends CharacterBody2D

class_name BaseSkeleton

@export var speed: float = 45.0
@export var max_health: float;
var health: float
var SWORD_COLLIDER_OFFSET = 50.0

# STATE DATA
var player: Player
var is_dead: bool = false
var player_on_range: bool = false

enum State {
	WALKING,
	ATTACKING
}

var state: State = State.WALKING
@export var damage_given: float;
@onready var health_bar: HealthBar = $HealthBar
@onready var pathfinder: NavigationAgent2D = $NavigationAgent2D
var damageTakenLabel: PackedScene = preload("res://scenes/damage_label.tscn")

	
func _ready():
	add_to_group("skeletons")
	health = max_health
	
	health_bar.max_value = max_health
	health_bar.set_health_bar_value(max_health)
	
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.animation = "walk"
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true
	$AttackTimer.timeout.connect(_on_attack_timer_timeout)
	$AttackTimer.wait_time = 0.8

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 50, 10, shadow_color)

func _physics_process(delta: float) -> void:
	if player:
		var player_pos = self.player.global_position
		pathfinder.target_position = Vector2(player_pos.x, player_pos.y + 10)
		var dir = to_local(pathfinder.get_next_path_position()).normalized()
		if player_on_range:
			velocity = Vector2.ZERO
		else:
			velocity = dir * speed
		move_and_slide()
		

func _process(delta: float) -> void:
	if is_dead: 
		return
	
	var pos_diff = player.position.x - position.x
	if abs(pos_diff) > 5:
		if pos_diff < 0:
			if not $AnimatedSprite2D.flip_h: 
				$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
				$SwordArea/CollisionShape2D.rotation *= -1
			$AnimatedSprite2D.flip_h = true
		else:
			if $AnimatedSprite2D.flip_h:
				$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
				$SwordArea/CollisionShape2D.rotation *= -1
			$AnimatedSprite2D.flip_h = false
			
	
	if state == State.ATTACKING:
		$AnimatedSprite2D.animation = "attack"
	elif state == State.WALKING:
		$AnimatedSprite2D.animation = "walk"
		
	$AnimatedSprite2D.play()

func die():
	$HealthBar.hide_health_ui()
	is_dead = true
	$DieSound.play()
	$AnimatedSprite2D.play("die")
	
	await $AnimatedSprite2D.animation_finished
	
	queue_free()

func show_damage_label(damage: float):
	var damageLabel: DamageLabel = damageTakenLabel.instantiate()
	add_child(damageLabel)
	damageLabel.position = Vector2(0, -20)
	damageLabel.texture_filter = 1
	damageLabel.modulate = Color.YELLOW
	damageLabel.add_theme_font_size_override("font_size", 10)
	damageLabel.show_damage_label(damage, 0.7)
	
func take_damage(damage: float) -> void:
	health -= damage	
	if health <= 0:
		die()
		return
	
	$HealthBar.set_health_bar_value(health)
	show_damage_label(damage)
	
	$AnimatedSprite2D.play("take_damage")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.play("walk")

	
func on_attack_range_body_entered(body: Node2D) -> void:
	if body is Player:
		player_on_range = true
		state = State.ATTACKING
		$SwordArea/CollisionShape2D.disabled = false
		$AttackTimer.start()

func _on_attack_timer_timeout():
	player.take_damage(damage_given)
	
	
func _on_attack_range_body_exited(body):
	if body is Player:
		player_on_range = false
		state = State.WALKING
		$SwordArea/CollisionShape2D.disabled = true
		$AttackTimer.stop()
