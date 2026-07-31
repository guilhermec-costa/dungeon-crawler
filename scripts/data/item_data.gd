class_name ItemData
extends Resource

enum ItemID {
	GOLD,
	LIFE_POTION,
	CORRUPTED_KEY,
	RUNE_GRAY,
	RUNE_BLACK,
	RUNE_BLUE
}

@export var id: ItemID
@export var display_name: String
@export var icon: Texture2D
@export var description: String
@export var consumable: bool
@export var icon_scale: Vector2 = Vector2.ONE
@export var collect_sound: AudioStream
@export_range(-80.0, 24.0, 0.5) var collect_volume_db := 1.0
