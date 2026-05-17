class_name RoomGraph
extends RefCounted

# 饥荒式 Voronoi room 划分：撒 N 点 → Lloyd 松弛 → 每个 tile 归到最近点。
# 每个 cell 对应一个 Room；后续撒点 pipeline 按 room 走 count/distribute 两 pass。

class Room:
	var id: int = -1
	var center_tile: Vector2i = Vector2i.ZERO        # map-local tile 坐标（左上角原点）
	var center_world: Vector2 = Vector2.ZERO         # 世界坐标（像素）
	var biome_id: String = ""
	var biome: BiomeData = null
	var tile_count: int = 0
	var bbox_min: Vector2i = Vector2i.ZERO
	var bbox_max: Vector2i = Vector2i.ZERO

const TILE_PX := 16.0
const RELAX_ITERS := 6                # Lloyd 松弛迭代次数
const RELAX_STEP := 2                 # 松弛阶段粗采样步长（步长越大越快但越粗）
const ROW_YIELD_INTERVAL := 32        # 最终归属阶段每 N 行 yield 一帧

var map_w: int = 0
var map_h: int = 0
var origin_tile: Vector2i = Vector2i.ZERO
var tile_owner: PackedInt32Array     # idx = y*map_w + x → room.id
var rooms: Array = []                # Array[Room]
var _host: Node = null               # 用于分帧 await get_tree().process_frame


func _init(host: Node = null) -> void:
	_host = host


# 主入口：生成 voronoi room（async，调用方应 await）
func build(map_w_: int, map_h_: int, room_count: int, seed_val: int, origin: Vector2i) -> void:
	map_w = map_w_
	map_h = map_h_
	origin_tile = origin
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# 撒种子点
	var seeds: PackedVector2Array = PackedVector2Array()
	seeds.resize(room_count)
	for i in room_count:
		seeds[i] = Vector2(
			rng.randf_range(2.0, map_w - 2.0),
			rng.randf_range(2.0, map_h - 2.0),
		)

	# Lloyd 松弛
	for _iter in RELAX_ITERS:
		seeds = _relax(seeds, RELAX_STEP)
		await _yield()

	# 最终归属（全分辨率）
	tile_owner = PackedInt32Array()
	tile_owner.resize(map_w * map_h)
	var tile_counts := PackedInt32Array()
	tile_counts.resize(room_count)
	var bbox_min_x := PackedInt32Array()
	bbox_min_x.resize(room_count)
	var bbox_min_y := PackedInt32Array()
	bbox_min_y.resize(room_count)
	var bbox_max_x := PackedInt32Array()
	bbox_max_x.resize(room_count)
	var bbox_max_y := PackedInt32Array()
	bbox_max_y.resize(room_count)
	for i in room_count:
		bbox_min_x[i] = map_w
		bbox_min_y[i] = map_h
		bbox_max_x[i] = -1
		bbox_max_y[i] = -1

	for y in map_h:
		for x in map_w:
			var best := 0
			var best_d2 := INF
			for i in room_count:
				var s := seeds[i]
				var dx := float(x) - s.x
				var dy := float(y) - s.y
				var d2 := dx * dx + dy * dy
				if d2 < best_d2:
					best_d2 = d2
					best = i
			tile_owner[y * map_w + x] = best
			tile_counts[best] += 1
			if x < bbox_min_x[best]: bbox_min_x[best] = x
			if y < bbox_min_y[best]: bbox_min_y[best] = y
			if x > bbox_max_x[best]: bbox_max_x[best] = x
			if y > bbox_max_y[best]: bbox_max_y[best] = y
		if (y % ROW_YIELD_INTERVAL) == 0:
			await _yield()

	# 构造 Room
	rooms.clear()
	for i in room_count:
		var r := Room.new()
		r.id = i
		r.center_tile = Vector2i(int(seeds[i].x), int(seeds[i].y))
		r.center_world = Vector2(
			float(origin_tile.x + r.center_tile.x) * TILE_PX + TILE_PX * 0.5,
			float(origin_tile.y + r.center_tile.y) * TILE_PX + TILE_PX * 0.5,
		)
		r.tile_count = tile_counts[i]
		r.bbox_min = Vector2i(bbox_min_x[i], bbox_min_y[i])
		r.bbox_max = Vector2i(bbox_max_x[i], bbox_max_y[i])
		var biome := WorldGenerator.get_biome_at(r.center_world)
		if biome:
			r.biome = biome
			r.biome_id = biome.id
		rooms.append(r)


# Lloyd 松弛：每点 → 其归属 tile 的质心
func _relax(seeds: PackedVector2Array, step: int) -> PackedVector2Array:
	var n := seeds.size()
	var sum_x := PackedFloat32Array()
	sum_x.resize(n)
	var sum_y := PackedFloat32Array()
	sum_y.resize(n)
	var cnt := PackedInt32Array()
	cnt.resize(n)

	var y := 0
	while y < map_h:
		var x := 0
		while x < map_w:
			var best := 0
			var best_d2 := INF
			for i in n:
				var s := seeds[i]
				var dx := float(x) - s.x
				var dy := float(y) - s.y
				var d2 := dx * dx + dy * dy
				if d2 < best_d2:
					best_d2 = d2
					best = i
			sum_x[best] += float(x)
			sum_y[best] += float(y)
			cnt[best] += 1
			x += step
		y += step

	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		if cnt[i] > 0:
			out[i] = Vector2(sum_x[i] / float(cnt[i]), sum_y[i] / float(cnt[i]))
		else:
			out[i] = seeds[i]
	return out


func _yield() -> void:
	if _host:
		await _host.get_tree().process_frame


# 查询：tile 坐标（map-local，左上 0,0）→ Room
func room_at_local(tx: int, ty: int) -> Room:
	if tx < 0 or tx >= map_w or ty < 0 or ty >= map_h:
		return null
	var idx := tile_owner[ty * map_w + tx]
	return rooms[idx]


# 查询：世界 tile 坐标 → Room
func room_at_world_tile(wx: int, wy: int) -> Room:
	return room_at_local(wx - origin_tile.x, wy - origin_tile.y)
