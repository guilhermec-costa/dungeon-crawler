extends Node2D

@export var player: Player
@export var switch_offset_y := -20
@export var behind_player_z_index := -1
@export var in_front_of_player_z_index := 1

@onready var behind_player: CanvasItem = $BehindPlayer
@onready var in_front_of_player: CanvasItem = $InFrontOfPlayer

var _showing_behind := false
var _initialized := false


func _ready() -> void:
	if player == null:
		push_error("DualPillar precisa de uma referência para o player.")
		set_process(false)
		return

	_update_pillar()


func _process(_delta: float) -> void:
	_update_pillar()


func _update_pillar() -> void:
	var should_show_behind := player.global_position.y > global_position.y + switch_offset_y
	
	if _initialized and should_show_behind == _showing_behind:
		return

	_initialized = true
	_showing_behind = should_show_behind
	z_index = (
		behind_player_z_index
		if _showing_behind
		else in_front_of_player_z_index
	)
	behind_player.visible = _showing_behind
	in_front_of_player.visible = not _showing_behind
