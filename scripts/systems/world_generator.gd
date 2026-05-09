extends Node

const MAP_HALF      := 100
const MAP_SIZE      := MAP_HALF * 2
const SOURCE_ID     := 0
const WARP_STR      := 18.0
const PATH_RADIUS   := 1
const SMOOTH_ITERS  := 3

# 地砖类型（整数，存入 map 数组）
const TILE_GRASS    := 0
const TILE_PATH     := 1
const TILE_FARMLAND := 2
const TILE_STONE    := 3
const TILE_TYPE_COUNT := 4

# Atlas 列 = 地砖类型，Atlas 行 = 变体
# 期望 ground_tiles.png 尺寸：64×64（4列×4行，每格16×16）
const VARIANT_COUNT   := 4
const TILE_ATLAS_PATH := "res://assets/sprites/environment/ground_tiles.png"


func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = _load_tile_texture()
	src.texture_region_size = Vector2i(16, 16)
	for col in TILE_TYPE_COUNT:
		for row in VARIANT_COUNT:
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, SOURCE_ID)
	return ts


func generate(tilemap: TileMap, seed_val: int) -> void:
	var terrain := FastNoiseLite.new()
	terrain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain.seed = seed_val
	terrain.frequency = 0.018
	terrain.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain.fractal_octaves = 5
	terrain.fractal_lacunarity = 2.0
	terrain.fractal_gain = 0.5

	var wx := _make_warp_noise(seed_val + 101)
	var wy := _make_warp_noise(seed_val + 202)

	var farm := FastNoiseLite.new()
	farm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	farm.seed = seed_val + 303
	farm.frequency = 0.09

	var raw      := _gen_raw(terrain, wx, wy, farm)
	var smoothed := _smooth(raw)
	_carve_paths(smoothed, seed_val)

	tilemap.clear()
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var tile_type: int = smoothed[_idx(x, y)]
			tilemap.set_cell(0, Vector2i(x, y), SOURCE_ID, _pick_variant(tile_type, x, y))


# --- 内部步骤 ---

func _gen_raw(terrain: FastNoiseLite, wx: FastNoiseLite, wy: FastNoiseLite, farm: FastNoiseLite) -> Array:
	var map := []
	map.resize(MAP_SIZE * MAP_SIZE)
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var fx := float(x)
			var fy := float(y)
			var sx := fx + wx.get_noise_2d(fx, fy) * WARP_STR
			var sy := fy + wy.get_noise_2d(fx + 137.0, fy + 137.0) * WARP_STR
			var n  := terrain.get_noise_2d(sx, sy)

			var farm_r := 10.0 + farm.get_noise_2d(fx, fy) * 4.0
			var tile: int
			if Vector2(fx, fy).length() < farm_r:
				tile = TILE_FARMLAND
			elif n > 0.28:
				tile = TILE_STONE
			else:
				tile = TILE_GRASS
			map[_idx(x, y)] = tile
	return map


func _smooth(map: Array) -> Array:
	var cur := map.duplicate()
	var nxt := map.duplicate()
	for _iter in SMOOTH_ITERS:
		for y in range(-MAP_HALF, MAP_HALF):
			for x in range(-MAP_HALF, MAP_HALF):
				if cur[_idx(x, y)] == TILE_FARMLAND:
					nxt[_idx(x, y)] = TILE_FARMLAND
					continue
				var cg := 0
				var cs := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx := x + dx
						var ny := y + dy
						if nx < -MAP_HALF or nx >= MAP_HALF or ny < -MAP_HALF or ny >= MAP_HALF:
							continue
						var t: int = cur[_idx(nx, ny)]
						if t == TILE_STONE:
							cs += 1
						elif t == TILE_GRASS:
							cg += 1
				if cs >= 5:
					nxt[_idx(x, y)] = TILE_STONE
				elif cg >= 5:
					nxt[_idx(x, y)] = TILE_GRASS
				else:
					nxt[_idx(x, y)] = cur[_idx(x, y)]
		cur = nxt.duplicate()
	return cur


func _carve_paths(map: Array, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var landmarks: Array[Vector2i] = [Vector2i(0, 0)]
	for i in 5:
		var angle := float(i) / 5.0 * TAU + rng.randf_range(-0.25, 0.25)
		var dist  := rng.randf_range(35.0, 75.0)
		landmarks.append(Vector2i(roundi(cos(angle) * dist), roundi(sin(angle) * dist)))
	for i in range(1, landmarks.size()):
		_draw_path(map, landmarks[0], landmarks[i])
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
					map[_idx(bx, by)] = TILE_PATH


# 位置哈希选变体行：同一位置固定结果，无明显格子/对角纹路
func _pick_variant(tile_type: int, x: int, y: int) -> Vector2i:
	var h := x * 374761393 + y * 668265263
	h ^= h >> 13
	h *= 1274126177
	h ^= h >> 16
	return Vector2i(tile_type, abs(h) % VARIANT_COUNT)


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


func _load_tile_texture() -> ImageTexture:
	var img := Image.load_from_file(TILE_ATLAS_PATH)
	if img:
		return ImageTexture.create_from_image(img)
	return _gen_fallback_texture()


# fallback：4列×4行，每列同色、每行稍微亮度不同
func _gen_fallback_texture() -> ImageTexture:
	var colors := [
		Color(0.30, 0.60, 0.22),  # grass
		Color(0.75, 0.60, 0.32),  # path
		Color(0.32, 0.18, 0.06),  # farmland
		Color(0.50, 0.50, 0.52),  # stone
	]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for col in 4:
		for row in VARIANT_COUNT:
			var base: Color = colors[col]
			var brightness := 1.0 + (row - 1) * 0.08
			var c := Color(
				clampf(base.r * brightness, 0.0, 1.0),
				clampf(base.g * brightness, 0.0, 1.0),
				clampf(base.b * brightness, 0.0, 1.0)
			)
			for py in 16:
				for px in 16:
					img.set_pixel(col * 16 + px, row * 16 + py, c)
	return ImageTexture.create_from_image(img)
