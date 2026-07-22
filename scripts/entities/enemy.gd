extends CharacterBody2D

class_name BaseEnemy

var gold_scene: PackedScene = preload("res://scenes/gold_drop.tscn")

@export var config: EnemyData
@export var player: Player

@onready var health_bar: HealthBar = $HealthBar
@onready var pathfinder: NavigationAgent2D = $NavigationAgent2D
@onready var start_chase_area: Area2D = $StartChaseArea
@onready var limit_chase_area: Area2D = $LimitChaseArea

var dash_controller: DashBehavior

var health: float
var walk_direction := Vector2.ZERO
var spawn_origin: Vector2
var state: State = State.IDLE
var attack_hit_frame: int = 0

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

	$WalkTimer.timeout.connect(_on_walk_timer_timeout)
	$WalkTimer.wait_time = config.idle_duration
	$WalkTimer.start()


func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 50, 10, shadow_color)


# --- Flip ---

func is_facing_left() -> bool:
	return $AnimatedSprite2D.flip_h

func is_facing_right() -> bool:
	return not $AnimatedSprite2D.flip_h

func flip_to_left():
	if not $AnimatedSprite2D.flip_h:
		$AnimatedSprite2D.flip_h = true
		on_flip_left()

func flip_to_right():
	if $AnimatedSprite2D.flip_h:
		$AnimatedSprite2D.flip_h = false
		on_flip_right()

# virtuals
func on_flip_left() -> void:
	pass

func on_flip_right() -> void:
	pass

# -----

func update_flip_based_on_player_position():
	if not is_instance_valid(player):
		return
	var pos_diff = player.position.x - position.x
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


# --- Movement ---

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

# --- Animation ---

func _process(_delta: float) -> void:
	if state == State.DEAD:
		return
		
	update_animation(get_animation_from_state())

func get_animation_from_state() -> String:
	match state:
		State.IDLE:
			return "idle"
		State.CHASING, State.PATROLLING:
			return "walk"
		State.ATTACKING:
			return "attack"
		State.TAKING_DAMAGE:
			return "take_damage"
		_:
			return "walk"

func update_animation(new_animation: String):
	if new_animation != $AnimatedSprite2D.animation or not $AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(new_animation)


# --- Combat ---

func show_damage_label(damage: float, type: DamageTypes.Type):
	var damage_label := Label.new()
	add_child(damage_label)
	
	damage_label.z_index = 10
	damage_label.position = Vector2(0, -20)
	damage_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	match type:
		DamageTypes.Type.NORMAL:
			damage_label.modulate = Color.WHITE
		DamageTypes.Type.CRITICAL:
			damage_label.modulate = Color(1.0, 0.85, 0.0)

	damage_label.add_theme_font_size_override("font_size", 18)
	damage_label.add_theme_constant_override("outline_size", 3)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	TweenManager.animate_floating_label(damage_label, str(damage), 0.7)

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
	
	$AnimatedSprite2D.play("take_damage")
	await $AnimatedSprite2D.animation_finished
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


# --- Signals ---

func _on_frame_changed() -> void:
	pass

func on_enter_attack_range(body: Node2D) -> void:
	pass

func on_exit_attack_range(body: Node2D) -> void:
	pass

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
		
func drop_gold():
	var _gold_scene: GoldDrop = gold_scene.instantiate()
	_gold_scene.global_position = global_position
	_gold_scene.z_index = player.z_index - 1
	_gold_scene.gold_amount = config.gold_drop_amount_on_death
	get_parent().add_child(_gold_scene)
	
func is_on_hit_frame():
	return $AnimatedSprite2D.frame == attack_hit_frame

func is_on_frame(frame: int):
	return $AnimatedSprite2D.frame == frame
