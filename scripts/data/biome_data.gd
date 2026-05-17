class_name BiomeData

var id: String = ""
var display_name: String = ""
# room 抽签时此 biome 被选中的相对权重（饥荒里 task 池权重）
var room_weight: float = 1.0
# 必出 prefab：resource_id → int 或 [min, max]
var count_prefabs: Dictionary = {}
# 权重撒点 prefab：resource_id → 整数权重
var distribute_prefabs: Dictionary = {}
# 候选点中实际撒点的比例（0~1），饥荒 distributepercent
var distribute_percent: float = 0.5
# 生物刷新权重：creature_id → weight
var creature_weights: Dictionary = {}
