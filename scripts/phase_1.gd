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
@onready var player_start_position_secret_room: Marker2D = $World/SecretRoom/PlayerStartPosition

var last_position_on_dungeon_map: Vector2 = Vector2.ZERO

func _ready() -> void:
	player_hud.update_max_health()
	player_hud.update_health()
	player_hud.update_max_stamina()
	player_hud.update_stamina()
	
	secret_room.hide()
	
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
	
func _on_secret_room_enter():
	dungeon_map.hide()
	secret_room.show()

	
func _on_secret_room_exit():
	secret_room.hide()
	dungeon_map.show()
	#player.global_position = last_position_on_dungeon_map

func _on_player_room_change_request(room: Node2D):
	print("change request")
	last_position_on_dungeon_map = player.global_position
	player.global_position = player_start_position_secret_room.global_position
	room.show()
	dungeon_map.hide()
