extends BaseSkeleton

func _ready():
	attacks = [
		AttackConfig.new("attack1", 0, 5, 7, 0.3, 0.7),
		AttackConfig.new("attack2", 0, 5, 7, 0.3, 0.7)
	]
	super._ready()
