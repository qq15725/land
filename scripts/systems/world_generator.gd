extends Node

const MAP_HALF    := 100
const MAP_SIZE    := MAP_HALF * 2
const SOURCE_ID   := 0
const TILE_ATLAS_PATH := "res://assets/sprites/environment/ground_tiles.png"

const TILE_GRASS    := 0
const TILE_PATH     := 1
const TILE_FARMLAND := 2
const TILE_STONE    := 3
const TILE_TYPE_COUNT := 4

# Atlas：基础 16 列（mask 0–15）+ 变体列，× 4 行（地砖类型）
const MASK_COUNT    := 16
const VARIANT_COUNT := 3    # mask=15 的额外装饰变体（列 16-18）
const TOTAL_COLS    := MASK_COUNT + VARIANT_COUNT

# ── 可调参数 ─────────────────────────────────────────────
# 耕地：以原点为圆心，半径内为起始农场
const FARM_RADIUS    := 6     # 格，玩家视野约 ±10 格，6 刚好可以看到草地边界

# 石地：noise > STONE_HI → 石；noise < STONE_LO → 草；中间平滑带
const STONE_HI       := 0.30
const STONE_LO       := 0.15
const STONE_FREQ     := 0.022  # 频率越低石地区域越大越整块

# 域扭曲：让地形边缘不规则
const WARP_STR       := 10.0
const WARP_FREQ      := 0.030

# 平滑：CA 迭代让石地收敛成团块，减少孤立像素
const SMOOTH_ITERS   := 3

# 路径
const PATH_RADIUS    := 1     # 路宽：1 = 菱形 5 格
const RING_POINTS    := 5     # 路标点数（围绕耕地的放射路）
# ──────────────────────────────────────────────────────────


func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = _load_tile_texture()
	src.texture_region_size = Vector2i(64, 64)
	for col in range(TOTAL_COLS):
		for row in range(TILE_TYPE_COUNT):
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, SOURCE_ID)
	return ts


func generate(tilemap: TileMap, seed_val: int) -> void:
	var map := _build_map(seed_val)
	map = _smooth(map)
	_carve_paths(map, seed_val)

	tilemap.clear()
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var tile_type: int = map[_idx(x, y)]
			var mask := _compute_mask(map, x, y)
			tilemap.set_cell(0, Vector2i(x, y), SOURCE_ID, Vector2i(_variant_col(mask, x, y, seed_val), tile_type))


# ─────────────────────────────────────────────────────────
#  地形生成
# ─────────────────────────────────────────────────────────

func _build_map(seed_val: int) -> Array:
	# 主噪声（决定草/石分布）
	var n_terrain := _make_noise(seed_val, STONE_FREQ, 4)
	# 域扭曲（让地形边缘有机弯曲）
	var n_wx := _make_noise(seed_val + 1, WARP_FREQ, 2)
	var n_wy := _make_noise(seed_val + 2, WARP_FREQ, 2)
	# 耕地边缘微扰（让农场轮廓不是完美圆）
	var n_farm := _make_noise(seed_val + 3, 0.08, 2)

	var map := []
	map.resize(MAP_SIZE * MAP_SIZE)

	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var fx := float(x)
			var fy := float(y)

			# 域扭曲：采样坐标偏移
			var sx := fx + n_wx.get_noise_2d(fx, fy) * WARP_STR
			var sy := fy + n_wy.get_noise_2d(fx + 91.3, fy + 91.3) * WARP_STR

			var noise_val := n_terrain.get_noise_2d(sx, sy)  # [-1, 1]

			# 耕地：中心圆，边缘由噪声微扰让轮廓有机
			var farm_r := float(FARM_RADIUS) + n_farm.get_noise_2d(fx, fy) * 2.5
			if Vector2(fx, fy).length() < farm_r:
				map[_idx(x, y)] = TILE_FARMLAND
				continue

			# 石地：硬阈值，中间有一个 [STONE_LO, STONE_HI] 的过渡带，
			# 由平滑步骤再决定归属，减少随机孤岛
			if noise_val > STONE_HI:
				map[_idx(x, y)] = TILE_STONE
			else:
				map[_idx(x, y)] = TILE_GRASS

	return map


# CA 平滑：让草/石各自收敛成连续区域
func _smooth(map: Array) -> Array:
	var cur := map.duplicate()
	var nxt  := map.duplicate()

	for _iter in SMOOTH_ITERS:
		for y in range(-MAP_HALF, MAP_HALF):
			for x in range(-MAP_HALF, MAP_HALF):
				# 耕地固定不动
				if cur[_idx(x, y)] == TILE_FARMLAND:
					nxt[_idx(x, y)] = TILE_FARMLAND
					continue

				var n_stone := 0
				var n_grass := 0
				var n_total := 0

				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx2 := x + dx
						var ny2 := y + dy
						if nx2 < -MAP_HALF or nx2 >= MAP_HALF or ny2 < -MAP_HALF or ny2 >= MAP_HALF:
							continue
						n_total += 1
						var t: int = cur[_idx(nx2, ny2)]
						if t == TILE_STONE:
							n_stone += 1
						elif t == TILE_GRASS:
							n_grass += 1

				# 比例判断（兼容边界格邻居少的情况）
				if n_stone * 2 > n_total:
					nxt[_idx(x, y)] = TILE_STONE
				elif n_grass * 2 > n_total:
					nxt[_idx(x, y)] = TILE_GRASS
				else:
					nxt[_idx(x, y)] = cur[_idx(x, y)]

		cur = nxt.duplicate()

	return cur


