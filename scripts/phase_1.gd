extends Node

class_name Phase1

var yellowSkeletonScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene = preload("res://scenes/enemies/white_skeleton.tscn")
var minimap = preload("res://scenes/minimap.tscn")

@onready var player: Player = $Entities/Player

func spawn_mobs():
	player.start($PlayerStartPosition.position)
	var yellowSkeleton: BaseSkeleton = yellowSkeletonScene.instantiate()
	yellowSkeleton.player = player
	yellowSkeleton.position =  player.global_position + Vector2(180, 25)
	$Entities.add_child(yellowSkeleton)
	
	var yellowSkeleton2: BaseSkeleton = yellowSkeletonScene.instantiate()
	yellowSkeleton2.player = player
	yellowSkeleton2.position =  player.global_position + Vector2(180, 25)
	$Entities.add_child(yellowSkeleton2)
	
	var whiteSkeleton: BaseSkeleton = whiteSkeletonScene.instantiate()
	whiteSkeleton.player = player
	whiteSkeleton.position = player.global_position + Vector2(180, 25)
	$Entities.add_child(whiteSkeleton)
	
func setup_minimap():
	var _minimap: Minimap = minimap.instantiate()
	_minimap.player = player
	add_child(_minimap)
	
func start():
	spawn_mobs()
	setup_minimap()
