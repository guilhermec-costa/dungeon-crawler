class_name Chest
extends Interactable

signal items_collected(_items: Array[ItemData])

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var items: Array[ItemData]

enum State {
	OPENED,
	CLOSED,
}

var state = State.CLOSED

func _on_body_entered(body):
	if state == State.OPENED:
		return

	super._on_body_entered(body)

func change_state(new_state: State):
	if new_state == State.OPENED and current_interaction_widget:
		remove_interaction_widget()
		
	state = new_state
	
func interact(player: Player):
	if state == State.OPENED:
		return
		
	open()
	items_collected.emit(items)
	for item in items:
		player.inventory.add_item(item, 1)
		
func open():
	if state == State.OPENED:
		return
	
	change_state(State.OPENED)
	AudioManager.play_sfx(audio_stream_player_2d.stream)
	await play_and_await("open")

func close():
	if state == State.OPENED:
		change_state(State.CLOSED)
		await play_and_await("close")


func play_and_await(animation: String) -> void:
	$AnimatedSprite2D.play(animation)
	await $AnimatedSprite2D.animation_finished
