class_name Interactable
extends Area2D


@export var interaction_position := Vector2.ZERO

var interaction_widget: PackedScene = preload("res://scenes/UI/interaction_widget.tscn")
var current_interaction_widget: InteractionWidget


	
func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body is Player:
		body.enter_interectable(self)
		var interaction_widget: InteractionWidget = interaction_widget.instantiate()
		interaction_widget.position = interaction_position
		add_child(interaction_widget)
		current_interaction_widget = interaction_widget

func _on_body_exited(body):
	if body is Player:
		body.exit_interactable(self)
		remove_interaction_widget()
		
func remove_interaction_widget():
	if current_interaction_widget:
		current_interaction_widget.queue_free()		
		
func interact(player: Player):
	pass
