extends Node

var skeletonScene = preload("res://scenes/skeleton.tscn")

func _ready():
	$Entities/Player.start($PlayerStartPosition.position)
	var skeleton: Skeleton = skeletonScene.instantiate()
	skeleton.player = $Entities/Player
	$Entities.add_child(skeleton)
