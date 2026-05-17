class_name PrefabPopulator
extends RefCounted

# 饥荒式 PopulateVoronoi：按 room 依次走 count_prefabs / distribute_prefabs / setpiece pass。
# 整图共享一张 occupied 表（world tile 坐标），footprint 互斥 + 跨 room 阻断。

const TILE_PX := 16.0
# 候选点数 / room tile 数（饥荒 cell sample point 数 ≈ 面积）
const CANDIDATE_DENSITY := 0.025
# 随机 setpiece 抽样次数
const RANDOM_SETPIECE_COUNT := 5
# room 必须比 setpiece footprint 大多少倍才合格
const SETPIECE_MIN_ROOM_RATIO := 4

var graph: RoomGraph
var y_sort_layer: Node2D
var resource_scene: PackedScene
var occupied: Dictionary = {}   # Vector2i(world tile) → true
var rng: RandomNumberGenerator


func _init(g: RoomGraph, layer: Node2D, scene: PackedScene, seed_val: int) -> void:
	graph = g
	y_sort_layer = layer
	resource_scene = scene
	rng = RandomNumberGenerator.new()
	rng.seed = seed_val


# 在生成前 reserve 一块世界区域（如玩家出生点），不让任何 prefab 占进来。
func reserve_world_tiles(rect: Rect2i) -> void:
	for ty in range(rect.position.y, rect.position.y + rect.size.y):
		for tx in range(rect.position.x, rect.position.x + rect.size.x):
			occupied[Vector2i(tx, ty)] = true


func populate() -> void:
	_populate_setpieces()
	var i := 0
	for r in graph.rooms:
		var room := r as RoomGraph.Room
		if room.biome == null:
			continue
		_populate_count_prefabs(room)
		_populate_distribute_prefabs(room)
		i += 1
		if (i % 8) == 0 and y_sort_layer:
			await y_sort_layer.get_tree().process_frame


# ─── Setpiece pass ──────────────────────────────────────────────────────────

func _populate_setpieces() -> void:
	var setpieces: Array = ItemDatabase.get_all_setpieces()
	if setpieces.is_empty():
		return
	for sp in setpieces:
		if (sp as SetpieceData).required:
			_try_place_setpiece(sp)
	var pool: Array = []
	for sp in setpieces:
		if not (sp as SetpieceData).required:
			pool.append(sp)
	if pool.is_empty():
		return
	for _i in RANDOM_SETPIECE_COUNT:
		var chosen := _pick_setpiece_by_weight(pool)
		if chosen:
			_try_place_setpiece(chosen)


func _pick_setpiece_by_weight(pool: Array) -> SetpieceData:
	var total := 0.0
	for sp in pool:
		total += (sp as SetpieceData).weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	var acc := 0.0
	for sp in pool:
		acc += (sp as SetpieceData).weight
		if roll <= acc:
			return sp
	return pool[pool.size() - 1]


func _try_place_setpiece(sp: SetpieceData) -> bool:
	var fp_area: int = sp.footprint.x * sp.footprint.y
	var candidates: Array = []
	for r in graph.rooms:
		var room := r as RoomGraph.Room
		if room.biome == null:
			continue
		if not sp.biome_filter.is_empty() and not (room.biome.id in sp.biome_filter):
			continue
		if room.tile_count < fp_area * SETPIECE_MIN_ROOM_RATIO:
			continue
		candidates.append(room)
	if candidates.is_empty():
		return false
	candidates.shuffle()
	for room in candidates:
		if _place_setpiece_in_room(room, sp):
			return true
	return false


func _place_setpiece_in_room(room: RoomGraph.Room, sp: SetpieceData) -> bool:
	var max_x := room.bbox_max.x - sp.footprint.x + 1
	var max_y := room.bbox_max.y - sp.footprint.y + 1
	if max_x < room.bbox_min.x or max_y < room.bbox_min.y:
		return false
	for _attempt in 30:
		var tx := rng.randi_range(room.bbox_min.x, max_x)
		var ty := rng.randi_range(room.bbox_min.y, max_y)
		if not _setpiece_fits(room, sp, tx, ty):
			continue
		_mark_footprint(tx, ty, sp.footprint)
		for p in sp.prefabs:
			var data := ItemDatabase.get_resource_node(String(p.get("id", "")))
			if data == null:
				continue
			var ox := int(p.get("x", 0))
			var oy := int(p.get("y", 0))
			_spawn_resource(data, graph.origin_tile.x + tx + ox, graph.origin_tile.y + ty + oy)
		return true
	return false


