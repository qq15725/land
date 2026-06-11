class_name Inserter
extends AutomationNode

# 放入器：从背后(back)的传送带取物品，放入朝向(front)的目标。
# 目标支持：储物箱 / 空农田(自动播种) / 动物围栏(自动喂食)。
# 只在目标成功接收后才从传送带取走（避免丢件）。

func _node_color() -> Color:
	return Color(0.3, 0.46, 0.34, 0.95)

func tick() -> void:
	var back = AutomationSystem.node_at(back_cell())
	if back == null:
		return
	var item := back.peek_item()
	if item == null:
		return
	var dst := AutomationSystem.building_at(front_cell(), get_parent())
	if dst == null:
		return
	# 农田：空地播种
	if dst is FarmPlot:
		if dst.is_empty() and dst.auto_plant(item):
			back.take_item()
		return
	# 储物箱
	if dst is BuildingBase and ("storage" in dst) and dst.get("storage") != null:
		if dst.storage.add_item(item, 1) == 0:
			back.take_item()
		return
	# 动物围栏：喂食
	if dst.get("_spawned_animal") != null:
		var animal = dst.get("_spawned_animal")
		if animal != null and animal.has_method("auto_feed") and animal.auto_feed(item):
			back.take_item()
