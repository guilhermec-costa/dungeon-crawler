extends CharacterBody2D

class_name BaseEnemy

const MESSAGE_LABEL_SCENE := preload("res://scenes/UI/message_label.tscn")

@export var config: EnemyData
@export var player: Player
@export var right_offset := Vector2.ZERO
@export var left_offset := Vector2.ZERO
@onready var health_bar: HealthBar = $HealthBar
@onready var pathfinder: NavigationAgent2D = $NavigationAgent2D
@onready var start_chase_area: Area2D = $StartChaseArea
@onready var limit_chase_area: Area2D = $LimitChaseArea

var dash_controller: DashBehavior
var health: float
var walk_direction := Vector2.ZERO
var spawn_origin: Vector2
var state: State = State.IDLE
var hit_window_open := false

var attack_on_progress := false
var attack_timer := 0.0
var current_attack: AttackConfig
var attacks: Array[AttackConfig]

enum State {
	IDLE,
	ATTACKING,
	CHASING,
	PATROLLING,
	DEAD,
	RETURNING_SPAWN_ORIGIN,
	TAKING_DAMAGE
}

func change_state(new_state: State) -> void:
	if state == State.DEAD:
		return
	
	if state == State.ATTACKING and new_state == State.TAKING_DAMAGE:
		if randf() >= config.cancel_attack_on_damage_chance:
			return
		
	state = new_state

	
func create_patrol_circle():
	var patrol_circle := DebugPatrolCircle.new()
	patrol_circle.radius = config.patrol_radius
	patrol_circle.global_position = global_position
	patrol_circle.top_level = true
	add_child(patrol_circle)
	
func _ready():
	add_to_group("enemies")
	spawn_origin = global_position
	dash_controller = DashBehavior.new(
		config.dash_chance,
		config.dash_force,
		config.dash_duration,
		config.dash_cooldown
	)
	
	if OS.has_feature("patrol_radius"):
		create_patrol_circle()
	
	health = config.max_health
	health_bar.max_value = config.max_health
	health_bar.set_health_bar_value(config.max_health)

	$CollisionShape2D.disabled = false

	start_chase_area.body_entered.connect(_on_chase_area_body_entered)
	limit_chase_area.body_exited.connect(_on_limit_chase_area_body_exited)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AttackRange.body_entered.connect(on_enter_attack_range)
	$AttackRange.body_exited.connect(on_exit_attack_range)

	$WalkTimer.timeout.connect(_on_walk_timer_timeout)
	$WalkTimer.wait_time = config.idle_duration
	$WalkTimer.start()


func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, config.shadow_scale)

	var color := Color.BLACK
	color.a = config.shadow_alpha

	draw_circle(config.shadow_offset, config.shadow_radius, color)

func is_facing_left() -> bool:
	return $AnimatedSprite2D.flip_h

func is_facing_right() -> bool:
	return not $AnimatedSprite2D.flip_h

func flip_to_left():
	if not $AnimatedSprite2D.flip_h:
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.offset = left_offset
		on_flip_left()

func flip_to_right():
	if $AnimatedSprite2D.flip_h:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.offset = right_offset
		on_flip_right()

func on_flip_left() -> void:
	pass

func on_flip_right() -> void:
	pass
	
func update_flip_based_on_player_position():
	if not is_instance_valid(player):
		return
		
	var pos_diff = player.global_position.x - global_position.x
	if abs(pos_diff) > 5:
		if pos_diff < 0:
			flip_to_left()
		else:
			flip_to_right()

func update_flip_based_on_velocity():
	if velocity.x > 0:
		flip_to_right()
	elif velocity.x < 0:
		flip_to_left()


func _chase_player():
	var target = player.global_position
	target.x += 5 if is_facing_left() else -5

	pathfinder.target_position = target

	var next_pos = pathfinder.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * config.speed


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	if state == State.CHASING or state == State.ATTACKING:
		update_flip_based_on_player_position()
	elif state == State.PATROLLING:
		update_flip_based_on_velocity()

	if global_position.distance_to(spawn_origin) < 8 and state == State.RETURNING_SPAWN_ORIGIN:
		change_state(State.PATROLLING)
		
	if player and state == State.CHASING:
		_chase_player()
	elif state == State.RETURNING_SPAWN_ORIGIN:
		pathfinder.target_position = spawn_origin
		if pathfinder.is_navigation_finished():
			change_state(State.PATROLLING)
			return
		
		var next_pos = pathfinder.get_next_path_position()
		var return_direction = global_position.direction_to(next_pos)
		velocity = return_direction * config.speed_on_random_walk
		
	elif state == State.PATROLLING:
		if global_position.distance_to(spawn_origin) >= config.patrol_radius:
			walk_direction = (spawn_origin - global_position).normalized()

		velocity = walk_direction * config.speed_on_random_walk
	elif state == State.IDLE or state == State.ATTACKING:
		velocity = Vector2.ZERO
	
	process_special_movement(delta)
	move_and_slide()

