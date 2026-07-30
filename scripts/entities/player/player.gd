extends CharacterBody2D

class_name Player

signal player_dead
signal damage_taken
signal update_stats
signal room_change_requested(room: Node2D, spawn_position: Vector2)
signal initialized

const MESSAGE_LABEL_SCENE := preload("res://scenes/UI/message_label.tscn")

@onready var running_sound: AudioStreamPlayer2D = $RunningSound
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamageSound
@onready var drink_potion_life: AudioStreamPlayer2D = $PotionDrinkSound
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast2D = $CollisionRay
@onready var animated_sprite: PlayerAnimatedSprite = $AnimatedSprite2D
@onready var sword_area: SwordArea = $SwordArea
@export var config: PlayerConfig
@export var initial_items: Dictionary[ItemData, int]
@export var game_items: GameItems


var current_attack: AttackConfig
var target_recovery_health: float = 0
var recover_life_window: bool = false
var last_attack_time: float = Time.get_unix_time_from_system()

var attacks: Array[AttackConfig]

var speed: float:
	get: 
		var can_sprint = stamina > 0
		return config.base_speed * (
			config.sprinting_multiplier if can_sprint and is_sprinting else 1.0
		)

var is_sprinting: bool = false:
	get:
		return is_sprinting and velocity.length() > 0
	set(value):
		is_sprinting = value
		
var stamina_cost := {
	"roll": 30.0
}

var inventory := Inventory.new(5)
var current_interactable: Interactable

var stamina_recovery_timer := 0.0
var health: float:
	get:
		return health
	set(value):
		health = clamp(value, 0, config.max_health)
		update_stats.emit()
var stamina: float = 0.0:
	get:
		return stamina
	set(value):
		stamina = clamp(value, 0, config.max_stamina)
		update_stats.emit()
		
var last_leaved_room: Node2D
var current_room: Node2D
var position_on_last_room := Vector2.ZERO
const RAYCAST_OFFSET = 20
const PLAYER_COLLIDER_X = 0
	
func start(start_position: Vector2):
	global_position = start_position
	change_state(State.IDLE)
	sword_area.set_disabled(true)
	
func consume_stamina(amount: float):
	stamina -= amount
	stamina_recovery_timer = config.stamina_recovery_delay

enum State {
	IDLE,
	WALKING,
	RUNNING,
	ATTACKING,
	ROLLING,
	CUTSCENE,
	DEAD
}

var state := State.	IDLE


func change_state(new_state: State):
	if state == new_state:
		return

	if state == State.DEAD:
		return
		
	if state == State.CUTSCENE:
		set_process_input(true)
		
	if new_state == State.CUTSCENE:
		set_process_input(false)
		
	if new_state == State.DEAD:
		running_sound.stop()
		walk_sound.stop()
	
	if new_state == State.WALKING:
		running_sound.stop()
		is_sprinting = false

	if new_state == State.RUNNING:
		walk_sound.stop()
		is_sprinting = true
	
	if new_state == State.IDLE:
		is_sprinting = false
		
	state = new_state

func die():
	change_state(State.DEAD)
	animated_sprite.play("death")
	running_sound.stop()

	await animated_sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	player_dead.emit()


func _ready():
	$Camera2D.zoom = Vector2(6.2, 6.2)
	attacks = [
		AttackConfig.new("attack1", config.attack_1_damage, 10, 3, 4),
		AttackConfig.new("attack2", config.attack_2_damage, 15, 3, 4)
	]
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_changed.connect(_on_animation_changed)
	animated_sprite.setup(sword_area)
	health = config.start_health
	target_recovery_health = config.start_health
	stamina = config.max_stamina
	
	for item in initial_items.keys():
		inventory.add_item(item, initial_items[item])
		
	initialized.emit()	

func collect_item(item: ItemData, amount: float) -> void:
	inventory.add_item(item, amount)
	var label: MessageLabel = MESSAGE_LABEL_SCENE.instantiate()
	if item.collect_sound:
		AudioManager.play_sfx(item.collect_sound)
	
func handle_mouse_event(event: InputEventMouseButton) -> void:
	if event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if OS.has_feature("camera_control_enabled"):
					var new_zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
					if new_zoom <= Vector2(8, 8): 
						$Camera2D.zoom = new_zoom
			MOUSE_BUTTON_WHEEL_DOWN:
				if OS.has_feature("camera_control_enabled"):
					var new_zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
					if new_zoom >= Vector2(0.5, 0.5):	
						$Camera2D.zoom = new_zoom
			MOUSE_BUTTON_LEFT:
				if not state == State.ATTACKING:
					_attack()

func handle_keyboard_event(event: InputEventKey) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		current_interactable.interact(self)
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handle_mouse_event(event)
	if event is InputEventKey:
		handle_keyboard_event(event)

func _attack():
	var next_attack = choose_random_attack()
	if stamina > next_attack.stamina_cost:
		current_attack = next_attack
		change_state(State.ATTACKING)
	else:
		show_no_stamina_message()

func is_stopped() -> bool:
	return velocity == Vector2.ZERO
		
func in_processable_state() -> bool:
	return state != State.CUTSCENE and state != State.DEAD

