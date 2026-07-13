extends BaseEnemy

class_name BaseSkeleton

var SWORD_COLLIDER_OFFSET = 50.0

func _ready():
	attack_hit_frame = 5
	postmortem_scene = preload("res://scenes/decorations/skeleton_postmorten.tscn")
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)
	super._ready()


func on_flip_left() -> void:
	if not $AnimatedSprite2D.flip_h:
		$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
		$SwordArea/CollisionShape2D.rotation *= -1

func on_flip_right() -> void:
	if $AnimatedSprite2D.flip_h:
		$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
		$SwordArea/CollisionShape2D.rotation *= -1

# --- Attack ---

func _on_frame_changed() -> void:
	if state == State.ATTACKING and $AnimatedSprite2D.frame == attack_hit_frame:
		for body in $SwordArea.get_overlapping_bodies():
			if body is Player:
				player.take_damage(damage_given)

func on_enter_attack_range(body: Node2D) -> void:
	if body is Player:
		state = State.ATTACKING
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", false)
		$WalkTimer.stop()

func on_exit_attack_range(body: Node2D) -> void:
	if body is Player:
		if state == State.ATTACKING:
			await $AnimatedSprite2D.animation_finished
		
		if $AttackRange.has_overlapping_bodies():
			state = State.ATTACKING
		else:
			state = State.CHASING
		
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", true)

# --- Death ---

func die() -> void:
	$HealthBar.hide_health_ui()
	is_dead = true
	$DieSound.play()
	$AnimatedSprite2D.play("die")

	await $AnimatedSprite2D.animation_finished

	var corpse = postmortem_scene.instantiate()
	corpse.global_position = global_position
	get_parent().add_child(corpse)
	var despawn_timer = corpse.get_tree().create_timer(10)
	despawn_timer.timeout.connect(corpse.on_despawn_timer_timeout)

	queue_free()
