class_name ItemData
extends Resource

enum ItemID {
	GOLD,
	LIFE_POTION,
	CORRUPTED_KEY
}

@export var id: ItemID
@export var display_name: String
@export var icon: Texture2D
@export var description: String
@export var consumable: bool
@export var icon_scale: Vector2 = Vector2.ONE
