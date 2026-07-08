extends CharacterBody2D

class_name Player

@export var speed: float = 30
@export var max_health: float
var health: float;

const SWORD_COLLIDER_OFFSET = 50
const PLAYER_ATTACK_OFFSET = 20
const PLAYER_COLLIDER_X = 0

enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	SLIDING
}

var state := State.	IDLE

@onready var health_bar: HealthBar = $HealthBar

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.5, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 65, 10, shadow_color)
	
func _ready():
	$Camera2D.zoom = Vector2(4, 4)
	health_bar.max_value = max_health
	health = max_health
	$HealthBar.set_health_bar_value(health)
	
func start(initial_pos: Vector2):
	self.position = initial_pos
	state = State.IDLE
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true

var camera_control_enabled: bool = true
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if camera_control_enabled:
						var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
						if new_zoom <= Vector2(3, 3): 
							$Camera2D.zoom = new_zoom
				MOUSE_BUTTON_WHEEL_DOWN:
					if camera_control_enabled:
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
	velocity = direction * speed
	if state != State.ATTACKING:
		update_flip(direction)
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
	
	update_animation(get_animation_from_state())


func update_flip(direction: Vector2) -> void:
	if direction.x > 0:
		if $AnimatedSprite2D.flip_h:
			$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
			$AnimatedSprite2D.offset.x += 8
		$AnimatedSprite2D.flip_h = false
	elif direction.x < 0:
		if not $AnimatedSprite2D.flip_h:
			$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
			$AnimatedSprite2D.offset.x -= 8
		$AnimatedSprite2D.flip_h = true
			
func update_animation(new_animation: String) -> void:
	if $AnimatedSprite2D.animation != new_animation:
		$AnimatedSprite2D.play(new_animation)
		
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
	$HealthBar.set_health_bar_value(health)
