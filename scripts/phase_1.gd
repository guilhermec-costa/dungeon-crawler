extends Node

class_name Phase1

signal phase_completed
signal exit_reached

const BOSS_BATTLE_FADE_OUT_DURATION := 0.25
const BOSS_BATTLE_FADE_IN_DURATION := 0.65
const LEAVE_LIGHT_ENERGY := 2.2

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
@onready var boss_respawn_position: Marker2D = $World/DungeonMap/BossRespawnPosition
@onready var player_camera: Camera2D = $World/Entities/Player/Camera2D
@onready var leave_light: PointLight2D = $World/DungeonMap/Lights/LeaveLight
@onready var leave_trigger: Area2D = $World/DungeonMap/LeaveTrigger
@onready var exit_prompt: CanvasLayer = $ExitPrompt
@onready var gate_message: CanvasLayer = $GateMessage
@onready var gate_message_label: Label = $GateMessage/Label
@onready var boss_access_gate: BossAccessGate = $World/DungeonMap/BossAccessGate
@onready var boss_access_gate_collision: CollisionShape2D = $World/DungeonMap/BossAccessGate/StaticBody2D/CollisionShape2D
@onready var arena_gate: Node2D = $World/DungeonMap/ArenaGate
@onready var arena_gate_collision: CollisionShape2D = $World/DungeonMap/ArenaGate/StaticBody2D/CollisionShape2D

var last_position_on_dungeon_map: Vector2 = Vector2.ZERO
var boss_intro_started := false
var boss_intro_playing := false
var boss_intro_skipped := false
var boss_intro_tween: Tween
var boss_intro_camera_position := Vector2.ZERO
var boss_intro_camera_zoom := Vector2.ONE
var boss_intro_player_target := Vector2.ZERO
var boss_intro_generation := 0
var has_completed := false
var awaiting_exit := false
var gate_message_generation := 0


func _ready() -> void:
	player.current_room = dungeon_map
	player.room_change_requested.connect(_on_player_room_change_request)
	phase_1_boss.setup(player)
	phase_1_boss.defeated.connect(_on_phase_1_boss_defeated)
	boss_cutscene_trigger.body_entered.connect(_on_boss_cutscene_trigger_body_entered)
	leave_trigger.body_entered.connect(_on_leave_trigger_body_entered)
	boss_access_gate.locked_touched.connect(_on_boss_access_gate_touched)
	boss_access_gate.unlocked.connect(_unlock_boss_access_gate)
	secret_room.hide()
	leave_light.energy = 0.0
	exit_prompt.hide()
	gate_message.hide()
	set_arena_gate_sealed(false)


func _input(event: InputEvent) -> void:
	if boss_intro_playing and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip_boss_intro()


func start():
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
	boss_intro_generation += 1
	var intro_generation := boss_intro_generation
	boss_intro_playing = true
	boss_intro_skipped = false
	boss_intro_camera_position = player_camera.position
	boss_intro_camera_zoom = player_camera.zoom

	var step_direction := (
		1.0
		if boss_battle_position.global_position.x >= player.global_position.x
		else -1.0
	)
	boss_intro_player_target = (
		player.global_position + Vector2(step_direction, 0.0) * 32.0
	)

	player.change_state(Player.State.CUTSCENE)
	player.velocity = Vector2.ZERO

	var boss_position := phase_1_boss.get_focus_position()
	var boss_camera_position := player.to_local(boss_position) - player_camera.offset

	boss_intro_tween = create_tween().set_parallel()
	boss_intro_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	boss_intro_tween.tween_property(
		player_camera,
		"position",
		boss_camera_position,
		1.75
	)
	boss_intro_tween.tween_property(
		player_camera,
		"zoom",
		boss_intro_camera_zoom * 1.12,
		1.75
	)
	await boss_intro_tween.finished
	if is_boss_intro_cancelled(intro_generation):
		return

	await get_tree().create_timer(0.35).timeout
	if is_boss_intro_cancelled(intro_generation):
		return

	await phase_1_boss.play_revival()
	if is_boss_intro_cancelled(intro_generation):
		return

	await get_tree().create_timer(0.3).timeout
	if is_boss_intro_cancelled(intro_generation):
		return

	var battle_position := boss_battle_position.global_position
	var battle_camera_position := (
		player.to_local(battle_position) - player_camera.offset
	)
	boss_intro_tween = create_tween()
	boss_intro_tween.set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
	boss_intro_tween.tween_property(
		player_camera,
		"position",
		battle_camera_position,
		Phase1Boss.INTRO_WALK_DURATION
	)
	await phase_1_boss.play_intro_walk(battle_position)
	if is_boss_intro_cancelled(intro_generation):
		return

	player_camera.position = battle_camera_position
	await get_tree().create_timer(0.45).timeout
	if is_boss_intro_cancelled(intro_generation):
		return

	boss_intro_tween = create_tween().set_parallel()
	boss_intro_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	boss_intro_tween.tween_property(
		player_camera,
		"position",
		boss_intro_camera_position,
		1.0
	)
	boss_intro_tween.tween_property(
		player_camera,
		"zoom",
		boss_intro_camera_zoom,
		1.0
	)
	await boss_intro_tween.finished
	if is_boss_intro_cancelled(intro_generation):
		return

	player_camera.position = boss_intro_camera_position
	player_camera.zoom = boss_intro_camera_zoom

	var walk_direction := Vector2(step_direction, 0.0)
	player.animated_sprite.update_flip(walk_direction)
	player.animated_sprite.update_animation("walk")

	boss_intro_tween = create_tween()
	boss_intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boss_intro_tween.tween_property(
		player,
		"global_position",
		boss_intro_player_target,
		0.8
	)
	await boss_intro_tween.finished
	if is_boss_intro_cancelled(intro_generation):
		return

	finish_boss_intro()


