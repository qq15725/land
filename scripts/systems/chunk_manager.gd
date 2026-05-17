extends Node

# 整图 entity 注册表（饥荒式：地图加载时一次性生成 prefab，所有 entity 全程在场）。
# 旧的 chunk 流式 / snapshot 机制已废弃；命名仍保留 ChunkManager 以兼容外部 autoload 引用。

var _entities: Array = []           # 当前活着的 ResourceNode 列表
var _pending_snapshot: Array = []   # 读档时缓存的扁平 entity 列表，供 world.gd populate 阶段消费


func clear_state() -> void:
	_entities.clear()
	_pending_snapshot.clear()


# 任意时刻新生成的 ResourceNode 都应通过此 API 登记，方便存档时遍历。
func register_entity(node: Node) -> void:
	if not is_instance_valid(node):
		return
	_entities.append(node)


# 旧 API 兼容（保存时调用）：整图一次性生成无需 snapshot 刷新，此处为 noop。
func snapshot_active_chunks() -> void:
	pass


# 序列化所有活着的资源节点为扁平条目。
func export_snapshots() -> Array:
	var out: Array = []
	for n in _entities:
		if not is_instance_valid(n):
			continue
		if n is ResourceNode:
			var rn := n as ResourceNode
			out.append({
				"kind": "resource",
				"id": rn.resource_id,
				"x": rn.global_position.x,
				"y": rn.global_position.y,
				"depleted": rn.is_depleted(),
			})
	return out


# 读档时缓存待还原项；world.gd 在 populate 前消费。
func import_snapshots(data: Variant) -> void:
	_pending_snapshot.clear()
	if data is Array:
		for entry in data:
			if entry is Dictionary:
				_pending_snapshot.append(entry)


func has_pending_restore() -> bool:
	return not _pending_snapshot.is_empty()


func consume_pending_snapshot() -> Array:
	var out := _pending_snapshot.duplicate()
	_pending_snapshot.clear()
	return out
