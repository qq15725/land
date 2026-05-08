class_name CreatureResource
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_health: float = 30.0
@export var move_speed: float = 60.0
@export var attack_damage: float = 8.0
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 1.2
@export var detection_radius: float = 150.0
@export var wander_radius: float = 200.0
@export var color: Color = Color(0.6, 0.2, 0.2)

# 掉落表：[{item_id, min, max, chance}]
@export var drop_table: Array[Dictionary] = []
