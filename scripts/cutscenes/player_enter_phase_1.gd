class_name PlayerEnterPhase1
extends Node2D

const WAKE_FRAME_DELAYS := [0.52, 0.48, 0.58, 0.62]
const WALK_TO_START_DURATION := 0.85

@onready var player: Player = $"../../World/Entities/Player"
@onready var player_start_position: Marker2D = $"../../PlayerStartPosition"


func play() -> void:
	player.change_state(Player.State.CUTSCENE)
	player.velocity = Vector2.ZERO
	player.stop_movement_sounds()
	player.animation_player.stop()

	await _play_wake_sequence()
	await _walk_to_start_position()


func _play_wake_sequence() -> void:
	var sprite := player.animated_sprite
	sprite.stop()
	sprite.animation = &"stand"
	sprite.frame = 0
	sprite.frame_progress = 0.0

	# The stand animation is a one-shot sequence. Setting each frame manually
	# prevents AnimationPlayer from overriding it while the player is in CUTSCENE.
	for frame_index in range(1, 5):
		await get_tree().create_timer(WAKE_FRAME_DELAYS[frame_index - 1]).timeout
		sprite.frame = frame_index
		sprite.frame_progress = 0.0

	await get_tree().create_timer(0.25).timeout


func _walk_to_start_position() -> void:
	var direction := player.global_position.direction_to(
		player_start_position.global_position
	)
	player.animated_sprite.update_flip(direction)
	player.animated_sprite.update_animation("walk")

	var walk_tween := create_tween()
	walk_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk_tween.tween_property(
		player,
		"global_position",
		player_start_position.global_position,
		WALK_TO_START_DURATION
	)
	await walk_tween.finished

	player.global_position = player_start_position.global_position
	player.velocity = Vector2.ZERO
	player.animated_sprite.update_animation("idle")
