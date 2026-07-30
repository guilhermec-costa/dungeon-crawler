extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", config.damage_given, 0, 5, 7, 1.0, 1.5),
		AttackConfig.new("attack2", config.damage_given * 1.5, 0, 5, 8, 1.3, 1.8)
	]

	super._ready()
