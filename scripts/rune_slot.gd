class_name RuneSlot
extends Interactable

@onready var frame_icon: TextureRect = $Frame/Icon
@export var runeId: ItemData.ItemID

var rune_placed: bool = false

func set_frame_item(_item: ItemData):
	frame_icon.texture = _item.icon
	frame_icon.visible = true
	frame_icon.scale = Vector2.ONE

func _on_body_entered(body):
	if body is Player and not rune_placed:
		super._on_body_entered(body)
		
func interact(player: Player):
	var rune = player.inventory.find_by_item_id(self.runeId)
	if rune:
		rune_placed = true
		set_frame_item(rune)
		player.inventory.free_space(rune)
		remove_interaction_widget()
