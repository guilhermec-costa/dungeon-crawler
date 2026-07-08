extends Area2D

@export var damage: float = 5
func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is BaseSkeleton:
		var damage = damage
		body.take_damage(damage)
