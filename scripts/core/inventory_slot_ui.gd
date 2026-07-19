class_name InventorySlotUI
extends Control

@onready var icon: TextureRect = $Icon
@onready var amount: Label = $Label
@onready var frame: TextureRect = $Frame

func set_item(item: ItemData, quantity: int):
	icon.texture = item.icon
	icon.visible = true
	tooltip_text = item.description
	amount.text = str(quantity)
	
func clear():
	icon.texture = null
	icon.visible = false
	amount.text = ""
	
	
