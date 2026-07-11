extends Node

class_name Phase1

var yellowSkeletonScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene = preload("res://scenes/enemies/white_skeleton.tscn")

func start():
	#$Entities/Player.start($PlayerStartPosition.position)
	#var yellowSkeleton: BaseSkeleton = yellowSkeletonScene.instantiate()
	#yellowSkeleton.player = $Entities/Player
	#yellowSkeleton.position =  $Entities/Player.global_position + Vector2(180, 25)
	#$Entities.add_child(yellowSkeleton)
	#
	#var yellowSkeleton2: BaseSkeleton = yellowSkeletonScene.instantiate()
	#yellowSkeleton2.player = $Entities/Player
	#yellowSkeleton2.position =  $Entities/Player.global_position + Vector2(180, 25)
	#$Entities.add_child(yellowSkeleton2)
	
	var whiteSkeleton: BaseSkeleton = whiteSkeletonScene.instantiate()
	whiteSkeleton.player = $Entities/Player
	whiteSkeleton.position = $Entities/Player.global_position + Vector2(180, 25)
	$Entities.add_child(whiteSkeleton)
