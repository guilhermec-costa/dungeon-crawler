extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", 10, 0, 5, 7, 1.0, 1.5),
		AttackConfig.new("attack2", 15, 0, 5, 8, 1.3, 1.8)
	]

	super._ready()
