class_name RuneSlot
extends Interactable

signal placed_rune

@export var runeId: ItemData.ItemID

@onready var frame_icon: Sprite2D = $Frame/Icon
@onready var socket: Sprite2D = $Frame/Socket
@onready var rune_ring: Sprite2D = $Frame/RuneRing
@onready var rune_glow: PointLight2D = $RuneGlow

var rune_placed := false
var rune_color := Color.WHITE


func _ready() -> void:
	super._ready()
	rune_color = _get_rune_color()
	_apply_empty_visuals()


func _process(_delta: float) -> void:
	var pulse := (sin(Time.get_ticks_msec() * 0.0022) + 1.0) * 0.5
	rune_ring.rotation += _delta * (0.18 if rune_placed else 0.07)
	rune_ring.modulate.a = 0.75 + pulse * 0.16 if rune_placed else 0.24 + pulse * 0.12
	rune_glow.energy = 0.95 + pulse * 0.2 if rune_placed else 0.28 + pulse * 0.1


func set_frame_item(item: ItemData) -> void:
	frame_icon.texture = item.icon
	frame_icon.visible = true
	frame_icon.scale = Vector2(0.19, 0.19)
	frame_icon.modulate = Color.WHITE

	rune_ring.modulate = rune_color.lightened(0.2)
	rune_ring.modulate.a = 0.75
	socket.modulate = rune_color.darkened(0.62)
	rune_glow.color = rune_color

	var placement_tween := create_tween()
	placement_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	placement_tween.tween_property(frame_icon, "scale", Vector2(0.245, 0.245), 0.14)
	placement_tween.tween_property(frame_icon, "scale", Vector2(0.19, 0.19), 0.16)


func _apply_empty_visuals() -> void:
	socket.modulate = rune_color.darkened(0.72)
	rune_ring.modulate = rune_color
	rune_ring.modulate.a = 0.3
	rune_glow.color = rune_color


func _get_rune_color() -> Color:
	match runeId:
		ItemData.ItemID.RUNE_GRAY:
			return Color("a8b0c0")
		ItemData.ItemID.RUNE_BLACK:
			return Color("8a4c9e")
		ItemData.ItemID.RUNE_BLUE:
			return Color("4d9cff")
		_:
			return Color("8ba6ca")


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not rune_placed:
		super._on_body_entered(body)


func interact(player: Player) -> void:
	var rune := player.inventory.find_by_item_id(runeId)
	if not rune:
		return

	rune_placed = true
	set_frame_item(rune)
	$PlaceSound.play()
	player.inventory.free_space(rune)
	remove_interaction_widget()
	placed_rune.emit()
