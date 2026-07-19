class_name PlayerHUD

extends CanvasLayer

@onready var healthbar: TextureProgressBar = $Stats/HealthBar
@onready var staminabar: TextureProgressBar = $Stats/StaminaBar
@onready var hotbar: Hotbar = $Hotbar
@export var player: Player


func _ready() -> void:
	healthbar.min_value = 0
	staminabar.min_value = 0
	player.inventory.item_added.connect(_on_inventory_item_added)
	
func _on_inventory_item_added(item: ItemData, amount: int):
	update_inventory()

func update_inventory():
	var index := 0
	for item in player.inventory.slots:
		hotbar.slots[index].set_item(item, player.inventory.slots[item])
		index += 1
		
	while index < hotbar.slots.size():
		hotbar.slots[index].clear()
		index += 1
		
func update_max_health() -> void:
	self.healthbar.max_value = player.max_health

func update_max_stamina() -> void:
	self.staminabar.max_value = player.max_stamina
	
func update_health():
	self.healthbar.value = player.health
	
func update_stamina():
	self.staminabar.value = player.stamina
