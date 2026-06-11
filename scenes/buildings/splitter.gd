class_name Splitter
extends Conveyor

# 分流器：物品轮流分配到 3 个输出方向（前/右/左），平衡多条产线。

var _rr := 0

func _node_color() -> Color:
	return Color(0.5, 0.5, 0.28, 0.95)

func tick() -> void:
	if _item == null or _moved_this_tick:
		return
	var out_dirs := [facing, (facing + 1) % 4, (facing + 3) % 4]  # 前 右 左
	for k in 3:
		var d: int = out_dirs[(_rr + k) % 3]
		var n = AutomationSystem.node_at(grid_pos + DIRS[d])
		if n != null and n.can_accept(_item) and n.push_item(_item):
			_item = null
			_rr = (_rr + k + 1) % 3
			_update_item_visual()
			return
