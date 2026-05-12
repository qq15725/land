extends Node

# 把世界按 CHUNK_SIZE × CHUNK_SIZE tile 划分。
# 当前版本：world.gd 启动时一次性生成所有 chunk 内的资源；
# 留 activate/deactivate 接口给未来真正按需加载/卸载使用。

const CHUNK_SIZE := 32                      # tile 数（每 chunk）
const TILE_SIZE := 16.0                     # 像素
const CHUNK_PIXELS := CHUNK_SIZE * TILE_SIZE
const RESOURCES_PER_CHUNK := 6              # 每个 chunk 期望资源数

var _active_chunks: Dictionary = {}         # Vector2i → Array[Node]（属于该 chunk 的实体）

# 把世界坐标转 chunk 坐标
func world_to_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK_PIXELS), floori(pos.y / CHUNK_PIXELS))

# chunk 中心的世界坐标
func chunk_center(chunk: Vector2i) -> Vector2:
	return Vector2(
		(chunk.x + 0.5) * CHUNK_PIXELS,
		(chunk.y + 0.5) * CHUNK_PIXELS
	)

# 在 chunk 内随机一个世界坐标（避开边缘 buffer）
func random_in_chunk(rng: RandomNumberGenerator, chunk: Vector2i, edge_buffer: float = 16.0) -> Vector2:
	var x := chunk.x * CHUNK_PIXELS + rng.randf_range(edge_buffer, CHUNK_PIXELS - edge_buffer)
	var y := chunk.y * CHUNK_PIXELS + rng.randf_range(edge_buffer, CHUNK_PIXELS - edge_buffer)
	return Vector2(x, y)

# 枚举覆盖给定半径的所有 chunk（半径单位：tile）
func chunks_in_radius(center_tile: Vector2i, radius_tiles: int) -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	var center_chunk_x := floori(float(center_tile.x) / float(CHUNK_SIZE))
	var center_chunk_y := floori(float(center_tile.y) / float(CHUNK_SIZE))
	var r := maxi(1, ceili(float(radius_tiles) / float(CHUNK_SIZE)))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			chunks.append(Vector2i(center_chunk_x + dx, center_chunk_y + dy))
	return chunks

# 注册 chunk 中的实体（用于将来卸载）
func register_entity(chunk: Vector2i, node: Node) -> void:
	if not _active_chunks.has(chunk):
		_active_chunks[chunk] = []
	_active_chunks[chunk].append(node)

func get_active_chunks() -> Array:
	return _active_chunks.keys()

func entities_in_chunk(chunk: Vector2i) -> Array:
	return _active_chunks.get(chunk, [])
