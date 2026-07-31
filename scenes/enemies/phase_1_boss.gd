class_name Phase1Boss
extends Node2D

@export var player: Player

@onready var skeleton_knight: BaseSkeleton = $SkeletonKnight
@onready var animated_sprite: AnimatedSprite2D = $SkeletonKnight/AnimatedSprite2D
@onready var boss_hud: CanvasLayer = $BossHUD
@onready var boss_health_bar: TextureProgressBar = $BossHUD/TextureProgressBar
@onready var body_collision: CollisionShape2D = $SkeletonKnight/CollisionShape2D
@onready var attack_range: Area2D = $SkeletonKnight/AttackRange
@onready var start_chase_area: Area2D = $SkeletonKnight/StartChaseArea
@onready var limit_chase_area: Area2D = $SkeletonKnight/LimitChaseArea
@onready var sword_area: Area2D = $SkeletonKnight/SwordArea
@onready var walk_timer: Timer = $SkeletonKnight/WalkTimer

var battle_started := false
var intro_skipped := false
var intro_walk_tween: Tween

const INTRO_WALK_DURATION := 4.0


func setup(p: Player) -> void:
	player = p
	skeleton_knight.player = p
	prepare_for_intro()


func prepare_for_intro() -> void:
	battle_started = false
	intro_skipped = false
	boss_hud.visible = false
	skeleton_knight.velocity = Vector2.ZERO
	skeleton_knight.state = BaseEnemy.State.IDLE
	skeleton_knight.set_process(false)
	skeleton_knight.set_physics_process(false)
	walk_timer.stop()

	body_collision.disabled = true
	attack_range.monitoring = false
	start_chase_area.monitoring = false
	limit_chase_area.monitoring = false
	sword_area.monitoring = false

	animated_sprite.stop()
	animated_sprite.animation = &"die"
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"die") - 1
	animated_sprite.frame_progress = 1.0

	boss_health_bar.max_value = skeleton_knight.config.max_health
	boss_health_bar.value = skeleton_knight.health


func get_focus_position() -> Vector2:
	return skeleton_knight.global_position


func play_revival() -> void:
	animated_sprite.speed_scale = 0.55
	animated_sprite.play_backwards(&"die")
	await animated_sprite.animation_finished
	if intro_skipped:
		return

	animated_sprite.speed_scale = 1.0
	animated_sprite.play(&"idle")


func play_intro_walk(target_position: Vector2) -> void:
	var walk_direction := skeleton_knight.global_position.direction_to(
		target_position
	)
	if walk_direction.x < 0.0:
		skeleton_knight.flip_to_left()
	elif walk_direction.x > 0.0:
		skeleton_knight.flip_to_right()

	animated_sprite.play(&"walk")
	intro_walk_tween = create_tween()
	intro_walk_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	intro_walk_tween.tween_property(
		skeleton_knight,
		"global_position",
		target_position,
		INTRO_WALK_DURATION
	)
	await intro_walk_tween.finished
	if intro_skipped:
		return

	skeleton_knight.global_position = target_position
	skeleton_knight.spawn_origin = target_position
	skeleton_knight.velocity = Vector2.ZERO
	animated_sprite.play(&"idle")
	intro_walk_tween = null


func cancel_intro() -> void:
	intro_skipped = true
	if intro_walk_tween and intro_walk_tween.is_valid():
		intro_walk_tween.kill()
	intro_walk_tween = null

	animated_sprite.stop()
	animated_sprite.speed_scale = 1.0
	skeleton_knight.velocity = Vector2.ZERO


func place_at_battle_position(target_position: Vector2) -> void:
	skeleton_knight.global_position = target_position
	skeleton_knight.spawn_origin = target_position
	skeleton_knight.velocity = Vector2.ZERO
	animated_sprite.play(&"idle")


func skip_intro(target_position: Vector2) -> void:
	cancel_intro()
	place_at_battle_position(target_position)


func start_battle() -> void:
	if battle_started:
		return

	body_collision.disabled = false
	attack_range.monitoring = true
	start_chase_area.monitoring = true
	limit_chase_area.monitoring = true
	sword_area.monitoring = true

	skeleton_knight.update_flip_based_on_player_position()
	skeleton_knight.set_process(true)
	skeleton_knight.set_physics_process(true)
	walk_timer.stop()
	skeleton_knight.change_state(BaseEnemy.State.CHASING)

	battle_started = true
	boss_health_bar.modulate.a = 0.0
	boss_hud.visible = true
	create_tween().tween_property(boss_health_bar, "modulate:a", 1.0, 0.4)


func _process(_delta: float) -> void:
	if not battle_started:
		return

	boss_health_bar.value = skeleton_knight.health
	if skeleton_knight.state == BaseEnemy.State.DEAD:
		battle_started = false
		boss_hud.visible = false
