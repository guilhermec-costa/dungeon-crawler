class_name BossAccessGate
extends Interactable

signal locked_touched
signal unlocked

const KEY_ID := ItemData.ItemID.CORRUPTED_KEY

var is_unlocked := false


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or is_unlocked:
		return

	if body.inventory.find_by_item_id(KEY_ID) == null:
		locked_touched.emit()
		return

	# The interaction area extends in front of the solid barrier.  Create the
	# prompt here instead of relying on the inherited callback, so the player is
	# always registered as able to interact before colliding with the gate.
	if current_interaction_widget == null:
		body.enter_interectable(self)
		current_interaction_widget = interaction_widget.instantiate()
		current_interaction_widget.position = interaction_position
		add_child(current_interaction_widget)


func _on_body_exited(body: Node2D) -> void:
	if body is Player and current_interaction_widget != null:
		super._on_body_exited(body)


func interact(player: Player) -> void:
	if is_unlocked:
		return

	var key := player.inventory.find_by_item_id(KEY_ID)
	if key == null:
		locked_touched.emit()
		return

	player.inventory.free_space(key)
	is_unlocked = true
	player.exit_interactable(self)
	remove_interaction_widget()
	unlocked.emit()
