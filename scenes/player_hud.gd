class_name PlayerHUD

extends CanvasLayer

@onready var healthbar: TextureProgressBar = $Stats/HealthBar
@onready var staminabar: TextureProgressBar = $Stats/StaminaBar
@onready var hotbar: Hotbar = $Hotbar
@onready var portrait_container: PortraitContainer = $Stats/PortraitWidget/PortraitContainer
@export var player: Player


func _ready() -> void:
	healthbar.min_value = 0
	staminabar.min_value = 0
	
	player.inventory.inventory_update.connect(_on_inventory_update)
	player.damage_taken.connect(_on_player_damage_taken)
	player.update_stats.connect(on_player_update_stats)
	player.initialized.connect(_on_player_initialized)
		
	for slot in hotbar.slots:
		slot.consume_item.connect(player._on_item_consume)

func _on_inventory_update():
	var index := 0
	for item in player.inventory.slots:
		hotbar.slots[index].set_item(item, player.inventory.slots[item])
		index += 1
		
	while index < hotbar.slots.size():
		hotbar.slots[index].clear()
		index += 1

func play_ui_hurt_animation():
	portrait_container.play_hurt_animation()
		
func update_max_health() -> void:
	self.healthbar.max_value = player.config.max_health

func update_max_stamina() -> void:
	self.staminabar.max_value = player.config.max_stamina
	
func update_health():
	self.healthbar.value = player.health
	
func update_stamina():
	self.staminabar.value = player.stamina

func _on_player_initialized():
	update_stats()

func on_player_update_stats() -> void:
	update_stats()
	
func update_stats():
	update_max_health()
	update_health()
	update_max_stamina()
	update_stamina()
	
func _on_player_damage_taken() -> void:
	update_health()
	play_ui_hurt_animation()