func in_movement_state() -> bool:
	return state == State.RUNNING or state == State.WALKING
	
func _physics_process(delta: float) -> void:
	if not in_processable_state():
		return
				
	if Input.is_action_just_pressed("roll"):
		_start_roll()
		
	if state != State.ROLLING and state != State.ATTACKING:
		if Input.is_action_pressed("sprint"):
			change_state(State.RUNNING)
		elif Input.is_action_just_released("sprint"):
			change_state(State.IDLE)
		
		
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
			animated_sprite.update_flip(direction)
			move_and_slide()


func _start_roll():
	if stamina < stamina_cost["roll"]:
		show_no_stamina_message()
		return
	
	change_state(State.ROLLING)
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if animated_sprite.is_facing_left() else Vector2.RIGHT
		
	animated_sprite.update_flip(direction)
	velocity = direction * speed * config.roll_speed_multiplier
	consume_stamina(stamina_cost["roll"])

func handle_sprinting(delta: float) -> void:		
	if is_sprinting:
		consume_stamina(config.sprint_stamina_cost_per_second * delta)
	else:
		if stamina_recovery_timer > 0:
			stamina_recovery_timer -= delta
		else:
			stamina += config.stamina_recovery_rate * delta

func handle_life_recovering(delta: float) -> void:
	if not recover_life_window:
		return
		
	if health < target_recovery_health:
		health += config.life_recovery_rate * delta	
	else:
		target_recovery_health = 0
		recover_life_window = false
			
func _process(delta: float) -> void:
	if not in_processable_state():
		return
	
	if not in_movement_state():
		walk_sound.stop()
		running_sound.stop()
	
	handle_sprinting(delta)
	handle_life_recovering(delta)

	match state:
		State.ROLLING, State.ATTACKING:
			pass
		_:
			if velocity == Vector2.ZERO:
				change_state(State.IDLE)
				running_sound.stop()
			else:
				if is_sprinting and stamina > 0:
					change_state(State.RUNNING)
					if not running_sound.playing:
						running_sound.play()
				else:
					change_state(State.WALKING)
					if not walk_sound.playing:
						walk_sound.play()
	
	animated_sprite.update_animation(get_animation_from_state())
		
func get_animation_from_state() -> String:
	match state:
		State.IDLE:
			return "idle"
		State.ATTACKING:
			return current_attack.animation_name
		State.ROLLING:
			return "roll"
		State.WALKING:
			return "walk"
		State.RUNNING:
			return "run"
		_:
			return "idle"
			
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "roll":
		change_state(State.IDLE)
		
	if animated_sprite.animation == "attack1" \
	or animated_sprite.animation == "attack2":
		change_state(State.IDLE)
		sword_area.set_disabled(true)
 
func take_damage(damage: float):
	if not in_processable_state():
		return
		
	if state == State.ROLLING:
		if randf()  < config.dodge_chance:
			animate_message_label("DODGE!", FloatingTextConfigs.DODGE_MESSAGE)
			return
		
	health -= damage
	take_damage_sound.play()
	damage_taken.emit()
	animation_player.play("hurt")
	animate_message_label(str(damage), FloatingTextConfigs.NORMAL_DAMAGE)
	
	if health <= 0:
		die()
		return
		
func _on_animation_changed():
	if state != State.ATTACKING and not sword_area.is_disabled():
		sword_area.set_disabled(true)

func choose_random_attack():
	return attacks.pick_random()

func get_next_attack_time():
	var variation_time = randf_range(0.5, 2.5)
	return last_attack_time + variation_time

func _on_frame_changed():
	if state == State.ATTACKING:
		if animated_sprite.frame == current_attack.attack_hit_frame:
			consume_stamina(current_attack.stamina_cost)
			last_attack_time = Time.get_unix_time_from_system()
			if not $SwordAttackSound.playing:
				AudioManager.play_sfx($SwordAttackSound.stream)
			sword_area.set_disabled(false)
		
		if animated_sprite.frame == 4:
			sword_area.set_disabled(true)

func show_no_stamina_message():
	animate_message_label("NO STAMINA!", FloatingTextConfigs.WARNING_MESSAGE)

func animate_message_label(text: String, config: FloatingTextConfig):
	var label: MessageLabel = MESSAGE_LABEL_SCENE.instantiate()
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
	
func play_cutscene_animation(name: String):
	change_state(State.CUTSCENE)
	
	animation_player.play(name)
	await animation_player.animation_finished

func recover_health() -> void:
	target_recovery_health = min(
		health + config.life_potion_recovery_amount,
		config.max_health
	)
	var recovered_health := target_recovery_health - health
	var label = "+%d" % int(round(recovered_health))
	recover_life_window = true
	drink_potion_life.play()
	animate_message_label(label, FloatingTextConfigs.LIFE_RECOVERED)
	
func _on_item_consume(item: ItemData, quantity: int = 1) -> void:
	inventory.consume_item(item, quantity)
	match item.id:
		ItemData.ItemID.LIFE_POTION:
			recover_health()

func get_current_attack_damage() -> float:
	return current_attack.damage
