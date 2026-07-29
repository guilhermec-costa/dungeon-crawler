extends BaseSkeleton

var current_combo: AttackCombo
var combo_attack_index := 0

var combo_basic: AttackCombo
var combo_aggressive: AttackCombo
var combo_special: AttackCombo


func _ready():
	attacks = [
		AttackConfig.new("attack1", 10, 0, 4, 8, 0.8, 1.2),
		AttackConfig.new("attack2", 15, 0, 2, 4, 1.2, 2.0),
		AttackConfig.new("attack3", 35, 0, 3, 4, 1.5, 2.5)
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

	var attack = current_combo.attacks[combo_attack_index]

	combo_attack_index += 1


	if combo_attack_index >= current_combo.attacks.size():
		finish_combo()


	return attack

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
