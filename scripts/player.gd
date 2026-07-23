extends CharacterBody2D

class_name Player

signal player_dead
signal damage_taken
signal update_stamina
signal room_change_requested(room: Node2D, spawn_position: Vector2)

@onready var raycast: RayCast2D = $CollisionRay
@onready var sword_area: SwordArea = $SwordArea
@export var roll_speed_multiplier: float = 1.6
@export var sprinting_multiplier: float = 1.5
@export var max_health: float
@export var max_stamina: float
@export var dodge_chance: float = 5.0
@export var current_gold: float = 0.0
@export var sprint_stamina_cost_per_second: float = 15.0
@export var stamina_recovery_rate: float = 22.0
@export var stamina_recovery_delay: float = 0.75
@export var speed: float = 25:
	get: 
		var can_sprint = stamina > 0
		return speed * sprinting_multiplier \
			if (can_sprint and is_sprinting) else speed

var is_dead: bool = false
var is_sprinting: bool = false:
	get:
		return is_sprinting
	set(value):
		is_sprinting = value
var stamina_cost := {
	"roll": 30.0,
	"main_attack": 20.0,
}
var inventory := Inventory.new(4)
var stamina_controller := StaminaController.new()
var current_interactable: Interactable
var stamina_recovery_timer := 0.0
var health: float
var stamina: float = 0.0:
	get:
		return stamina
	set(value):
		stamina = clamp(value, 0, max_stamina)
		update_stamina.emit()
var last_leaved_room: Node2D
var current_room: Node2D
var position_on_last_room := Vector2.ZERO

func consume_stamina(amount: float):
	stamina -= amount
	stamina_recovery_timer = stamina_recovery_delay

const SWORD_COLLIDER_OFFSET = 35
const RAYCAST_OFFSET = 20
const PLAYER_ATTACK_OFFSET = 20
const PLAYER_COLLIDER_X = 0

enum State {
	IDLE,
	WALKING,
	RUNNING,
	ATTACKING,
	ROLLING,
}

var state := State.	IDLE

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.95, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.15
	draw_circle(Vector2.DOWN * 25, 10, shadow_color)
	
func die():
	is_dead = true
	$AnimatedSprite2D.play("death")
	if $RunningSound.playing:
		$RunningSound.stop()
		
	await $AnimatedSprite2D.animation_finished
	await get_tree().create_timer(0.5).timeout
	player_dead.emit()
	
	
func _ready():
	$Camera2D.zoom = Vector2(8, 8)
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_changed.connect(_on_animation_changed)
	health = max_health
	stamina = max_stamina
	
func start(initial_pos: Vector2):
	self.position = initial_pos
	state = State.IDLE
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true

var camera_control_enabled: bool = true

func collect_gold(goldData: ItemData, amount: float):
	current_gold += amount
	inventory.add_item(goldData, amount)
	var label := MessageLabel.new()
	var gold_message = "+%d" % int(amount)
	animate_message_label(gold_message, FloatingTextConfigs.GOLD_COLLECTED)
	
	
func handle_mouse_event(event: InputEventMouseButton) -> void:
	if event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if camera_control_enabled:
					var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
					if new_zoom <= Vector2(8, 8): 
						$Camera2D.zoom = new_zoom
			MOUSE_BUTTON_WHEEL_DOWN:
				if camera_control_enabled:
					var new_zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
					if new_zoom >= Vector2(0.5, 0.5):	
						$Camera2D.zoom = new_zoom
			MOUSE_BUTTON_LEFT:

				if not state == State.ATTACKING:
					if stamina > stamina_cost["main_attack"]:
						_attack()
					else:
						show_no_stamina_message()

func handle_keyboard_event(event: InputEventKey) -> void:
	if event.is_action_pressed("interact"):
		if current_interactable:
			current_interactable.interact(self)
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handle_mouse_event(event)
	if event is InputEventKey:
		handle_keyboard_event(event)