func _setpiece_fits(room: RoomGraph.Room, sp: SetpieceData, tx: int, ty: int) -> bool:
	for dy in sp.footprint.y:
		for dx in sp.footprint.x:
			var fx := tx + dx
			var fy := ty + dy
			if graph.room_at_local(fx, fy) != room:
				return false
			var key := Vector2i(graph.origin_tile.x + fx, graph.origin_tile.y + fy)
			if occupied.has(key):
				return false
	return true


# ─── count_prefabs pass ────────────────────────────────────────────────────

func _populate_count_prefabs(room: RoomGraph.Room) -> void:
	var biome := room.biome
	for prefab_id in biome.count_prefabs:
		var count := _resolve_count(biome.count_prefabs[prefab_id])
		var data := ItemDatabase.get_resource_node(String(prefab_id))
		if data == null or count <= 0:
			continue
		for _i in count:
			_try_place_resource_in_room(room, data)


func _resolve_count(v) -> int:
	if v is Array and v.size() >= 2:
		return rng.randi_range(int(v[0]), int(v[1]))
	if v is float:
		return int(v)
	return int(v)


# ─── distribute_prefabs pass ───────────────────────────────────────────────

func _populate_distribute_prefabs(room: RoomGraph.Room) -> void:
	var biome := room.biome
	if biome.distribute_prefabs.is_empty():
		return
	var n_candidates := maxi(1, int(room.tile_count * CANDIDATE_DENSITY))
	var weight_total := 0.0
	for w in biome.distribute_prefabs.values():
		weight_total += float(w)
	if weight_total <= 0.0:
		return
	for _i in n_candidates:
		if rng.randf() > biome.distribute_percent:
			continue
		var data := _pick_distribute(biome, weight_total)
		if data == null:
			continue
		_try_place_resource_in_room(room, data)


func _pick_distribute(biome: BiomeData, total: float) -> ResourceNodeData:
	var roll := rng.randf() * total
	var acc := 0.0
	for id in biome.distribute_prefabs:
		acc += float(biome.distribute_prefabs[id])
		if roll <= acc:
			return ItemDatabase.get_resource_node(String(id))
	return null


# ─── 通用放置 ────────────────────────────────────────────────────────────────

func _try_place_resource_in_room(room: RoomGraph.Room, data: ResourceNodeData) -> bool:
	var fp: Vector2i = data.footprint
	if fp.x <= 0:
		fp.x = 1
	if fp.y <= 0:
		fp.y = 1
	var max_x := room.bbox_max.x - fp.x + 1
	var max_y := room.bbox_max.y - fp.y + 1
	if max_x < room.bbox_min.x or max_y < room.bbox_min.y:
		return false
	for _attempt in 10:
		var tx := rng.randi_range(room.bbox_min.x, max_x)
		var ty := rng.randi_range(room.bbox_min.y, max_y)
		if not _resource_fits(room, fp, tx, ty):
			continue
		_mark_footprint(tx, ty, fp)
		_spawn_resource(data, graph.origin_tile.x + tx, graph.origin_tile.y + ty)
		return true
	return false


func _resource_fits(room: RoomGraph.Room, fp: Vector2i, tx: int, ty: int) -> bool:
	for dy in fp.y:
		for dx in fp.x:
			var fx := tx + dx
			var fy := ty + dy
			if graph.room_at_local(fx, fy) != room:
				return false
			var key := Vector2i(graph.origin_tile.x + fx, graph.origin_tile.y + fy)
			if occupied.has(key):
				return false
	return true


# tx, ty 是 map-local tile 坐标
func _mark_footprint(tx: int, ty: int, fp: Vector2i) -> void:
	for dy in fp.y:
		for dx in fp.x:
			occupied[Vector2i(graph.origin_tile.x + tx + dx, graph.origin_tile.y + ty + dy)] = true


# wx, wy 是 footprint 左上角的世界 tile 坐标
func _spawn_resource(data: ResourceNodeData, wx: int, wy: int) -> void:
	var fp: Vector2i = data.footprint
	if fp.x <= 0:
		fp.x = 1
	if fp.y <= 0:
		fp.y = 1
	var pos := Vector2(
		(float(wx) + fp.x * 0.5) * TILE_PX,
		(float(wy) + fp.y - 0.5) * TILE_PX,
	)
	var node: ResourceNode = resource_scene.instantiate()
	node.resource_id = data.id
	node.position = pos
	y_sort_layer.add_child(node)
