extends Node

const GOLD_DROP_SCENE = preload("res://scenes/drops/gold_drop.tscn")
const GREY_RUNE_DROP_SCENE = preload("res://scenes/drops/grey_rune_drop.tscn")
const BLACK_RUNE_DROP_SCENE = preload("res://scenes/drops/black_rune_drop.tscn")
const BLUE_RUNE_DROP_SCENE = preload("res://scenes/drops/blue_rune_drop.tscn")


const drop_id_to_scene: Dictionary[ItemData.ItemID, PackedScene] = {
	ItemData.ItemID.GOLD: GOLD_DROP_SCENE,
	ItemData.ItemID.RUNE_GRAY: GREY_RUNE_DROP_SCENE,
	ItemData.ItemID.RUNE_BLACK: BLACK_RUNE_DROP_SCENE,
	ItemData.ItemID.RUNE_BLUE: BLUE_RUNE_DROP_SCENE
}

func get_item_scene_by_id(item_id: ItemData.ItemID):
	return drop_id_to_scene.get(item_id, null)

func spawn(
	item_id: ItemData.ItemID,
	amount: int,
	position: Vector2,
	parent: Node,
	z_index: int
):
	var scene = self.get_item_scene_by_id(item_id)
	if not scene:
		return

	var drop: BaseDrop = scene.instantiate()
	drop.amount = amount
	drop.global_position = position
	drop.z_index = z_index

	parent.add_child(drop)
