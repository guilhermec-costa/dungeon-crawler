extends BaseEnemy

class_name BaseSkeleton

@export var SWORD_COLLIDER_OFFSET = 50.0

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
	attacks = [
		AttackConfig.new("attack1", 0, 5, 2, 3),
		AttackConfig.new("attack2", 0, 5, 2, 3)
	]
	$SwordArea.monitoring = true
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)
	super._ready()


func on_flip_left() -> void:
	$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

func on_flip_right() -> void:
	$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

func apply_player_damage():
	if hit_window_open:
		if $SwordArea.overlaps_body(player):
			hit_window_open = false
			player.take_damage(config.damage_given)
			
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	apply_player_damage()
	super._physics_process(delta)
	
func take_damage(damage: float, type: DamageTypes.Type) -> void:
	play_animation_player("hurt")
	super.take_damage(damage, type)
	
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
	if state != State.ATTACKING:
		hit_window_open = false
		return
		
	if state == State.ATTACKING and is_on_frame(attack_hit_frame):
		hit_window_open = true
		if not sword_hit_sound.playing:
			sword_hit_sound.play()

func on_enter_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
	
	if body is Player:
		change_state(State.ATTACKING)
		attack_timer = 0
		$WalkTimer.stop()

func on_exit_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
		
	if body is Player:
		if state == State.ATTACKING:
			await $AnimatedSprite2D.animation_finished
		
		if $AttackRange.has_overlapping_bodies():
			change_state(State.ATTACKING)
		else:
			change_state(State.CHASING)
	
func die() -> void:
	sword_hit_sound.stop()
		
	$HealthBar.hide_health_ui()
	state = State.DEAD
	AudioManager.play_sfx($DieSound.stream)
	$AnimatedSprite2D.play("die")

	await $AnimatedSprite2D.animation_finished
	
	drop_item()
	queue_free()

func play_animation_player(animation: String) -> void:
	$AnimationPlayer.play(animation)
