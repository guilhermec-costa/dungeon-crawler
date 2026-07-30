extends BaseSkeleton

var current_combo: AttackCombo
var combo_attack_index := 0

var combo_basic: AttackCombo
var combo_aggressive: AttackCombo
var combo_special: AttackCombo


const ATTACK_SOUND = preload("res://assets/audio/greatsword.mp3")

var random_move_timer := 0.0
var movement_offset := Vector2.ZERO

func process_special_movement(delta: float) -> void:
	if state == State.CHASING:
		random_move_timer -= delta

		if random_move_timer <= 0.0:
			random_move_timer = randf_range(0.2, 0.5)
			movement_offset = Vector2.from_angle(randf() * TAU) * randf_range(0.3, 0.8)

		var direction = global_position.direction_to(player.global_position)
		velocity = (direction + movement_offset).normalized() * config.speed

	super.process_special_movement(delta)
	
func _ready():
	attacks = [
		AttackConfig.new("attack1", 10, 0, 4, 6, 1.2, 1.6)
			.set_audio_config(ATTACK_SOUND, -6.0, 1.30),
		AttackConfig.new("attack2", 15, 0, 2, 4, 1.4, 1.9)
			.set_audio_config(ATTACK_SOUND, -2.5, 1.00),
		AttackConfig.new("attack3", 35, 0, 3, 4, 1.8, 2.4)
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
	if combo_attack_index >= current_combo.attacks.size():
		finish_combo()

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
