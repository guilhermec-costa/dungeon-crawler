extends CharacterBody2D

class_name Player

signal player_dead

@export var speed: float = 30
@export var roll_speed_multiplier: float = 1.1
@export var max_health: float
@onready var health_bar: HealthBar = $HealthBar
var damageTakenLabel: PackedScene = preload("res://scenes/damage_label.tscn")


var health: float;
var is_dead: bool = false

const SWORD_COLLIDER_OFFSET = 50
const PLAYER_ATTACK_OFFSET = 20
const PLAYER_COLLIDER_X = 0

enum State {
	IDLE,
	RUNNING,
	ATTACKING,
	SLIDING,
	ROLLING
}

var state := State.	IDLE


func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.5, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 65, 10, shadow_color)
	
func die():
	is_dead = true
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(0.5).timeout
	player_dead.emit()
	
	
func _ready():
	$Camera2D.zoom = Vector2(4, 4)
	health_bar.max_value = max_health
	health = max_health
	$HealthBar.set_health_bar_value(health)
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	
func start(initial_pos: Vector2):
	self.position = initial_pos
	state = State.IDLE
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true

var camera_control_enabled: bool = true
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if camera_control_enabled:
						var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
						if new_zoom <= Vector2(6, 6): 
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

func is_stopped() -> bool:
	return velocity == Vector2.ZERO
		
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	match state:
		State.ATTACKING:
			return
		State.ROLLING:
			move_and_slide()
			return 
			
		_:
			var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			velocity = direction * speed
			update_flip(direction)
			move_and_slide()
			
			if Input.is_action_just_pressed("roll"):
				_start_roll()

func _start_roll():
	state = State.ROLLING
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if is_facing_left() else Vector2.RIGHT
	velocity = direction * speed * roll_speed_multiplier
	
func _process(delta: float) -> void:
	if is_dead:
		return
	
	match state:
		State.ROLLING, State.ATTACKING:
			pass
		_:
			if velocity == Vector2.ZERO:
				state = State.IDLE
				$RunningSound.stop()
			else:
				state = State.RUNNING
				if not $RunningSound.playing:
					$RunningSound.play()
	
	update_animation(get_animation_from_state())

func is_facing_left():
	return $AnimatedSprite2D.flip_h
	
func is_facing_right():
	return not $AnimatedSprite2D.flip_h
	
func update_flip(direction: Vector2) -> void:
	if direction.x > 0:
		if is_facing_left():
			$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
			$AnimatedSprite2D.offset.x += 8
		$AnimatedSprite2D.flip_h = false
	elif direction.x < 0:
		if is_facing_right():
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
		State.ROLLING:
			return "roll"
		_:
			return "idle"
			
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "roll":
		state = State.IDLE
		print("finished")
		
	if $AnimatedSprite2D.animation == "attack":
		state = State.IDLE
		$SwordArea/CollisionShape2D.disabled = true

func take_damage(damage: float):
	if is_dead: 
		return
		
	health -= damage
	$HealthBar.set_health_bar_value(health)
	show_damage_label(damage)
	
	if health <= 0:
		die()
		return

func _on_frame_changed():
	if state == State.ATTACKING and $AnimatedSprite2D.frame == 2:
		$SwordArea/CollisionShape2D.disabled = false



func show_damage_label(damage: float):
	var damage_label: DamageLabel = damageTakenLabel.instantiate()
	add_child(damage_label)
	damage_label.position = Vector2(0, 32)
	damage_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	damage_label.modulate = Color(1.0, 0.3, 0.3)
	damage_label.add_theme_constant_override("outline_size", 4)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.show_damage_label(damage, 0.7)
