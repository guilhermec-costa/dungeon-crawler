class_name Hotbar
extends HBoxContainer

@onready var slots: Array[InventorySlotUI] = [
	$InventorySlotUI,
	$InventorySlotUI2,
	$InventorySlotUI3,
	$InventorySlotUI4,
	$InventorySlotUI5
]

func _ready() -> void:
	for i in slots.size():
		slots[i].setup(i + 1)
