extends CharacterBody2D

class_name BaseSkeleton
@export var walk_duration: float = 2.0
@export var idle_duration: float = 1.5
var walk_direction := Vector2.ZERO
var walk_timer: float = 0.0

@export var speed: float = 45.0
@export var speed_on_random_walk: float = 25.0
@export var max_health: float;
@export var resistence: float
@export var damage_given: float;
@onready var health_bar: HealthBar = $HealthBar
@onready var pathfinder: NavigationAgent2D = $NavigationAgent2D
@onready var start_chase_area: Area2D = $StartChaseArea
@onready var limit_chase_area: Area2D = $LimitChaseArea

var health: float
var SWORD_COLLIDER_OFFSET = 50.0

# STATE DATA
var player: Player
var is_dead: bool = false

enum State {
	IDLE,
	ATTACKING,
	CHASING,
	WALKING
}

var state: State = State.IDLE
var damageTakenLabel: PackedScene = preload("res://scenes/damage_label.tscn")

	
func _ready():
	walk_timer = idle_duration
	add_to_group("skeletons")
	health = max_health
	health_bar.max_value = max_health
	health_bar.set_health_bar_value(max_health)
	
	$CollisionShape2D.disabled = false
	$SwordArea.monitoring = true
	$SwordArea/CollisionShape2D.disabled = true
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	
	start_chase_area.body_entered.connect(_on_chase_area_body_entered)
	limit_chase_area.body_exited.connect(_on_limit_chase_area_body_exited)
	
	$WalkTimer.timeout.connect(_on_walk_timer_timeout)
	$WalkTimer.start()
	

func _draw():
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	var shadow_color = Color.BLACK
	shadow_color.a = 0.4
	draw_circle(Vector2.DOWN * 50, 10, shadow_color)

func flip_to_left():
	if not $AnimatedSprite2D.flip_h: 
			$SwordArea/CollisionShape2D.position.x -= SWORD_COLLIDER_OFFSET
			$SwordArea/CollisionShape2D.rotation *= -1
	$AnimatedSprite2D.flip_h = true
	
func flip_to_right():
	if $AnimatedSprite2D.flip_h:
		$SwordArea/CollisionShape2D.position.x += SWORD_COLLIDER_OFFSET
		$SwordArea/CollisionShape2D.rotation *= -1
	$AnimatedSprite2D.flip_h = false
	
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
		
func _chase_player():	
	var player_pos = self.player.global_position
	var dir_to_player = (player_pos - global_position).normalized()
	pathfinder.target_position = Vector2(player_pos.x + (-1 if dir_to_player.x > 0 else 1) * 20, player_pos.y + 10)
	var direction = to_local(pathfinder.get_next_path_position()).normalized()
	velocity = direction * speed
			
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if state == State.CHASING or state == State.ATTACKING:
		update_flip_based_on_player_position()
	elif state == State.WALKING:
		update_flip_based_on_velocity()
	
	if player and state == State.CHASING:
		_chase_player()
	elif state == State.WALKING:
		velocity = walk_direction * speed_on_random_walk
	elif state == State.IDLE or pathfinder.is_navigation_finished():
		velocity = Vector2.ZERO
		
	move_and_slide()

func _process(delta: float) -> void:
	if is_dead: 
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
		
func die():
	$HealthBar.hide_health_ui()
	is_dead = true
	$DieSound.play()
	$AnimatedSprite2D.play("die")
	
	await $AnimatedSprite2D.animation_finished
	
	queue_free()

func show_damage_label(damage: float, type: DamageTypes.Type):
	var damageLabel: DamageLabel = damageTakenLabel.instantiate()
	add_child(damageLabel)
	damageLabel.position = Vector2(0, -20)
	damageLabel.texture_filter = 1
	
	if type ==  DamageTypes.Type.NORMAL:
		damageLabel.modulate = Color.YELLOW
	elif type ==  DamageTypes.Type.CRITICAL:
		damageLabel.modulate = Color.RED
		
	damageLabel.add_theme_font_size_override("font_size", 10)
	damageLabel.show_damage_label(damage, 0.7)
	
func take_damage(damage: float, type: DamageTypes.Type) -> void:
	if resistence != 0:
		damage = max(0, damage * resistence/100)
		
	health -= damage	
	if health <= 0:
		die()
		return
	
	$HealthBar.set_health_bar_value(health)
	show_damage_label(damage, type)
	
	$AnimatedSprite2D.play("take_damage")
	await $AnimatedSprite2D.animation_finished
	update_animation(get_animation_from_state())

	
func on_attack_range_body_entered(body: Node2D) -> void:
	if body is Player:
		state = State.ATTACKING
		$SwordArea/CollisionShape2D.disabled = false
		$WalkTimer.stop()

func _on_attack_range_body_exited(body):
	if body is Player:
		state = State.CHASING
		$SwordArea/CollisionShape2D.disabled = true
		
func _on_chase_area_body_entered(body: Node2D):
	if body is Player:
		state = State.CHASING
		$WalkTimer.stop()

func _on_limit_chase_area_body_exited(body: Node2D):
	if body is Player:
		state = State.IDLE
		walk_timer = idle_duration
		$WalkTimer.start()

func _on_frame_changed():
	if state == State.ATTACKING and $AnimatedSprite2D.frame == 5:
		player.take_damage(damage_given)

func _on_walk_timer_timeout():
	if state != State.ATTACKING:
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
