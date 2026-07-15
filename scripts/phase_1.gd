extends Node

class_name Phase1

var yellowSkeletonScene = preload("res://scenes/enemies/yellow_skeleton.tscn")
var whiteSkeletonScene = preload("res://scenes/enemies/white_skeleton.tscn")
var blue_golem = preload("res://scenes/enemies/blue_golem.tscn")
var minimap = preload("res://scenes/minimap.tscn")

@onready var player_hud: PlayerHUD = $PlayerHUD
@onready var entities = $World/Entities
@onready var player: Player = entities.get_node("Player")

func _ready() -> void:
	player_hud.player = player
	player_hud.update_max_health()
	player_hud.update_health()
	player_hud.update_max_stamina()
	player_hud.update_stamina()
	
	player.damage_taken.connect(_on_player_damage_taken)
	player.update_stamina.connect(_on_player_deplete_stamina)
	
func spawn_mobs():
	player.start($PlayerStartPosition.position)

func setup_minimap():
	var _minimap: Minimap = minimap.instantiate()
	_minimap.player = player
	add_child(_minimap)
	
func start():
	spawn_mobs()
	#setup_minimap()


func _on_player_damage_taken() -> void:
	player_hud.update_health()

func _on_player_deplete_stamina() -> void:
	player_hud.update_stamina()
	
