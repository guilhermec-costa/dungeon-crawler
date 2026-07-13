extends Node

class_name Phase1

var yellowSkeletonScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene = preload("res://scenes/enemies/white_skeleton.tscn")
var blue_golem = preload("res://scenes/enemies/blue_golem.tscn")
var minimap = preload("res://scenes/minimap.tscn")

@onready var player_hud: PlayerHUD = $PlayerHUD
@onready var player: Player = $Entities/Player

func _ready() -> void:
	player_hud.player = player
	player_hud.update_max_health()
	player_hud.update_health()
	
func spawn_mobs():
	player.start($PlayerStartPosition.position)
	var yellowSkeleton: BaseSkeleton = yellowSkeletonScene.instantiate()
	yellowSkeleton.player = player
	yellowSkeleton.position =  player.global_position + Vector2(-250, 120)
	$Entities.add_child(yellowSkeleton)
	
	var yellowSkeleton2: BaseSkeleton = yellowSkeletonScene.instantiate()
	yellowSkeleton2.player = player
	yellowSkeleton2.position =  player.global_position + Vector2(-250, 120)
	$Entities.add_child(yellowSkeleton2)
	
	var whiteSkeleton: BaseSkeleton = whiteSkeletonScene.instantiate()
	whiteSkeleton.player = player
	whiteSkeleton.position = player.global_position + Vector2(-250, 120)
	$Entities.add_child(whiteSkeleton)
	
	var blue_golem: BlueGolem = blue_golem.instantiate()
	blue_golem.player = player
	blue_golem.position = player.global_position + Vector2(180, 25)
	$Entities.add_child(blue_golem)
	
func setup_minimap():
	var _minimap: Minimap = minimap.instantiate()
	_minimap.player = player
	add_child(_minimap)
	
func start():
	spawn_mobs()
	#setup_minimap()


func _on_player_damage_taken() -> void:
	player_hud.update_health()
