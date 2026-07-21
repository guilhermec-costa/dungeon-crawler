class_name Chest
extends Interactable

signal items_collected(_items: Array[ItemData])

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var items: Array[ItemData]

enum State {
	OPENED,
	CLOSED,
	OPENING,
	CLOSING,
}

var state = State.CLOSED

func change_state(new_state: State):
	state = new_state
	
func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		body.enter_interectable(self)

func _on_body_exited(body):
	if body is Player:
		body.exit_interactable(self)

	
func interact(player: Player):
	if state == State.CLOSED:
		open()
		items_collected.emit(items)
		for item in items:
			player.inventory.add_item(item, 1)
		
func open():
	if state == State.OPENED:
		return
	
	change_state(State.OPENED)
	AudioManager.play_sfx(audio_stream_player_2d.stream)
	play_and_await("open")

func close():
	if state == State.OPENED:
		change_state(State.CLOSED)
		play_and_await("close")


func play_and_await(animation: String) -> void:
	$AnimatedSprite2D.play(animation)
	await $AnimatedSprite2D.animation_finished
