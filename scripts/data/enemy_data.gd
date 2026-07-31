class_name EnemyData
extends Resource

@export var walk_duration: float
@export var idle_duration: float
@export var speed: float
@export var speed_on_random_walk: float
@export var patrol_radius: float
@export var max_health: float
@export var resistence: float
@export var damage_given: float
@export var cancel_attack_on_damage_chance: float = 0.5
@export var dash_force: float
@export var dash_duration: float
@export var dash_chance: float
@export var dash_cooldown: float
@export var drop_id_on_death: ItemData.ItemID
@export var drop_amount_on_death: int 

# shadow
@export var shadow_offset := Vector2(0, 50)
@export var shadow_radius := 10.0
@export var shadow_scale := Vector2(1.0, 0.6)
@export var shadow_alpha := 0.4
