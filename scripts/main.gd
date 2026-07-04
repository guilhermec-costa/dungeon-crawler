extends Node

func _ready() -> void:
	$Player.start($PlayerStartPosition.position, Vector2(3, 3))
