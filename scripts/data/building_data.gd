class_name BuildingData

var id: String = ""
var display_name: String = ""
var category: String = "building"
var scene_path: String = ""
var sprite_path: String = ""
var cost: Array = []
# cost 元素: {item_id: String, amount: int, item: ItemData}
var animal_id: String = ""
var connects: bool = false
var is_gate: bool = false
# 围栏/特殊建筑可能有自定义渲染逻辑，跳过通用 sprite 加载
var custom_render: bool = false
