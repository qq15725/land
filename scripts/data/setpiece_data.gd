class_name SetpieceData

# 固定地标（饥荒 setpiece）：在一片 footprint 范围内按相对坐标摆若干 prefab。
# 放置时整片 footprint 在 room 内 reserve 占格，distribute pass 不会再撒到这片区域。

var id: String = ""
var display_name: String = ""
# 占用 tile 数
var footprint: Vector2i = Vector2i(1, 1)
# 允许出现的 biome_id 列表（空 = 任意 biome）
var biome_filter: Array = []
# 随机抽取时的权重
var weight: float = 1.0
# true = 每张地图必出一次
var required: bool = false
# [{id, x, y}, ...] x,y 是 footprint 内局部 tile 坐标
var prefabs: Array = []
