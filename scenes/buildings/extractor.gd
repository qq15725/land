class_name Extractor
extends AutomationNode

# 抽取器：从背后(back)的源取物品，推到朝向(front)的传送带。
# 源支持：储物箱 / 成熟农田(自动收获) / 动物围栏(收集附近产出掉落物)。
# 农田一次收获多个时用 _pending 缓冲逐 tick 送出。

const PEN_COLLECT_RADIUS := 48.0

var _pending_item: ItemData = null
var _pending_count: int = 0

func _node_color() -> Color:
	return Color(0.5, 0.34, 0.3, 0.95)

func tick() -> void:
	var front = AutomationSystem.node_at(front_cell())
	if front == null:
		return
	# 优先送出缓冲
	if _pending_item != null:
		if front.can_accept(_pending_item) and front.push_item(_pending_item):
			_pending_count -= 1
			if _pending_count <= 0:
				_pending_item = null
		return
	var src := AutomationSystem.building_at(back_cell(), get_parent())
	if src == null:
		return
	# 农田：成熟则收获进缓冲
	if src is FarmPlot:
		if src.is_ready():
			var r: Dictionary = src.auto_harvest()
			if r.has("item"):
				_pending_item = r["item"]
				_pending_count = int(r["amount"])
		return
	# 储物箱
	if src is BuildingBase and ("storage" in src) and src.get("storage") != null:
		var inv = src.storage
		var item := _first_item(inv)
		if item != null and front.can_accept(item):
			inv.remove_item(item, 1)
			front.push_item(item)
		return
	# 动物围栏：收集附近的产出掉落物
	if src.get("_spawned_animal") != null:
		_collect_drop_near(src, front)

func _first_item(inv) -> ItemData:
	for slot in inv.slots:
		if slot.item != null and slot.amount > 0:
			return slot.item
	return null

func _collect_drop_near(pen: Node, front) -> void:
	var layer := get_parent()
	for c in layer.get_children():
		if c is DropItem and c.item != null and c.amount > 0:
			if c.global_position.distance_to(pen.global_position) <= PEN_COLLECT_RADIUS:
				if front.can_accept(c.item):
					front.push_item(c.item)
					c.amount -= 1
					if c.amount <= 0:
						c.queue_free()
					elif c.has_method("_refresh_visual"):
						c._refresh_visual()
					return
