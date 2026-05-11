class_name ResourceNodeData

var id: String = ""
var display_name: String = ""
var drop_item_id: String = ""
var drop_item: ItemData = null
var drop_amount: int = 3
var respawn_time: float = 30.0
var tool_required: String = ""
var spawn_weight: float = 1.0

var collision_size: Vector2 = Vector2(16, 16)
var collision_offset_y: float = 0.0
var visual_offset_y: float = 0.0
var frame_height: int = 64
var drop_table: Array = []  # [{item_id, amount, chance}]
