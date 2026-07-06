extends CharacterBody2D

class_name Player

const SPEED = 130
const SWORD_COLLIDER_OFFSET = 50
const PLAYER_ATTACK_OFFSET = 20
const PLAYER_COLLIDER_X = 0
var health: float = 100


enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	SLIDING
}

var state := State.	IDLE

var center: Vector2:
	get:
		return global_position + $AnimatedSprite2D.offset

func _ready():
	$Camera2D.zoom = Vector2(2, 2)
	
func start(initial_pos: Vector2):
	self.position = initial_pos
	state = State.IDLE
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
					if new_zoom <= Vector2(3, 3): 
						$Camera2D.zoom = new_zoom
				MOUSE_BUTTON_WHEEL_DOWN:
					var new_zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
					if new_zoom >= Vector2(1.5, 1.5):	
						$Camera2D.zoom = new_zoom
				MOUSE_BUTTON_LEFT:
					if not state == State.ATTACKING:
						state = State.ATTACKING
						$SwordAttackSound.play()
						$SwordArea/CollisionShape2D.disabled = false
						

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	
func _process(delta: float) -> void:
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
		if $AnimatedSprite2D.flip_h:
			$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
			$AnimatedSprite2D.offset.x += 8
		$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("move_left"):
		if not $AnimatedSprite2D.flip_h:
			$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
			$AnimatedSprite2D.offset.x -= 8
		$AnimatedSprite2D.flip_h = true
	
	var animation = get_animation_from_state()	
	$AnimatedSprite2D.animation = animation	
	$AnimatedSprite2D.play()


func get_animation_from_state() -> String:
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
		$SwordArea/CollisionShape2D.disabled = true

func take_damage(damage: float):
	health -= damage
	print("Player health: ", healthgit statcv)
