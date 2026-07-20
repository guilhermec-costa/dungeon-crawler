extends BaseEnemy

class_name BaseSkeleton

var SWORD_COLLIDER_OFFSET = 50.0

@onready var running_sound: AudioStreamPlayer2D = $RunningSound
@onready var sword_hit_sound: AudioStreamPlayer2D = $SwordHitSound

func process_special_movement(delta):
	if dash_controller.process(delta):
		velocity = dash_controller.dash_velocity
		return

	if state == State.ATTACKING \
	and dash_controller.can_dash() \
	and not $AttackRange.overlaps_body(player) \
	and is_on_hit_frame():
		dash_controller.try_dash(global_position,player.global_position)


func _ready():
	attack_hit_frame = 5
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)
	config.gold_drop_amount_on_death = 10
	super._ready()


func on_flip_left() -> void:
	$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

func on_flip_right() -> void:
	$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

# --- Attack ---

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	
	super._physics_process(delta)
	
func _process(_delta: float) -> void:
	if state == State.DEAD:
		return
			
	var walking := state == State.PATROLLING or state == State.CHASING

	if walking:
		if not $RunningSound.playing:
			$RunningSound.play()
	else:
		if $RunningSound.playing:
			$RunningSound.stop()
	
	super._process(_delta)
	
func _on_frame_changed() -> void:
	if state == State.ATTACKING and is_on_hit_frame():
		for body in $SwordArea.get_overlapping_bodies():
			if body is Player:
				player.take_damage(config.damage_given)
		if not sword_hit_sound.playing:
			sword_hit_sound.play()

func on_enter_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
		
	if body is Player:
		
		state = State.ATTACKING
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", false)
		$WalkTimer.stop()

func on_exit_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
		
	if body is Player:
		if state == State.ATTACKING:
			await $AnimatedSprite2D.animation_finished
		
		if $AttackRange.has_overlapping_bodies():
			state = State.ATTACKING
		else:
			state = State.CHASING
		
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", true)
	
func die() -> void:
	sword_hit_sound.stop()
		
	$HealthBar.hide_health_ui()
	state = State.DEAD
	AudioManager.play_sfx($DieSound.stream)
	$AnimatedSprite2D.play("die")

	await $AnimatedSprite2D.animation_finished
	
	drop_gold()
	queue_free()
