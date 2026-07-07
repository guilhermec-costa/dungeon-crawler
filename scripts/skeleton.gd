extends CharacterBody2D

class_name Skeleton

# PHISICS DATA
const SPEED = 45.0
var SWORD_COLLIDER_OFFSET = 50.0

# HEALTH DATA
const MAX_HEALTH = 10
var health = MAX_HEALTH

# STATE DATA
var player: Player
var is_dead: bool = false
var player_on_range: bool = false

enum State {
	WALKING,
	ATTACKING
}

var state: State = State.WALKING

@onready var health_bar: HealthBar = $HealthBar
	
func _ready():
	add_to_group("skeletons")
	health_bar.max_value = MAX_HEALTH
	health_bar.set_health_bar_value(MAX_HEALTH)
	$CollisionShape2D.disabled = false
	$AnimatedSprite2D.animation = "walk"
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true
	$AttackTimer.timeout.connect(_on_attack_timer_timeout)

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 50, 10, shadow_color)

func _physics_process(delta: float) -> void:
	if player:
		var dir = (self.player.center - global_position).normalized()
		if player_on_range:
			velocity = Vector2.ZERO
		else:
			velocity = dir * SPEED
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
	
func take_damage(damage: float) -> void:
	health -= damage	
	if health <= 0:
		die()
		return
	
	$HealthBar.set_health_bar_value(health)
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
	player.take_damage(15)
	
func _on_attack_range_body_exited(body):
	if body is Player:
		player_on_range = false
		state = State.WALKING
		$SwordArea/CollisionShape2D.disabled = true
		$AttackTimer.stop()
