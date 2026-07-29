extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", 0, 4, 5, 1, 1.5),
		AttackConfig.new("attack2", 0, 1, 2, 1, 1.5),
		AttackConfig.new("attack3", 0, 2, 4, 1, 1.8)
	]
	super._ready()
