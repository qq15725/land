class_name FilterConveyor
extends Conveyor

# 过滤传送带：锁定第一个经过的物品类型，之后只允许同类通过（自动分拣）。
# 配合分流器可把混合物品流按种类分开。

var _filter_id := ""

func _node_color() -> Color:
	return Color(0.52, 0.3, 0.42, 0.95)

func can_accept(item: ItemData) -> bool:
	if not _filter_id.is_empty() and item.id != _filter_id:
		return false
	return super.can_accept(item)

func push_item(item: ItemData) -> bool:
	var ok := super.push_item(item)
	if ok and _filter_id.is_empty():
		_filter_id = item.id   # 锁定第一个通过的物品类型
	return ok

func get_save_state() -> Dictionary:
	var d := super.get_save_state()
	d["filter"] = _filter_id
	return d

func load_save_state(data: Dictionary) -> void:
	super.load_save_state(data)
	_filter_id = data.get("filter", "")
