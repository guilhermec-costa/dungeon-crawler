extends BaseSkeleton

var current_combo: AttackCombo
var combo_attack_index := 0

var combo_basic: AttackCombo
var combo_aggressive: AttackCombo
var combo_special: AttackCombo


const ATTACK_SOUND = preload("res://assets/audio/greatsword.mp3")

var random_move_timer := 0.0
var movement_offset := Vector2.ZERO
var combat_maneuver_timer := 0.0
var orbit_direction := 1.0
var shadow_visible := false

const MANEUVER_CHANCE := 0.5
const MANEUVER_DURATION_MIN := 0.65
const MANEUVER_DURATION_MAX := 0.95
const MANEUVER_SPEED_MULTIPLIER := 1.55
const DEATH_ANIMATION_SPEED := 0.48


func _draw() -> void:
	if shadow_visible:
		super._draw()


func set_shadow_visible(value: bool) -> void:
	if shadow_visible == value:
		return
	shadow_visible = value
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta)
	# During combat, the shadow follows real movement instead of remaining under
	# a stationary attacker. The intro walk is handled explicitly by Phase1Boss.
	if state != State.DEAD:
		set_shadow_visible(velocity.length_squared() > 1.0)

func process_special_movement(delta: float) -> void:
	if state == State.CHASING:
		if dash_controller.process(delta):
			velocity = dash_controller.dash_velocity
			return

		if combat_maneuver_timer > 0.0:
			combat_maneuver_timer -= delta
			var toward_player := global_position.direction_to(player.global_position)
			var orbit_vector := toward_player.rotated(
				PI * 0.5 * orbit_direction
			)
			velocity = (
				orbit_vector * 0.92 - toward_player * 0.38
			).normalized() * config.speed * MANEUVER_SPEED_MULTIPLIER

			if combat_maneuver_timer <= 0.0:
				$AnimatedSprite2D.speed_scale = 1.0
				if is_player_in_attack_range():
					change_state(State.ATTACKING)
					attack_timer = 0.25
			return

		random_move_timer -= delta

		if random_move_timer <= 0.0:
			random_move_timer = randf_range(0.2, 0.5)
			movement_offset = Vector2.from_angle(randf() * TAU) * randf_range(0.3, 0.8)

		var direction = global_position.direction_to(player.global_position)
		velocity = (direction + movement_offset).normalized() * config.speed

		return

	super.process_special_movement(delta)
	
func _ready():
	attacks = [
		AttackConfig.new("attack1", config.damage_given * 0.75, 0, 4, 6, 1.2, 1.6)
			.set_audio_config(ATTACK_SOUND, -6.0, 1.30),
		AttackConfig.new("attack2", config.damage_given, 0, 2, 4, 1.4, 1.9)
			.set_audio_config(ATTACK_SOUND, -2.5, 1.00),
		AttackConfig.new("attack3", config.damage_given * 2.0, 0, 3, 4, 1.8, 2.4)
			.set_audio_config(ATTACK_SOUND, 2.0, 0.70)
	]

	setup_combos()

	super._ready()

func setup_combos():
	combo_basic = AttackCombo.new(
		"basic",
		[
			attacks[0],
			attacks[1],
			attacks[2]
		]
	)

	combo_aggressive = AttackCombo.new(
		"aggressive",
		[
			attacks[1],
			attacks[1],
			attacks[2]
		]
	)

	combo_special = AttackCombo.new(
		"special",
		[
			attacks[2],
			attacks[0],
			attacks[2]
		]
	)

	combo_basic.add_sub_combo(combo_aggressive)
	combo_basic.add_sub_combo(combo_special)


	current_combo = combo_basic



func get_next_attack() -> AttackConfig:
	return current_combo.attacks[combo_attack_index]

func on_attack_completed(_attack: AttackConfig) -> void:
	combo_attack_index += 1
	_try_combat_maneuver()
	if combo_attack_index >= current_combo.attacks.size():
		finish_combo()


func _try_combat_maneuver() -> void:
	if state != State.ATTACKING or not is_player_in_attack_range():
		return
	if randf() > MANEUVER_CHANCE:
		return

	combat_maneuver_timer = randf_range(
		MANEUVER_DURATION_MIN,
		MANEUVER_DURATION_MAX
	)
	orbit_direction = -1.0 if randf() < 0.5 else 1.0
	$AnimatedSprite2D.speed_scale = 1.4
	change_state(State.CHASING)

func finish_combo():
	combo_attack_index = 0
	
	
	if current_combo.parent_combo:
		current_combo = current_combo.parent_combo
		return

	if current_combo.sub_combos.size() > 0:
		if randf() < 0.5:
			current_combo = current_combo.sub_combos.pick_random()
			return

	current_combo = combo_basic


func reset_boss_combat_state() -> void:
	clear_attack()
	attack_timer = 0.0
	hit_window_open = false
	velocity = Vector2.ZERO
	walk_direction = Vector2.ZERO

	random_move_timer = 0.0
	movement_offset = Vector2.ZERO
	combat_maneuver_timer = 0.0
	$AnimatedSprite2D.speed_scale = 1.0
	combo_attack_index = 0
	current_combo = combo_basic

	if dash_controller:
		dash_controller.duration_timer = 0.0
		dash_controller.cooldown_timer = 0.0
		dash_controller.dash_velocity = Vector2.ZERO

	health = config.max_health
	health_bar.set_health_bar_value(health)
	health_bar.hide_health_ui()
	state = State.IDLE

	$AnimationPlayer.stop()
	$AnimatedSprite2D.modulate = Color.WHITE
	$RunningSound.stop()
	sword_hit_sound.stop()
	set_shadow_visible(false)


func die() -> void:
	if state == State.DEAD:
		return

	# The boss remains as a body in the arena for the victory cutscene.
	clear_attack()
	$HealthBar.hide_health_ui()
	state = State.DEAD
	velocity = Vector2.ZERO
	set_shadow_visible(false)
	$RunningSound.stop()
	sword_hit_sound.stop()
	$DieSound.play()
	$AnimatedSprite2D.speed_scale = DEATH_ANIMATION_SPEED
	$AnimatedSprite2D.play(&"die")

	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.speed_scale = 1.0
