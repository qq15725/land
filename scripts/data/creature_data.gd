class_name CreatureData

var id: String = ""
var display_name: String = ""
var sprite_path: String = ""
var max_health: float = 30.0
var move_speed: float = 60.0
var attack_damage: float = 8.0
var attack_range: float = 28.0
var attack_cooldown: float = 1.2
var detection_radius: float = 150.0
var wander_radius: float = 200.0
var sprite_scale: float = 1.0
var drop_table: Array = []
var passive: bool = false              # true = 不主动攻击玩家，受击逃跑
var nocturnal: bool = false            # true = 仅夜晚 spawn（默认 false 给野生生物白天用）
var max_health_scale: float = 1.0      # Boss/精英倍率，配合 B6
var is_boss: bool = false              # Boss 标志
