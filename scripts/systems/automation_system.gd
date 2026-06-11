extends Node

# 自动化系统（F 路线核心）。
#
# 设计锚点（已决策）：无能源 / 方格+朝向 / 补充手动 / 主世界铺设。
# 维护「格子坐标 → 自动化节点」注册表，固定 tick 推进物品流。
# 物品流单向：容器 →[抽取器]→ 传送带链 →[放入器]→ 容器。
# server-authoritative：仅房主跑 tick（单机即 server）。

const TILE_SIZE := 16.0
const TICK_INTERVAL := 0.5   # 每 0.5s 推进一格，节奏轻松可视

var _nodes: Dictionary = {}   # Vector2i → AutomationNode
var _accum := 0.0

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE_SIZE), floori(pos.y / TILE_SIZE))

func register(node) -> void:
	_nodes[node.grid_pos] = node

func unregister(node) -> void:
	if _nodes.get(node.grid_pos) == node:
		_nodes.erase(node.grid_pos)

func node_at(cell: Vector2i):
	var n = _nodes.get(cell)
	return n if is_instance_valid(n) else null

# 找某格子上的容器建筑（带 storage 的 BuildingBase）。layer 传节点的父层（YSortLayer）。
func find_storage_at(cell: Vector2i, layer: Node) -> Node:
	if layer == null:
		return null
	for c in layer.get_children():
		if c is BuildingBase and ("storage" in c) and c.get("storage") != null:
			if world_to_grid(c.global_position) == cell:
				return c
	return null

# 找某格子上可对接的建筑（储物箱 / 农田 / 动物围栏），供抽取器/放入器分派。
func building_at(cell: Vector2i, layer: Node) -> Node:
	if layer == null:
		return null
	for c in layer.get_children():
		if (c is BuildingBase or c is FarmPlot) and world_to_grid(c.global_position) == cell:
			return c
	return null

# 生产线总览统计
func get_stats() -> Dictionary:
	var counts := {}
	var items_on_belts := 0
	for n in _nodes.values():
		if not is_instance_valid(n):
			continue
		var t: String = n.get_class() if n.get_script() == null else n.get_script().get_global_name()
		counts[t] = int(counts.get(t, 0)) + 1
		if n is Conveyor and n.peek_item() != null:
			items_on_belts += 1
	return {
		"total": _nodes.size(),
		"by_type": counts,
		"items_on_belts": items_on_belts,
	}

func _process(delta: float) -> void:
	if not Network.is_server():
		return
	if _nodes.is_empty():
		return
	_accum += delta
	if _accum < TICK_INTERVAL:
		return
	_accum = 0.0
	var nodes := _nodes.values()
	# 两阶段：先清移动标记，再 tick，保证物品每 tick 最多前进一格
	for n in nodes:
		if is_instance_valid(n):
			n._moved_this_tick = false
	for n in nodes:
		if is_instance_valid(n):
			n.tick()