func _attack():
	state = State.ATTACKING
	
func is_stopped() -> bool:
	return velocity == Vector2.ZERO
		
func _physics_process(delta: float) -> void:
	if is_dead:
		return
				
	if Input.is_action_just_pressed("roll"):
		_start_roll()
	
	if Input.is_action_pressed("sprint"):
		if not is_sprinting:
			is_sprinting = true
			state = State.RUNNING
	elif Input.is_action_just_released("sprint"):
			is_sprinting = false
			state = State.IDLE
		
		
	match state:
		State.ATTACKING:
			return
		State.ROLLING:
			move_and_slide()
			return 
			
		_:
			var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if direction != Vector2.ZERO:
				raycast.target_position.x += -RAYCAST_OFFSET if direction.x > 0 else RAYCAST_OFFSET
				raycast.target_position = direction * 30

				
			velocity = direction * speed
			update_flip(direction)
			move_and_slide()


func _start_roll():
	if stamina < stamina_cost["roll"]:
		show_no_stamina_message()
		return
		
	state = State.ROLLING
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if is_facing_left() else Vector2.RIGHT
		
	update_flip(direction)
	velocity = direction * speed * roll_speed_multiplier
	consume_stamina(stamina_cost["roll"])
	
func _process(delta: float) -> void:
	if is_dead:
		return
	
	if (state == State.ROLLING or state == State.ATTACKING) \
		and $RunningSound.playing:
		$RunningSound.stop()
	
	if is_sprinting:
		consume_stamina(sprint_stamina_cost_per_second * delta)
	else:
		if stamina_recovery_timer > 0:
			stamina_recovery_timer -= delta
		else:
			stamina += stamina_recovery_rate * delta
	
	match state:
		State.ROLLING, State.ATTACKING:
			pass
		_:
			if velocity == Vector2.ZERO:
				state = State.IDLE
				$RunningSound.stop()
			else:
				if is_sprinting:
					state = State.RUNNING
				else:
					state = State.WALKING
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
		$AnimatedSprite2D.flip_h = false
	elif direction.x < 0:
		if is_facing_right():
			$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
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
		State.WALKING:
			return "walk"
		State.RUNNING:
			return "run"
		State.ROLLING:
			return "roll"
		_:
			return "idle"
			
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "roll":
		state = State.IDLE
		
	if $AnimatedSprite2D.animation == "attack":
		state = State.IDLE
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", true)
 
func take_damage(damage: float):
	if state == State.ROLLING:
		if (randf() * 100) < dodge_chance:
			animate_message_label("DODGE!", FloatingTextConfigs.MESSAGE)
			return
		
	if is_dead: 
		return
		
	health -= damage
	damage_taken.emit()
	animate_message_label(str(damage), FloatingTextConfigs.NORMAL_DAMAGE)
	
	if health <= 0:
		die()
		return


func _on_animation_changed():
	if state != State.ATTACKING and not $SwordArea/CollisionShape2D.disabled:
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", true)
		
func _on_frame_changed():
	if state == State.ATTACKING and $AnimatedSprite2D.frame == 2:
		consume_stamina(stamina_cost["main_attack"])
		if not $SwordAttackSound.playing:
			AudioManager.play_sfx($SwordAttackSound.stream)
		$SwordArea/CollisionShape2D.call_deferred("set_disabled", false)

func show_no_stamina_message():
	animate_message_label("NO STAMINA!", FloatingTextConfigs.WARNING_MESSAGE)

func animate_message_label(text: String, config: FloatingTextConfig):
	var label := MessageLabel.new()
	add_child(label)
	label.setup(text, config)
	TweenManager.animate_floating_label(label)
	
func enter_interectable(interactable: Interactable):
	current_interactable = interactable

func exit_interactable(interactable: Interactable):
	if current_interactable == interactable:
		current_interactable = null

func enter_room(room: Node2D, spawn_position: Vector2):
	room_change_requested.emit(room, spawn_position)