# ─────────────────────────────────────────────────────────
#  路径生成
# ─────────────────────────────────────────────────────────

func _carve_paths(map: Array, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# 找耕地到草地的边界点作为路的起点
	var origin := _farmland_exit(map, rng)

	# 在地图中分散放置若干路标点
	var landmarks: Array[Vector2i] = [origin]
	for i in range(RING_POINTS):
		var angle := (float(i) / float(RING_POINTS)) * TAU + rng.randf_range(-0.2, 0.2)
		var dist  := rng.randf_range(35.0, 80.0)
		var lx := clampi(roundi(cos(angle) * dist), -MAP_HALF + 4, MAP_HALF - 4)
		var ly := clampi(roundi(sin(angle) * dist), -MAP_HALF + 4, MAP_HALF - 4)
		landmarks.append(Vector2i(lx, ly))

	# 放射路：从起点到各地标，遇石绕行（不强行穿山）
	for i in range(1, landmarks.size()):
		_draw_path(map, origin, landmarks[i], false)

	# 环形路：地标首尾相连，强制连通
	for i in range(1, landmarks.size()):
		var j := i % (landmarks.size() - 1) + 1
		_draw_path(map, landmarks[i], landmarks[j], true)


func _farmland_exit(map: Array, rng: RandomNumberGenerator) -> Vector2i:
	# 沿随机角度射线，找到耕地与草地的边界
	var angle := rng.randf() * TAU
	for r in range(1, MAP_HALF):
		var px := roundi(cos(angle) * float(r))
		var py := roundi(sin(angle) * float(r))
		if px <= -MAP_HALF or px >= MAP_HALF or py <= -MAP_HALF or py >= MAP_HALF:
			break
		if map[_idx(px, py)] == TILE_GRASS:
			return Vector2i(px, py)
	return Vector2i(0, 0)


func _draw_path(map: Array, from: Vector2i, to: Vector2i, force: bool) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	if steps == 0:
		return
	for i in range(steps + 1):
		var t  := float(i) / float(steps)
		var px := roundi(lerp(float(from.x), float(to.x), t))
		var py := roundi(lerp(float(from.y), float(to.y), t))
		for dy in range(-PATH_RADIUS, PATH_RADIUS + 1):
			for dx in range(-PATH_RADIUS, PATH_RADIUS + 1):
				if dx * dx + dy * dy > PATH_RADIUS * PATH_RADIUS:
					continue
				var bx := px + dx
				var by := py + dy
				if bx < -MAP_HALF or bx >= MAP_HALF or by < -MAP_HALF or by >= MAP_HALF:
					continue
				var cur_tile: int = map[_idx(bx, by)]
				# 放射路不覆盖石地（自然绕山）；环形路强制覆盖保证连通
				if force or cur_tile == TILE_GRASS:
					map[_idx(bx, by)] = TILE_PATH


# ─────────────────────────────────────────────────────────
#  图片地图生成
# ─────────────────────────────────────────────────────────

# 返回地图中所有标记像素的世界坐标，key: "next_0"/"next_1"/"next_2"/"prev"
func generate_from_image(tilemap: TileMap, image_path: String) -> Dictionary:
	var file_bytes := FileAccess.get_file_as_bytes(image_path)
	if file_bytes.is_empty():
		push_error("地图文件不存在: " + image_path)
		return {}

	var img := Image.new()
	if img.load_png_from_buffer(file_bytes) != OK:
		push_error("地图图片解析失败: " + image_path)
		return {}

	var img_w := img.get_width()
	var img_h := img.get_height()
	var half_w := img_w / 2
	var half_h := img_h / 2

	var map: Array[int] = []
	map.resize(img_w * img_h)
	var markers: Dictionary = {}

	for iy in img_h:
		for ix in img_w:
			var col := img.get_pixel(ix, iy)
			var marker := _match_marker_color(col)
			if marker != "":
				markers[marker] = Vector2i(ix - half_w, iy - half_h)
				map[iy * img_w + ix] = TILE_GRASS
			else:
				map[iy * img_w + ix] = _match_terrain_color(col)

	var map_seed := hash(image_path)
	tilemap.clear()
	for iy in img_h:
		for ix in img_w:
			var tile_type: int = map[iy * img_w + ix]
			var mask := _compute_mask_img(map, ix, iy, img_w, img_h)
			tilemap.set_cell(0, Vector2i(ix - half_w, iy - half_h), SOURCE_ID,
					Vector2i(_variant_col(mask, ix, iy, map_seed), tile_type))

	return markers


func _match_terrain_color(col: Color) -> int:
	const PALETTE := [
		[TILE_GRASS,    0.290, 0.541, 0.157],
		[TILE_PATH,     0.784, 0.659, 0.314],
		[TILE_FARMLAND, 0.482, 0.361, 0.165],
		[TILE_STONE,    0.502, 0.502, 0.502],
		[TILE_STONE,    0.251, 0.251, 0.251],
	]
	var best := TILE_GRASS
	var best_d := 1e9
	for e in PALETTE:
		var d: float = (col.r - e[1]) * (col.r - e[1]) \
					 + (col.g - e[2]) * (col.g - e[2]) \
					 + (col.b - e[3]) * (col.b - e[3])
		if d < best_d:
			best_d = d
			best = int(e[0])
	return best


func _match_marker_color(col: Color) -> String:
	const MARKERS := [
		["next_0", 1.0,   0.0,   0.0],
		["next_1", 1.0,   0.400, 0.0],
		["next_2", 1.0,   0.0,   1.0],
		["prev",   0.0,   0.0,   1.0],
	]
	for e in MARKERS:
		var d: float = (col.r - e[1]) * (col.r - e[1]) \
					 + (col.g - e[2]) * (col.g - e[2]) \
					 + (col.b - e[3]) * (col.b - e[3])
		if d < 0.003:
			return e[0]
	return ""


func _compute_mask_img(map: Array, ix: int, iy: int, w: int, h: int) -> int:
	var t: int = map[iy * w + ix]
	var mask := 0
	if iy > 0     and map[(iy - 1) * w + ix      ] == t: mask |= 8
	if ix < w - 1 and map[iy       * w + (ix + 1)] == t: mask |= 4
	if iy < h - 1 and map[(iy + 1) * w + ix      ] == t: mask |= 2
	if ix > 0     and map[iy       * w + (ix - 1)] == t: mask |= 1
	return mask


# ─────────────────────────────────────────────────────────
#  工具
# ─────────────────────────────────────────────────────────

func _compute_mask(map: Array, x: int, y: int) -> int:
	var t: int = map[_idx(x, y)]
	var mask := 0
	if y > -MAP_HALF and map[_idx(x, y - 1)] == t:
		mask |= 8
	if x < MAP_HALF - 1 and map[_idx(x + 1, y)] == t:
		mask |= 4
	if y < MAP_HALF - 1 and map[_idx(x, y + 1)] == t:
		mask |= 2
	if x > -MAP_HALF and map[_idx(x - 1, y)] == t:
		mask |= 1
	return mask


# mask=15（四周全同地形）时按位置哈希选变体列，其他 mask 原样返回
# 用乘法哈希而非 RNG，确保每格结果与遍历顺序无关
func _variant_col(mask: int, x: int, y: int, seed_val: int) -> int:
	if mask != 15:
		return mask
	var h := (x * 1973 + y * 9277 + seed_val * 4099) & 0x7FFFFFFF
	var roll := h % 100
	if roll < 60:
		return 15   # 60% 基础格
	if roll < 82:
		return 16   # 22% 草丛变体
	if roll < 94:
		return 17   # 12% 野花变体
	return 18       # 6%  噪点变体


func _make_noise(seed_val: int, freq: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type          = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed                = seed_val
	n.frequency           = freq
	n.fractal_type        = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves     = octaves
	n.fractal_lacunarity  = 2.0
	n.fractal_gain        = 0.5
	return n


func _idx(x: int, y: int) -> int:
	return (y + MAP_HALF) * MAP_SIZE + (x + MAP_HALF)


func _load_tile_texture() -> ImageTexture:
	var img := Image.load_from_file(TILE_ATLAS_PATH)
	if img:
		return ImageTexture.create_from_image(img)
	return _gen_fallback_texture()


func _gen_fallback_texture() -> ImageTexture:
	var colors := [
		Color(0.29, 0.54, 0.16),
		Color(0.78, 0.63, 0.38),
		Color(0.29, 0.16, 0.06),
		Color(0.47, 0.47, 0.47),
	]
	const CELL := 64
	var img := Image.create(TOTAL_COLS * CELL, TILE_TYPE_COUNT * CELL, false, Image.FORMAT_RGBA8)
	for col in range(TOTAL_COLS):
		for row in range(TILE_TYPE_COUNT):
			var c: Color = colors[row]
			if col >= MASK_COUNT:
				c = c.darkened(0.12)  # 变体列稍暗，便于无美术时目视区分
			for py in range(CELL):
				for px in range(CELL):
					img.set_pixel(col * CELL + px, row * CELL + py, c)
	return ImageTexture.create_from_image(img)
