class_name BiomeData

var id: String = ""
var display_name: String = ""
# resource_id → weight
var resource_weights: Dictionary = {}
# creature_id → weight
var creature_weights: Dictionary = {}
# 同样的资源点配额下，该 biome 想要的密度倍率
var spawn_density: float = 1.0
