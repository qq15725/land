class_name Extractor
extends AutomationNode

# 抽取器：从背后(back)的储物箱取 1 个物品，推到朝向(front)的传送带。

func _node_color() -> Color:
	return Color(0.5, 0.34, 0.3, 0.95)

func tick() -> void:
	var front = AutomationSystem.node_at(front_cell())
	if front == null:
		return
	var chest = AutomationSystem.find_storage_at(back_cell(), get_parent())
	if chest == null:
		return
	var inv = chest.storage
	var item := _first_item(inv)
	if item == null:
		return
	if front.can_accept(item):
		inv.remove_item(item, 1)
		front.push_item(item)

func _first_item(inv) -> ItemData:
	for slot in inv.slots:
		if slot.item != null and slot.amount > 0:
			return slot.item
	return null
