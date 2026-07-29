class_name BlueGolem

extends BaseEnemy

@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
var slam_effect: PackedScene = preload("res://scenes/effects/ground_slam_effect.tscn")

func _ready():
	attacks = [
		AttackConfig.new("attack", 0, 5, 8, 0.3, 0.8)
	]
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

func apply_player_damage():
	if hit_window_open:
		if $AreaDamageRange.overlaps_body(player):
			player.take_damage(config.damage_given)
			hit_window_open = false
			
func _on_frame_changed() -> void:
	if state != State.ATTACKING:
		hit_window_open = false
		return
		
	if state == State.ATTACKING and is_on_hit_frame():
		hit_window_open = true
		var effect: SlamEffect = slam_effect.instantiate()
		effect.position = Vector2(0, 20)
		add_child(effect)
		effect.play()
		if not attack_sound.playing:
			attack_sound.play()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	apply_player_damage()
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
	drop_item()
	super.die()
