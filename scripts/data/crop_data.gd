class_name CropData

var id: String = ""
var display_name: String = ""
var seed_item_id: String = ""
var seed_item: ItemData = null
var output_item_id: String = ""
var output_item: ItemData = null
var output_amount: int = 1
var growth_time: float = 20.0
var bonus_drop: Dictionary = {}  # {item_id, amount} 或 {}
# 允许种植的季节列表（空数组 = 全年可种）
var allowed_seasons: Array = []
