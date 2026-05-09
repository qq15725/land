extends Node

const MAP_HALF     := 100
const MAP_SIZE     := MAP_HALF * 2
const SOURCE_ID    := 0
const WARP_STR     := 18.0  # 坐标扰动强度
const PATH_RADIUS  := 1     # 路径笔刷半径（格）
const SMOOTH_ITERS := 3     # CA 平滑迭代次数

const ATLAS_GRASS    := Vector2i(0, 0)
const ATLAS_PATH     := Vector2i(1, 0)
const ATLAS_FARMLAND := Vector2i(2, 0)
const ATLAS_STONE    := Vector2i(3, 0)


func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	_fill(img,  0, Color(0.30, 0.60, 0.22))  # 草地
	_fill(img, 16, Color(0.70, 0.58, 0.38))  # 小路
	_fill(img, 32, Color(0.38, 0.22, 0.08))  # 耕地
	_fill(img, 48, Color(0.52, 0.52, 0.55))  # 石地
	var tex := ImageTexture.create_from_image(img)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(16, 16)
	src.create_tile(Vector2i(0, 0))
	src.create_tile(Vector2i(1, 0))
	src.create_tile(Vector2i(2, 0))
	src.create_tile(Vector2i(3, 0))
	ts.add_source(src, SOURCE_ID)
	return ts


func generate(tilemap: TileMap, seed_val: int) -> void:
	# 地形主噪声：FBm 5 倍频，低频大地形
	var terrain := FastNoiseLite.new()
	terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain.seed = seed_val
	terrain.frequency = 0.018
	terrain.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain.fractal_octaves = 5
	terrain.fractal_lacunarity = 2.0
	terrain.fractal_gain = 0.5

	# Domain Warping：两张噪声分别扰动 X/Y 坐标，让边界有机弯曲
	var wx := _make_warp_noise(seed_val + 101)
	var wy := _make_warp_noise(seed_val + 202)

	# 耕地边界噪声：让出生点周边耕地轮廓不规则
	var farm := FastNoiseLite.new()
	farm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	farm.seed = seed_val + 303
	farm.frequency = 0.09

	# Step 1：生成原始地形
	var raw := _gen_raw(terrain, wx, wy, farm)
	# Step 2：CA 平滑，消除孤立格、让同类地块成片
	var smoothed := _smooth(raw)
	# Step 3：路径点连接（CA 之后雕刻，不会被平滑填平）
	_carve_paths(smoothed, seed_val)

	tilemap.clear()
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			tilemap.set_cell(0, Vector2i(x, y), SOURCE_ID, smoothed[_idx(x, y)])


# --- 内部步骤 ---

func _gen_raw(terrain: FastNoiseLite, wx: FastNoiseLite, wy: FastNoiseLite, farm: FastNoiseLite) -> Array:
	var map := []
	map.resize(MAP_SIZE * MAP_SIZE)
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var fx := float(x)
			var fy := float(y)
			# 用 warp 噪声扰动坐标再采样，使地形边界弯曲自然
			var sx := fx + wx.get_noise_2d(fx, fy) * WARP_STR
			var sy := fy + wy.get_noise_2d(fx + 137.0, fy + 137.0) * WARP_STR
			var n  := terrain.get_noise_2d(sx, sy)  # -1..1

			# 出生点附近耕地，边界由 farm 噪声扰动成有机形状
			var farm_r := 10.0 + farm.get_noise_2d(fx, fy) * 4.0
			var atlas: Vector2i
			if Vector2(fx, fy).length() < farm_r:
				atlas = ATLAS_FARMLAND
			elif n > 0.28:
				atlas = ATLAS_STONE
			else:
				atlas = ATLAS_GRASS
			map[_idx(x, y)] = atlas
	return map


func _smooth(map: Array) -> Array:
	# Cellular Automaton：多数邻居胜出（≥5/8），耕地不参与
	var cur := map.duplicate()
	var nxt := map.duplicate()
	for _iter in SMOOTH_ITERS:
		for y in range(-MAP_HALF, MAP_HALF):
			for x in range(-MAP_HALF, MAP_HALF):
				if cur[_idx(x, y)] == ATLAS_FARMLAND:
					nxt[_idx(x, y)] = ATLAS_FARMLAND
					continue
				var cg := 0
				var cs := 0
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx < -MAP_HALF or nx >= MAP_HALF or ny < -MAP_HALF or ny >= MAP_HALF:
							continue
						var t: Vector2i = cur[_idx(nx, ny)]
						if t == ATLAS_STONE:
							cs += 1
						elif t == ATLAS_GRASS:
							cg += 1
				if cs >= 5:
					nxt[_idx(x, y)] = ATLAS_STONE
				elif cg >= 5:
					nxt[_idx(x, y)] = ATLAS_GRASS
				else:
					nxt[_idx(x, y)] = cur[_idx(x, y)]
		cur = nxt.duplicate()
	return cur


func _carve_paths(map: Array, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# 出生点 + 5 个分布在外圈的地标点（角度略随机，距离 35-75 格）
	var landmarks: Array[Vector2i] = [Vector2i(0, 0)]
	for i in 5:
		var angle := float(i) / 5.0 * TAU + rng.randf_range(-0.25, 0.25)
		var dist  := rng.randf_range(35.0, 75.0)
		landmarks.append(Vector2i(roundi(cos(angle) * dist), roundi(sin(angle) * dist)))

	# 出生点 → 各地标（放射路）
	for i in range(1, landmarks.size()):
		_draw_path(map, landmarks[0], landmarks[i])
	# 相邻地标互联（环路）：1→2→3→4→5→1
	for i in range(1, landmarks.size()):
		_draw_path(map, landmarks[i], landmarks[i % (landmarks.size() - 1) + 1])


func _draw_path(map: Array, from: Vector2i, to: Vector2i) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	if steps == 0:
		return
	for i in steps + 1:
		var t  := float(i) / float(steps)
		var px := roundi(lerp(float(from.x), float(to.x), t))
		var py := roundi(lerp(float(from.y), float(to.y), t))
		for dy in range(-PATH_RADIUS, PATH_RADIUS + 1):
			for dx in range(-PATH_RADIUS, PATH_RADIUS + 1):
				if dx * dx + dy * dy > PATH_RADIUS * PATH_RADIUS:
					continue
				var bx := px + dx
				var by := py + dy
				if bx >= -MAP_HALF and bx < MAP_HALF and by >= -MAP_HALF and by < MAP_HALF:
					map[_idx(bx, by)] = ATLAS_PATH


func _make_warp_noise(seed_val: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_val
	n.frequency = 0.025
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 3
	return n


func _idx(x: int, y: int) -> int:
	return (y + MAP_HALF) * MAP_SIZE + (x + MAP_HALF)


func _fill(img: Image, offset_x: int, color: Color) -> void:
	for y in 16:
		for x in 16:
			img.set_pixel(offset_x + x, y, color)
