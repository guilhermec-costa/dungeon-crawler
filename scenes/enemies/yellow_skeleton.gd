extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", 20, 0, 4, 7, 0.7, 1.1),
		AttackConfig.new("attack2", 30, 0, 4, 6, 1.0, 1.5)
	]

	super._ready()