func process_special_movement(delta: float) -> void:
	pass

func _process(_delta: float) -> void:
	if state == State.DEAD:
		return
	
	if state == State.ATTACKING:
		process_attack(_delta)
	else:
		update_animation(get_animation_from_state())

func process_attack(delta: float):
	if attack_on_progress:
		return

	attack_timer -= delta

	if attack_timer > 0:
		return

	start_attack()

func start_attack():
	attack_on_progress = true
	current_attack = attacks.pick_random()
	$AnimatedSprite2D.play(current_attack.animation_name)
	attack_timer = randf_range(
		current_attack.attack_interval_min,
		current_attack.attack_interval_max
	)
	
func get_animation_from_state() -> String:
	match state:
		State.IDLE:
			return "idle"
		State.CHASING, State.PATROLLING:
			return "walk"
		State.TAKING_DAMAGE:
			return "take_damage"
		_:
			return ""

func update_animation(animation: String):
	if animation.is_empty():
		return

	if animation != $AnimatedSprite2D.animation or !$AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(animation)

func _on_animation_finished():
	current_attack = null
	attack_on_progress = false
		
func show_damage_label(damage: float, type: DamageTypes.Type):
	var label: MessageLabel = MESSAGE_LABEL_SCENE.instantiate()
	add_child(label)
	match type:
		DamageTypes.Type.NORMAL:
			label.setup(str(damage), FloatingTextConfigs.NORMAL_DAMAGE)
		DamageTypes.Type.CRITICAL:
			label.setup(str(damage), FloatingTextConfigs.CRITICAL_DAMAGE)

	TweenManager.animate_floating_label(label)

func take_damage(damage: float, type: DamageTypes.Type) -> void:
	var previous_state = state
	
	change_state(State.TAKING_DAMAGE)
	if config.resistence != 0:
		damage = max(0.0, damage * (1.0 - config.resistence))

	health -= damage
	if health <= 0:
		die()
		return

	$HealthBar.set_health_bar_value(health)
	show_damage_label(damage, type)
	
	if state != State.TAKING_DAMAGE:
		# the attack was not cancelled
		return
		
	attack_on_progress = false
	current_attack = null
	
	$AnimatedSprite2D.play("take_damage")
	await $AnimatedSprite2D.animation_finished
	
	if state == State.TAKING_DAMAGE:
		# nothing change, can restore
		state = previous_state
		update_animation(get_animation_from_state())

func die():
	$HealthBar.hide_health_ui()
	change_state(State.DEAD)
	if $DieSound:
		AudioManager.play_sfx($DieSound.stream)
		
	$AnimatedSprite2D.play("die")

	await $AnimatedSprite2D.animation_finished

	queue_free()

func _on_frame_changed() -> void:
	pass

var attack_range_exit_id := 0

func on_enter_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
	
	if body is Player:
		attack_range_exit_id += 1  # invalid pending corroutines
		change_state(State.ATTACKING)
		attack_timer = 0
		$WalkTimer.stop()

func on_exit_attack_range(body: Node2D) -> void:
	if state == State.DEAD:
		return
	
	if not body is Player:
		return
	
	attack_range_exit_id += 1
	var my_id = attack_range_exit_id
	
	if state == State.ATTACKING and attack_on_progress:
		await $AnimatedSprite2D.animation_finished
	
	if my_id != attack_range_exit_id:
		return
	
	if state == State.DEAD:
		return
	
	current_attack = null
	attack_on_progress = false
	
	if $AttackRange.has_overlapping_bodies():
		change_state(State.ATTACKING)
		attack_timer = 0
	else:
		change_state(State.CHASING)

func _on_chase_area_body_entered(body: Node2D) -> void:
	if body is Player:
		change_state(State.CHASING)
		$WalkTimer.stop()

func _on_limit_chase_area_body_exited(body: Node2D) -> void:
	if body is Player:
		change_state(State.RETURNING_SPAWN_ORIGIN)
		$WalkTimer.wait_time = config.idle_duration
		$WalkTimer.start()

func _on_walk_timer_timeout():
	if state == State.ATTACKING:
		return
		
	if state == State.IDLE:
		change_state(State.PATROLLING)
		walk_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		$WalkTimer.wait_time = config.walk_duration
		$WalkTimer.start()
	elif state == State.PATROLLING:
		change_state(State.IDLE)
		velocity = Vector2.ZERO
		$WalkTimer.wait_time = config.idle_duration
		$WalkTimer.start()

func drop_item():
	DropManager.spawn(
		config.drop_id_on_death,
		config.drop_amount_on_death,
		global_position,
		get_parent(),
		player.z_index
	)
	
func is_on_hit_frame():
	if current_attack:
		return $AnimatedSprite2D.frame == current_attack.attack_hit_frame

func is_on_frame(frame: int):
	return $AnimatedSprite2D.frame == frame
