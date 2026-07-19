class_name Inventory
extends Node


signal item_added(item: ItemData, amount: int)

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
		item_added.emit(item, slots[item])
		return true

	if not has_space():
		return false

	slots[item] = amount
	item_added.emit(item, amount)

	return true
