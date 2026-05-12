extends Node

# 把世界按 CHUNK_SIZE × CHUNK_SIZE tile 划分。
# 玩家附近半径内的 chunk 处于 active 状态；离开半径时 deactivate（实体卸载、状态存到 snapshot）。
# 再次进入时，优先从 snapshot 还原；若无则生成新内容。

const CHUNK_SIZE := 32                      # tile 数（每 chunk）
const TILE_SIZE := 16.0
const CHUNK_PIXELS := CHUNK_SIZE * TILE_SIZE
const RESOURCES_PER_CHUNK := 6              # 每个 chunk 期望资源数

# 当前 active chunk → 该 chunk 内的活跃实体（资源节点等）
var _active_chunks: Dictionary = {}         # Vector2i → Array[Node]

# Chunk 卸载后状态快照：被采集状态 / 位置 / 资源类型，重新进入时还原。
# 格式：Vector2i → Array[Dictionary]，每条 entry：
#   {"kind": "resource", "id": <resource_id>, "x", "y", "depleted": bool}
var _snapshots: Dictionary = {}


func world_to_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK_PIXELS), floori(pos.y / CHUNK_PIXELS))

func chunk_center(chunk: Vector2i) -> Vector2:
	return Vector2(
		(chunk.x + 0.5) * CHUNK_PIXELS,
		(chunk.y + 0.5) * CHUNK_PIXELS
	)

func random_in_chunk(rng: RandomNumberGenerator, chunk: Vector2i, edge_buffer: float = 16.0) -> Vector2:
	var x := chunk.x * CHUNK_PIXELS + rng.randf_range(edge_buffer, CHUNK_PIXELS - edge_buffer)
	var y := chunk.y * CHUNK_PIXELS + rng.randf_range(edge_buffer, CHUNK_PIXELS - edge_buffer)
	return Vector2(x, y)

func chunks_in_radius(center_tile: Vector2i, radius_tiles: int) -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	var center_chunk_x := floori(float(center_tile.x) / float(CHUNK_SIZE))
	var center_chunk_y := floori(float(center_tile.y) / float(CHUNK_SIZE))
	var r := maxi(1, ceili(float(radius_tiles) / float(CHUNK_SIZE)))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			chunks.append(Vector2i(center_chunk_x + dx, center_chunk_y + dy))
	return chunks

func register_entity(chunk: Vector2i, node: Node) -> void:
	if not _active_chunks.has(chunk):
		_active_chunks[chunk] = []
	_active_chunks[chunk].append(node)

func is_active(chunk: Vector2i) -> bool:
	return _active_chunks.has(chunk)

func get_active_chunks() -> Array:
	return _active_chunks.keys()

func entities_in_chunk(chunk: Vector2i) -> Array:
	return _active_chunks.get(chunk, [])

func has_snapshot(chunk: Vector2i) -> bool:
	return _snapshots.has(chunk)

func get_snapshot(chunk: Vector2i) -> Array:
	return _snapshots.get(chunk, [])

func clear_state() -> void:
	_active_chunks.clear()
	_snapshots.clear()

# 卸载 chunk：把当前实体序列化到 snapshot，free 节点。
func deactivate_chunk(chunk: Vector2i) -> void:
	if not _active_chunks.has(chunk):
		return
	var entries: Array = []
	for node in _active_chunks[chunk]:
		if not is_instance_valid(node):
			continue
		if node is ResourceNode:
			var rn := node as ResourceNode
			entries.append({
				"kind": "resource",
				"id": rn.resource_id,
				"x": rn.global_position.x,
				"y": rn.global_position.y,
				"depleted": rn.is_depleted(),
			})
		node.queue_free()
	_snapshots[chunk] = entries
	_active_chunks.erase(chunk)

# 标记 chunk 已激活但实体由外部创建好。外部调用 register_entity 添加实体。
func mark_active(chunk: Vector2i) -> void:
	if not _active_chunks.has(chunk):
		_active_chunks[chunk] = []

# ─── 存档支持 ────────────────────────────────────────────────────────────────

# 把所有 active chunk 的当前状态写回 _snapshots（不卸载节点）。存档时调用。
func snapshot_active_chunks() -> void:
	for chunk in _active_chunks.keys():
		var entries: Array = []
		for node in _active_chunks[chunk]:
			if not is_instance_valid(node):
				continue
			if node is ResourceNode:
				var rn := node as ResourceNode
				entries.append({
					"kind": "resource",
					"id": rn.resource_id,
					"x": rn.global_position.x,
					"y": rn.global_position.y,
					"depleted": rn.is_depleted(),
				})
		_snapshots[chunk] = entries

# 导出所有 snapshot 为扁平数组，方便 JSON 存储。
func export_snapshots() -> Array:
	var data: Array = []
	for chunk in _snapshots:
		for entry in _snapshots[chunk]:
			var e: Dictionary = entry.duplicate()
			e["chunk_x"] = chunk.x
			e["chunk_y"] = chunk.y
			data.append(e)
	return data

func import_snapshots(data: Array) -> void:
	_snapshots.clear()
	for e in data:
		var chunk := Vector2i(int(e.get("chunk_x", 0)), int(e.get("chunk_y", 0)))
		if not _snapshots.has(chunk):
			_snapshots[chunk] = []
		var copy: Dictionary = (e as Dictionary).duplicate()
		copy.erase("chunk_x")
		copy.erase("chunk_y")
		_snapshots[chunk].append(copy)
