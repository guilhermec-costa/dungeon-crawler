extends CharacterBody2D

class_name BaseEnemy

# Stats
@export var walk_duration: float = 2.0
@export var idle_duration: float = 1.5
@export var speed: float = 45.0
@export var speed_on_random_walk: float = 25.0
@export var max_health: float
@export var resistence: float
@export var damage_given: float


@onready var health_bar: HealthBar = $HealthBar
@onready var pathfinder: NavigationAgent2D = $NavigationAgent2D
@onready var start_chase_area: Area2D = $StartChaseArea
@onready var limit_chase_area: Area2D = $LimitChaseArea

var health: float
@export var player: Player
var walk_direction := Vector2.ZERO

enum State {
	IDLE,
	ATTACKING,
	CHASING,
	WALKING,
	DEAD
}

var state: State = State.IDLE

# Preloads
var damageTakenLabel: PackedScene = preload("res://scenes/damage_label.tscn")

# --- Overrideable ---

# animation frame that applies DAMAGE on attack
var attack_hit_frame: int = 0

# cadaver scene
var postmortem_scene: PackedScene = null


func _ready():
	add_to_group("enemies")
	health = max_health
	health_bar.max_value = max_health
	health_bar.set_health_bar_value(max_health)

	$CollisionShape2D.disabled = false

	start_chase_area.body_entered.connect(_on_chase_area_body_entered)
	limit_chase_area.body_exited.connect(_on_limit_chase_area_body_exited)

	$WalkTimer.timeout.connect(_on_walk_timer_timeout)
	$WalkTimer.wait_time = idle_duration
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
	target.y += 16
	target.x += 20 if is_facing_left() else -20

	pathfinder.target_position = target

	var next_pos = pathfinder.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * speed


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if state == State.CHASING or state == State.ATTACKING:
		update_flip_based_on_player_position()
	elif state == State.WALKING:
		update_flip_based_on_velocity()

	if player and state == State.CHASING:
		_chase_player()
	elif state == State.WALKING:
		velocity = walk_direction * speed_on_random_walk
	elif state == State.IDLE or state == State.ATTACKING:
		velocity = Vector2.ZERO

	move_and_slide()


# --- Animation ---

func _process(_delta: float) -> void:
	if state == State.DEAD:
		return
		
	update_animation(get_animation_from_state())

func get_animation_from_state() -> String:
	match state:
		State.IDLE:
			return "idle"
		[State.CHASING, State.WALKING]:
			return "walk"
		State.ATTACKING:
			return "attack"
		_:
			return "walk"

func update_animation(new_animation: String):
	if new_animation != $AnimatedSprite2D.animation or not $AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play(new_animation)


# --- Combat ---

func show_damage_label(damage: float, type: DamageTypes.Type):
	var damage_label: TweenMessage = damageTakenLabel.instantiate()
	add_child(damage_label)

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
	damage_label.show_damage_label(damage, 0.7)

func take_damage(damage: float, type: DamageTypes.Type) -> void:
	if resistence != 0:
		damage = max(0, damage * resistence / 100)

	health -= damage
	if health <= 0:
		die()
		return

	$HealthBar.set_health_bar_value(health)
	show_damage_label(damage, type)

	$AnimatedSprite2D.play("take_damage")
	await $AnimatedSprite2D.animation_finished
	update_animation(get_animation_from_state())

func spawn_dead_corpse():
	if postmortem_scene == null:
		return
	var corpse = postmortem_scene.instantiate()
	corpse.global_position = global_position
	get_parent().add_child(corpse)
	var despawn_timer = corpse.get_tree().create_timer(10)
	despawn_timer.timeout.connect(corpse.on_despawn_timer_timeout)

func die():
	$HealthBar.hide_health_ui()
	state = State.DEAD
	if $DieSound:
		$DieSound.play()
		
	$AnimatedSprite2D.play("die")

	await $AnimatedSprite2D.animation_finished

	spawn_dead_corpse()
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
		state = State.CHASING
		$WalkTimer.stop()

func _on_limit_chase_area_body_exited(body: Node2D) -> void:
	if body is Player:
		state = State.IDLE
		$WalkTimer.wait_time = idle_duration
		$WalkTimer.start()

func _on_walk_timer_timeout():
	if state == State.ATTACKING:
		return
	if state == State.IDLE:
		state = State.WALKING
		walk_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		$WalkTimer.wait_time = walk_duration
		$WalkTimer.start()
	elif state == State.WALKING:
		state = State.IDLE
		velocity = Vector2.ZERO
		$WalkTimer.wait_time = idle_duration
		$WalkTimer.start()
