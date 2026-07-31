extends CanvasLayer

class_name OpeningStory

signal completed

const STORY_PAGES := [
	"Beneath the ruins of Loreon, a knight heard three bells ringing under the earth.",
	"The first called the dead. The second called the brave. The third only rang when someone forgot to lock the dungeon door.",
	"With a slightly rusty sword and a map scribbled by a hurried necromancer, you descend to discover who woke the skeletons — and why they seem so angry.",
	"Find the runes. Place them in the tombs to open the hidden path. Beyond it waits the Corrupted Key — the only way into the boss corridor.",
	"The dungeon is waiting."
]

@onready var story_text: Label = $StoryText
@onready var progress: Label = $Progress
@onready var advance_hint: Label = $AdvanceHint

var current_page := -1
var is_playing := false
var type_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func play_story() -> void:
	show()
	is_playing = true
	current_page = -1
	show_next_page()
	await completed
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_story()
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance_story()
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		get_viewport().set_input_as_handled()
		advance_story()


func advance_story() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
		story_text.visible_ratio = 1.0
		update_advance_hint()
		return

	show_next_page()


func show_next_page() -> void:
	current_page += 1
	if current_page >= STORY_PAGES.size():
		finish_story()
		return

	story_text.text = tr(STORY_PAGES[current_page])
	story_text.visible_ratio = 0.0
	progress.text = "◆".repeat(current_page + 1) + "◇".repeat(
		STORY_PAGES.size() - current_page - 1
	)
	advance_hint.text = tr("CLICK OR ENTER TO REVEAL")

	type_tween = create_tween()
	type_tween.tween_property(
		story_text,
		"visible_ratio",
		1.0,
		clampf(story_text.text.length() * 0.018, 0.45, 2.0)
	)
	type_tween.finished.connect(update_advance_hint)


func update_advance_hint() -> void:
	if current_page == STORY_PAGES.size() - 1:
		advance_hint.text = tr("CLICK OR ENTER TO BEGIN  •  ESC TO SKIP")
	else:
		advance_hint.text = tr("CLICK OR ENTER TO CONTINUE  •  ESC TO SKIP")


func finish_story() -> void:
	if not is_playing:
		return

	if type_tween and type_tween.is_valid():
		type_tween.kill()

	is_playing = false
	completed.emit()
