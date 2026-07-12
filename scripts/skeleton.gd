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
var postmortenScene: PackedScene = preload("res://scenes/decorations/skeleton_postmorten.tscn")
	
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

var stuck_timer: float = 0.0
var stuck_direction: Vector2 = Vector2.ZERO
var unstuck_timer: float = 0.0

	
#func _on_velocity_computed(safe_velocity: Vector2):
	#print("computed")
	#velocity = safe_velocity
	
#func _chase_player():
	#var player_pos = player.global_position
	#pathfinder.target_position = player_pos
	#
	#var next_pos = pathfinder.get_next_path_position()
	#var direction = global_position.direction_to(next_pos)
	#pathfinder.velocity = direction * speed
	#
	
#func _chase_player():	
	#var player_pos = player.global_position
	#pathfinder.target_position = player_pos
	#
	#if unstuck_timer > 0:
		#velocity = stuck_direction * speed
		#return
	#
	#var next_pos = pathfinder.get_next_path_position()
	#var direction = global_position.direction_to(next_pos)
	#velocity = direction * speed
	#
	
func is_facing_left():
	return $AnimatedSprite2D.flip_h
	
func is_facing_right():
	return not $AnimatedSprite2D.flip_h
	
func _chase_player():	
	var target = player.global_position
	target.y += 16
	target.x += 20 if is_facing_left() else -20

	pathfinder.target_position = target
	
	var next_pos = pathfinder.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
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
	
	# TODO lógica de desbloquear em aprede
	#if state == State.CHASING:
		#if get_slide_collision_count() > 0:
			#stuck_timer += delta
			#if stuck_timer > 0.3:
				#var dir = global_position.direction_to(player.global_position)
				#stuck_direction = dir.rotated(PI / 3) * (1 if randi() % 2 == 0 else -1)
				#unstuck_timer = 0.2
				#stuck_timer = 0.0
		#else:
			#stuck_timer = 0.0
		#
		#if unstuck_timer > 0:
			#unstuck_timer -= delta
	#

func _process(delta: float) -> void:
	if is_dead: 
		return
	
	var animation = get_animation_from_state()
	update_animation(animation)

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

func spawn_dead_corpse():
	var corpse: SkeletonPostmorten = postmortenScene.instantiate()
	corpse.global_position = global_position
	
	get_parent().add_child(corpse)
	var despawn_timer = corpse.get_tree().create_timer(10)
	despawn_timer.timeout.connect(corpse.on_despawn_timer_timeout)
	
func die():
	$HealthBar.hide_health_ui()
	is_dead = true
	$DieSound.play()
	$AnimatedSprite2D.play("die")
	
	await $AnimatedSprite2D.animation_finished
	
	spawn_dead_corpse()
	queue_free()
	


func show_damage_label(damage: float, type: DamageTypes.Type):
	var damage_label: DamageLabel = damageTakenLabel.instantiate()
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
