class_name Inserter
extends AutomationNode

# 放入器：从背后(back)的传送带取物品，放入朝向(front)的储物箱。
# 只在容器放得下时才取走（避免丢件）。

func _node_color() -> Color:
	return Color(0.3, 0.46, 0.34, 0.95)

func tick() -> void:
	var back = AutomationSystem.node_at(back_cell())
	if back == null:
		return
	var item := back.peek_item()
	if item == null:
		return
	var chest = AutomationSystem.find_storage_at(front_cell(), get_parent())
	if chest == null:
		return
	var leftover := chest.storage.add_item(item, 1)
	if leftover == 0:
		back.take_item()
