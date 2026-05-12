class_name ItemData

var id: String = ""
var display_name: String = ""
var icon_path: String = ""
var icon_grid: Vector2i = Vector2i.ZERO
var max_stack: int = 64
var description: String = ""
var color: Color = Color.WHITE
var heal_amount: float = 0.0
# 工具类型："axe" / "pickaxe" 等，空表示非工具。
# 玩家选中工具时可用于采集对应 tool_required 的资源节点。
var tool_type: String = ""
