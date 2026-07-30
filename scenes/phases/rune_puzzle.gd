extends Node

@onready var rune_puzzle_collider_block: CollisionShape2D = $"../World/DungeonMap/Dungeon/SecretPassageWall/CollisionShape2D"
@onready var puzzle_resolved_message: Label = $PuzzleResolvedMessage
@onready var secret_passage_room: Node2D = $"../World/DungeonMap/Dungeon/SecretPassageRoom"

@onready var runes: Array[RuneSlot] = [
	$"../World/DungeonMap/RuneSlotGrey",
	$"../World/DungeonMap/RuneSlotBlue",
	$"../World/DungeonMap/RuneSlotBlack"
]

func _ready() -> void:
	puzzle_resolved_message.visible = false
	secret_passage_room.visible = false
	for rune in runes:
		rune.placed_rune.connect(_on_placed_rune)

func rune_is_placed(rune: RuneSlot) -> bool:
	return rune.rune_placed
	
func _on_placed_rune() -> void:
	var all_runes_placed = runes.all(func(rune: RuneSlot) : return rune.rune_placed)
	if all_runes_placed:
		rune_puzzle_collider_block.queue_free()
		var tween = create_tween()
		puzzle_resolved_message.modulate.a = 1.0
		puzzle_resolved_message.visible = true
		secret_passage_room.visible = true
		tween.tween_property(puzzle_resolved_message, "modulate:a", 0, 10)
		await tween.finished
		puzzle_resolved_message.queue_free()
