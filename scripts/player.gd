extends Area2D

var DEFAULT_SCALE: Vector2 = Vector2(1.0, 1.0)

func start(initial_pos: Vector2, initial_scale: Vector2 = DEFAULT_SCALE):
	self.position = initial_pos
	self.scale = initial_scale
	$AnimatedSprite2D.animation = "idle"

const SPEED = 400
var moving: bool = false
var attacking: bool = false
			
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index ==  MOUSE_BUTTON_LEFT and event.pressed:
			attacking = true
			$AnimatedSprite2D.animation = "attack"
			
			
func _process(delta: float) -> void:
	var velocity = Vector2(0, 0)
	moving = false
	if Input.is_action_pressed("move_right"):
		$AnimatedSprite2D.flip_h = false
		velocity = Vector2(1.0, 0.0)
		moving = true
	if Input.is_action_pressed("move_left"):
		$AnimatedSprite2D.flip_h = true
		velocity = Vector2(-1.0, 0.0)
		moving = true
	if Input.is_action_pressed("move_up"):
		velocity = Vector2(0.0, -1.0)
		moving = true
	if Input.is_action_pressed("move_down"):
		velocity = Vector2(0.0, 1.0)
		moving = true
	
	if  not moving and not attacking:
		$AnimatedSprite2D.animation = "idle"
		
	if moving and not attacking:
		$AnimatedSprite2D.animation = "run"
		
	$AnimatedSprite2D.play()
	position += velocity * SPEED * delta


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "attack":
		attacking = false
