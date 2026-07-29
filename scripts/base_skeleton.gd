extends BaseEnemy

class_name BaseSkeleton

@export var SWORD_COLLIDER_OFFSET = 50.0

@onready var sword_hit_sound: AudioStreamPlayer2D = $SwordHitSound

func process_special_movement(delta):
	if dash_controller.process(delta):
		velocity = dash_controller.dash_velocity
		return

	if state == State.ATTACKING \
	and attack_on_progress \
	and dash_controller.can_dash() \
	and not $AttackRange.overlaps_body(player) \
	and is_on_hit_frame():
		dash_controller.try_dash(global_position,player.global_position)


func _ready():
	$SwordArea.monitoring = true
	super._ready()


func on_flip_left() -> void:
	$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

func on_flip_right() -> void:
	$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
	$SwordArea/CollisionShape2D.rotation *= -1

func deal_attack_damage():
	if not current_attack:
		return
		
	if hit_window_open and $SwordArea.overlaps_body(player):
		hit_window_open = false
		print("here")
		player.take_damage(current_attack.damage)
	
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
	if state != State.ATTACKING \
	or not attack_on_progress \
	or not current_attack:
		hit_window_open = false
		return
	
	if is_on_hit_frame():
		hit_window_open = true
		if not sword_hit_sound.playing:
			sword_hit_sound.play()
			
	elif $AnimatedSprite2D.frame >= current_attack.attack_end_frame:
		hit_window_open = false
	
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
