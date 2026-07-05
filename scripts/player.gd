extends CharacterBody2D

const SPEED = 200

enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	SLIDING
}

var state := State.	IDLE

func _ready():
	$Camera2D.zoom = Vector2(2.5, 2.5)
	
func start(initial_pos: Vector2):
	self.position = initial_pos
	state = State.IDLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
					if new_zoom <= Vector2(2.5, 2.5): 
						$Camera2D.zoom = new_zoom
				MOUSE_BUTTON_WHEEL_DOWN:
					var new_zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
					if new_zoom >= Vector2(2.5, 2.5):	
						$Camera2D.zoom = new_zoom
				MOUSE_BUTTON_LEFT:
					state = State.ATTACKING
					$SwordAttackSound.play()

func _process(delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SPEED

	if state != State.ATTACKING:
		if velocity == Vector2.ZERO:
			state = State.IDLE
			if $RunningSound.playing:
				$RunningSound.stop()
		else:
			state = State.RUNNING
			if not $RunningSound.playing:
				$RunningSound.play()

	if Input.is_action_pressed("move_right"):
		$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("move_left"):
		$AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("player_slide"):
		state = State.SLIDING
	
	var animation: String = get_animation_from_state()	
	$AnimatedSprite2D.animation = animation	
	$AnimatedSprite2D.play()
	
	move_and_slide()

func get_animation_from_state():
	match state:
		State.IDLE:
			return "idle"
		State.ATTACKING:
			return "attack"
		State.RUNNING:
			return "run"
		State.SLIDING:
			return "slide"
		_:
			return "idle"
			
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "attack":
		state = State.IDLE
