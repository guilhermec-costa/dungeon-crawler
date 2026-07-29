class_name Phase1Boss
extends Node2D

@export var player: Player

@onready var skeleton_knight: BaseSkeleton = $SkeletonKnight


func setup(p: Player) -> void:
	skeleton_knight.player = p
