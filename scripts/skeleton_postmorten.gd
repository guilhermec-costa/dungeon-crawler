extends Node2D

class_name SkeletonPostmorten

func on_despawn_timer_timeout():
	queue_free()
