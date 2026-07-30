extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", config.damage_given, 0, 4, 7, 0.9, 1.3),
		AttackConfig.new("attack2", config.damage_given * 1.5, 0, 4, 6, 1.2, 1.7)
	]

	super._ready()
