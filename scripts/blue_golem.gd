class_name BlueGolem

extends BaseEnemy

func _ready():
	attack_hit_frame = 7
	postmortem_scene = preload("res://scenes/decorations/skeleton_postmorten.tscn")
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)
	super._ready()

func _on_frame_changed() -> void:
	if state == State.ATTACKING and $AnimatedSprite2D.frame == attack_hit_frame:
		for body in $AreaDamageRange.get_overlapping_bodies():
			if body is Player:
				player.take_damage(damage_given)

func on_enter_attack_range(body: Node2D) -> void:
	if body is Player:
		state = State.ATTACKING
		$WalkTimer.stop()

	
func on_exit_attack_range(body: Node2D) -> void:
	if body is Player:
		if state == State.ATTACKING:
			await $AnimatedSprite2D.animation_finished
		
		if $AttackRange.has_overlapping_bodies():
			state = State.ATTACKING
		else:
			state = State.CHASING
