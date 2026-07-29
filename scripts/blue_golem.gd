class_name BlueGolem

extends BaseEnemy

@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
var slam_effect: PackedScene = preload("res://scenes/effects/ground_slam_effect.tscn")

func _ready():
	attacks = [
		AttackConfig.new(
			"attack",
			40, # damage
			0,  # stamina
			7,  # hit frame
			12, # end frame
			1.8,
			2.8
		)
	]
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	super._ready()


func process_special_movement(delta):
	if dash_controller.process(delta):
		velocity = dash_controller.dash_velocity
		return

	if state == State.ATTACKING \
	and dash_controller.can_dash() \
	and is_on_hit_frame():
		dash_controller.try_dash(global_position,player.global_position)

func deal_attack_damage():
	if not current_attack:
		return
		
	if hit_window_open and $AreaDamageRange.overlaps_body(player):
			player.take_damage(current_attack.damage)
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

func _process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	super._process(delta)


func die():
	drop_item()
	super.die()