func is_boss_intro_cancelled(generation: int) -> bool:
	return boss_intro_skipped or generation != boss_intro_generation


func skip_boss_intro() -> void:
	if not boss_intro_playing:
		return

	boss_intro_skipped = true
	if boss_intro_tween and boss_intro_tween.is_valid():
		boss_intro_tween.kill()

	phase_1_boss.cancel_intro()
	finish_boss_intro()


func finish_boss_intro() -> void:
	if not boss_intro_playing:
		return

	boss_intro_playing = false
	boss_intro_tween = null
	player.velocity = Vector2.ZERO
	player.animated_sprite.update_animation("idle")
	player.stop_movement_sounds()

	await TransitionManager.fade_out(BOSS_BATTLE_FADE_OUT_DURATION)

	if boss_intro_skipped:
		phase_1_boss.place_at_battle_position(
			boss_battle_position.global_position
		)
		player.global_position = boss_intro_player_target

	player_camera.position = boss_intro_camera_position
	player_camera.zoom = boss_intro_camera_zoom

	await TransitionManager.fade_in(BOSS_BATTLE_FADE_IN_DURATION)

	player.change_state(Player.State.IDLE)
	phase_1_boss.start_battle()
	set_arena_gate_sealed(true)


func _on_boss_access_gate_touched() -> void:
	show_gate_message("THE CORRIDOR IS SEALED.\nTHE CORRUPTED KEY LIES BEYOND THE RUNE TRIAL.")


func _unlock_boss_access_gate() -> void:
	boss_access_gate_collision.set_deferred("disabled", true)
	boss_access_gate.hide()


func show_gate_message(message: String) -> void:
	gate_message_generation += 1
	var generation := gate_message_generation
	gate_message_label.text = message
	gate_message.show()
	await get_tree().create_timer(3.0).timeout
	if generation == gate_message_generation:
		gate_message.hide()


func set_arena_gate_sealed(sealed: bool) -> void:
	arena_gate.visible = sealed
	arena_gate_collision.set_deferred("disabled", not sealed)


func is_boss_battle_active() -> bool:
	return phase_1_boss.battle_started


func _on_phase_1_boss_defeated() -> void:
	if has_completed:
		return

	has_completed = true
	player.change_state(Player.State.CUTSCENE)
	player.velocity = Vector2.ZERO
	player.stop_movement_sounds()

	# The boss death is deliberately slow and remains visible on the arena floor.
	# Do not reveal the exit until both its animation and death sound have ended.
	await phase_1_boss.wait_for_death_presentation()
	await get_tree().create_timer(0.35).timeout
	await play_boss_victory_epilogue()
	phase_completed.emit()


func play_boss_victory_epilogue() -> void:
	var camera_rest_position := player_camera.position
	var leave_camera_position := player.to_local(leave_light.global_position) \
		- player_camera.offset

	var reveal_tween := create_tween().set_parallel()
	reveal_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reveal_tween.tween_property(
		player_camera,
		"position",
		leave_camera_position,
		1.25
	)
	reveal_tween.tween_property(
		leave_light,
		"energy",
		LEAVE_LIGHT_ENERGY,
		1.4
	)
	await reveal_tween.finished
	await get_tree().create_timer(0.3).timeout

	var return_camera_tween := create_tween()
	return_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return_camera_tween.tween_property(
		player_camera,
		"position",
		camera_rest_position,
		0.55
	)
	await return_camera_tween.finished

	player.change_state(Player.State.IDLE)
	awaiting_exit = true
	exit_prompt.show()
	await exit_reached


func _on_leave_trigger_body_entered(body: Node2D) -> void:
	if body != player or not awaiting_exit:
		return

	awaiting_exit = false
	exit_prompt.hide()
	player.change_state(Player.State.CUTSCENE)
	player.velocity = Vector2.ZERO
	player.stop_movement_sounds()
	exit_reached.emit()


func respawn_after_boss_death() -> void:
	phase_1_boss.stop_battle()
	player.stop_movement_sounds()

	await TransitionManager.fade_out(0.35)

	boss_intro_generation += 1
	boss_intro_started = false
	boss_intro_playing = false
	boss_intro_skipped = false
	boss_intro_tween = null
	awaiting_exit = false
	exit_prompt.hide()

	phase_1_boss.reset_for_intro()
	set_arena_gate_sealed(false)
	player_camera.position = boss_intro_camera_position
	player_camera.zoom = boss_intro_camera_zoom
	player.respawn(boss_respawn_position.global_position)
	boss_cutscene_trigger.set_deferred("monitoring", true)

	await TransitionManager.fade_in(0.65)
