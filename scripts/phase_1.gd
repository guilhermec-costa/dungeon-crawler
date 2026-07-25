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

var last_position_on_dungeon_map: Vector2 = Vector2.ZERO

func _ready() -> void:
	player_hud.update_max_health()
	player_hud.update_health()
	player_hud.update_max_stamina()
	player_hud.update_stamina()
	
	player.current_room = dungeon_map
	player.damage_taken.connect(_on_player_damage_taken)
	player.update_stamina.connect(_on_player_deplete_stamina)
	player.room_change_requested.connect(_on_player_room_change_request)
	
	secret_room.hide()
	
func start():
	if OS.has_feature("cutscene_enabled"):
		player.state = Player.State.CUTSCENE
		await phase1_animation_player.play()
	player.start()


func _on_player_damage_taken() -> void:
	player_hud.update_health()

func _on_player_deplete_stamina() -> void:
	player_hud.update_stamina()

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
