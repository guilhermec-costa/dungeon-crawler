class_name AttackCombo
extends RefCounted


var combo_name: String
var attacks: Array[AttackConfig] = []
var sub_combos: Array[AttackCombo] = []

var parent_combo: AttackCombo


func _init(
	_name: String,
	_attacks: Array[AttackConfig]
):
	combo_name = _name
	attacks = _attacks


func add_sub_combo(combo: AttackCombo):
	combo.parent_combo = self
	sub_combos.append(combo)
