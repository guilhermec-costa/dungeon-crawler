class_name Inventory
extends Node

signal inventory_update

@export var size := 0

var slots: Dictionary[ItemData, int] = {}

func _init(_size: int) -> void:
	size = _size
	

func has_space() -> bool:
	return slots.size() < size

func get_state():
	return slots
	
func add_item(item: ItemData, amount: int) -> bool:
	if slots.has(item):
		slots[item] += amount
		inventory_update.emit()
		return true

	if not has_space():
		return false

	slots[item] = amount
	inventory_update.emit()

	return true

func free_space(item: ItemData):
	var current_slot = slots.get(item, null)
	if current_slot != null:
		slots.erase(item)
		inventory_update.emit()

func find_by_item_id(id: ItemData.ItemID) -> ItemData:
	for item in slots.keys():
		if item.id == id:
			return item

	return null
	
func consume_item(item: ItemData, quantity: int) -> void:
	if not item.consumable:
		return
		
	var current_item = slots.get(item, null)
	if not current_item:
		return
		
	slots[item] -= quantity
	if slots[item] <= 0:
		free_space(item)
		return
	
	inventory_update.emit()
