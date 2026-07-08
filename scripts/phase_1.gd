extends Node

var yellowSkeletonScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene = preload("res://scenes/enemies/white_skeleton.tscn")

func _ready():
	$Entities/Player.start($PlayerStartPosition.position)
	var yellowSkeleton: BaseSkeleton = yellowSkeletonScene.instantiate()
	yellowSkeleton.player = $Entities/Player
	yellowSkeleton.position =  $Entities/Player.global_position
	$Entities.add_child(yellowSkeleton)
	
	var whiteSkeleton: BaseSkeleton = whiteSkeletonScene.instantiate()
	whiteSkeleton.player = $Entities/Player
	whiteSkeleton.position = $Entities/Player.global_position + Vector2(85, 40)
	$Entities.add_child(whiteSkeleton)
