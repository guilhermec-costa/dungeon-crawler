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

func setup(p: Player) -> void:
	player = p
	skeleton_knight.player = p
	prepare_for_intro()

func prepare_for_intro() -> void:
	battle_started = false
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
	animated_sprite.speed_scale = 0.8
	animated_sprite.play_backwards(&"die")
	await animated_sprite.animation_finished
	animated_sprite.speed_scale = 1.0
	animated_sprite.play(&"idle")

func start_battle() -> void:
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
