class_name BlueGolem

extends BaseEnemy

@onready var attack_sound: AudioStreamPlayer2D = $AttackSound

func _ready():
	attack_hit_frame = 7
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)
	super._ready()


func process_special_movement(delta):
	if dash_controller.process(delta):
		velocity = dash_controller.dash_velocity
		return

	if state == State.ATTACKING \
	and dash_controller.can_dash() \
	and is_on_hit_frame():
		dash_controller.try_dash(global_position,player.global_position)
		
func _on_frame_changed() -> void:
	if state == State.ATTACKING and $AnimatedSprite2D.frame == attack_hit_frame:
		for body in $AreaDamageRange.get_overlapping_bodies():
			if body is Player:
				player.take_damage(config.damage_given)
		if not attack_sound.playing:
			attack_sound.play()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
		
	super._physics_process(delta)
	
func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	super._process(delta)
	
func on_enter_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
		
	if body is Player:
		state = State.ATTACKING
		$WalkTimer.stop()


func die():
	drop_gold()
	super.die()
	
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
