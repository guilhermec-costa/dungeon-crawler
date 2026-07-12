class_name Minimap

extends CanvasLayer

@export var camera : Camera2D
@export var player: Player

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport

func _ready() -> void:
	viewport.world_2d = get_tree().root.world_2d
	camera.zoom = Vector2(0.8, 0.8)
	camera.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	camera.position = player.position
