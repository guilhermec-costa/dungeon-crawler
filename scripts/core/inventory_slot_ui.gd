class_name InventorySlotUI
extends Control

signal consume_item(item: ItemData, quantity: int)

@onready var icon: TextureRect = $Icon
@onready var amount: Label = $Label
@onready var frame: TextureRect = $Frame
@onready var index_label: Label = $Index

var index: int
var base_index_from_zero := 48
var item: ItemData

func setup(_index: int) -> void:
	index_label.text = str(_index)
	index = _index
	 
func set_item(_item: ItemData, quantity: int):
	icon.texture = _item.icon
	#icon.scale = _item.icon_scale
	icon.visible = true
	tooltip_text = _item.description
	amount.text = str(quantity)
	self.item = _item
	
func clear():
	icon.texture = null
	icon.visible = false
	amount.text = ""
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			var relative_index = event.keycode - base_index_from_zero
			if relative_index >= 0 and relative_index == index:
				consume_item.emit(item, 1)
