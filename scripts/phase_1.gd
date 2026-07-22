extends Node

class_name Phase1

var yellowSkeletonScene: PackedScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene: PackedScene = preload("res://scenes/enemies/white_skeleton.tscn")
var blue_golem: PackedScene = preload("res://scenes/enemies/blue_golem.tscn")

@onready var player_hud: PlayerHUD = $PlayerHUD
@onready var entities = $World/Entities
@onready var player: Player = entities.get_node("Player")
@onready var secret_room: Node2D = $World/SecretRoom
@onready var dungeon_map: Node2D = $World/DungeonMap

var last_position_on_dungeon_map: Vector2 = Vector2.ZERO

func _ready() -> void:
	player_hud.update_max_health()
	player_hud.update_health()
	player_hud.update_max_stamina()
	player_hud.update_stamina()
	
	secret_room.hide()
	
	player.current_room = dungeon_map
	player.damage_taken.connect(_on_player_damage_taken)
	player.update_stamina.connect(_on_player_deplete_stamina)
	player.room_change_requested.connect(_on_player_room_change_request)
	
func spawn_mobs():
	player.start($PlayerStartPosition.position)
	
func start():
	spawn_mobs()


func _on_player_damage_taken() -> void:
	player_hud.update_health()

func _on_player_deplete_stamina() -> void:
	player_hud.update_stamina()

func _on_player_room_change_request(room: Node2D, spawn_position: Vector2):
	player.position_on_last_room = player.global_position
	player.last_leaved_room = player.current_room
	player.current_room = room
	last_position_on_dungeon_map = player.global_position
	player.global_position = spawn_position
	player.last_leaved_room.hide()
	player.current_room.show()
