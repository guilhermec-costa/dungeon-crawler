extends Node2D

@export var player: Player

@onready var bottom_to_top: Node2D = $BottomToTop
@onready var top_to_bottom: Node2D = $TopToBottom

@onready var bottom_base: TileMapLayer = $BottomToTop/WallBase

@onready var bottom_collision: CollisionShape2D = $BottomToTop/StaticBody2D/CollisionShape2D
@onready var top_collision: CollisionShape2D = $TopToBottom/StaticBody2D/CollisionShape2D

var wall_y: float
var showing_bottom := false


func _ready() -> void:
	var cells := bottom_base.get_used_cells()

	if cells.is_empty():
		push_error("WallBase não possui tiles.")
		return

	wall_y = bottom_base.to_global(
		bottom_base.map_to_local(cells[0])
	).y

	update_wall()


func _process(_delta: float) -> void:
	update_wall()


func update_wall() -> void:
	var should_show_bottom := player.global_position.y > wall_y

	if should_show_bottom == showing_bottom:
		return

	showing_bottom = should_show_bottom

	if showing_bottom:
		show_bottom()
	else:
		show_top()


func show_bottom() -> void:
	bottom_to_top.visible = true
	top_to_bottom.visible = false

	bottom_collision.set_deferred("disabled", false)
	top_collision.set_deferred("disabled", true)


func show_top() -> void:
	bottom_to_top.visible = false
	top_to_bottom.visible = true

	bottom_collision.set_deferred("disabled", true)
	top_collision.set_deferred("disabled", false)
