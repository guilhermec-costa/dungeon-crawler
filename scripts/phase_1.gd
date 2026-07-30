extends Node

class_name Phase1

var yellowSkeletonScene: PackedScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene: PackedScene = preload("res://scenes/enemies/white_skeleton.tscn")
var blue_golem: PackedScene = preload("res://scenes/enemies/blue_golem.tscn")

@onready var phase1_animation_player: PlayerEnterPhase1 = $Cutscenes/PlayerEnterPhase1
@onready var player_hud: PlayerHUD = $PlayerHUD
@onready var entities = $World/Entities
@onready var player: Player = $World/Entities/Player
@onready var secret_room: Node2D = $World/SecretRoom
@onready var dungeon_map: Node2D = $World/DungeonMap
@onready var phase_1_boss: Phase1Boss = $World/Entities/Phase1Boss
@onready var boss_cutscene_trigger: Area2D = $World/DungeonMap/BossCutsceneTrigger
@onready var boss_battle_position: Marker2D = $World/DungeonMap/BossBattlePosition
@onready var player_camera: Camera2D = $World/Entities/Player/Camera2D

var last_position_on_dungeon_map: Vector2 = Vector2.ZERO
var boss_intro_started := false

func _ready() -> void:
	player.current_room = dungeon_map
	player.room_change_requested.connect(_on_player_room_change_request)
	phase_1_boss.setup(player)
	boss_cutscene_trigger.body_entered.connect(_on_boss_cutscene_trigger_body_entered)
	secret_room.hide()
	
func start():
	if OS.has_feature("cutscene_enabled"):
		player.change_state(Player.State.CUTSCENE)
		await phase1_animation_player.play()
	
	player.change_state(Player.State.IDLE)
	player.start($PlayerStartPosition.global_position)

func _on_player_room_change_request(room: Node2D, spawn_position: Vector2):
	await TransitionManager.fade_out()
	player.position_on_last_room = player.global_position
	player.last_leaved_room = player.current_room
	player.current_room = room
	last_position_on_dungeon_map = player.global_position
	player.global_position = spawn_position
	player.last_leaved_room.hide()
	player.current_room.show()
	await TransitionManager.fade_in()

func _on_boss_cutscene_trigger_body_entered(body: Node2D) -> void:
	if body != player or boss_intro_started:
		return

	boss_intro_started = true
	boss_cutscene_trigger.set_deferred("monitoring", false)
	await play_boss_intro()

func play_boss_intro() -> void:
	player.change_state(Player.State.CUTSCENE)
	player.velocity = Vector2.ZERO

	var camera_start_position := player_camera.position
	var camera_start_zoom := player_camera.zoom
	var boss_position := phase_1_boss.get_focus_position()
	var boss_camera_position := player.to_local(boss_position) - player_camera.offset

	var focus_tween := create_tween().set_parallel()
	focus_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	focus_tween.tween_property(
		player_camera,
		"position",
		boss_camera_position,
		1.75
	)
	focus_tween.tween_property(
		player_camera,
		"zoom",
		camera_start_zoom * 1.12,
		1.75
	)
	await focus_tween.finished
	await get_tree().create_timer(0.35).timeout

	await phase_1_boss.play_revival()
	await get_tree().create_timer(0.3).timeout

	var battle_position := boss_battle_position.global_position
	var battle_camera_position := (
		player.to_local(battle_position) - player_camera.offset
	)
	var camera_follow_tween := create_tween()
	camera_follow_tween.set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	camera_follow_tween.tween_property(
		player_camera,
		"position",
		battle_camera_position,
		Phase1Boss.INTRO_WALK_DURATION
	)
	await phase_1_boss.play_intro_walk(battle_position)
	player_camera.position = battle_camera_position
	boss_position = phase_1_boss.get_focus_position()
	await get_tree().create_timer(0.45).timeout

	var return_tween := create_tween().set_parallel()
	return_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(
		player_camera,
		"position",
		camera_start_position,
		1.0
	)
	return_tween.tween_property(
		player_camera,
		"zoom",
		camera_start_zoom,
		1.0
	)
	await return_tween.finished
	player_camera.position = camera_start_position
	player_camera.zoom = camera_start_zoom

	var step_direction := (
		1.0 if boss_position.x >= player.global_position.x else -1.0
	)
	var walk_direction := Vector2(step_direction, 0.0)
	player.animated_sprite.update_flip(walk_direction)
	player.animated_sprite.update_animation("walk")

	var player_step_tween := create_tween()
	player_step_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	player_step_tween.tween_property(
		player,
		"global_position",
		player.global_position + walk_direction * 32.0,
		0.8
	)
	await player_step_tween.finished

	player.velocity = Vector2.ZERO
	player.animated_sprite.update_animation("idle")
	player.change_state(Player.State.IDLE)
	phase_1_boss.start_battle()
