extends Node

# ── 地图尺寸 ──────────────────────────────────────────────────────────────────
const MAP_HALF := 100
const MAP_SIZE := MAP_HALF * 2

# ── Biome 噪声 ───────────────────────────────────────────────────────────────
const BIOME_FREQ := 0.008
var _biome_noise: FastNoiseLite = null

# ── 地形类型 ID ───────────────────────────────────────────────────────────────
const TERRAIN_GRASS    := 0
const TERRAIN_PATH     := 1
const TERRAIN_FARMLAND := 2
const TERRAIN_STONE    := 3
const TERRAIN_COUNT    := 4

# ── Godot Terrain 配置 ────────────────────────────────────────────────────────
# 所有地形共用 terrain_set=0，MATCH_CORNERS_AND_SIDES（blob，47 tile）
const TERRAIN_SET := 0

const TERRAIN_NAMES: Array[String] = ["草地", "小路", "耕地", "石地"]
const TERRAIN_COLORS: Array[Color] = [
	Color(0.29, 0.54, 0.16),
	Color(0.78, 0.66, 0.38),
	Color(0.48, 0.36, 0.17),
	Color(0.47, 0.47, 0.47),
]

# Atlas：每种地形一张独立图片，8 列 × 6 行（48 slot，47 用，最后一格留空）
const ATLAS_COLS := 8
const ATLAS_ROWS := 6
const TILE_SIZE  := Vector2i(64, 64)

const TERRAIN_ATLAS_PATHS: Array[String] = [
	"res://assets/sprites/environment/terrain_grass.png",
	"res://assets/sprites/environment/terrain_path.png",
	"res://assets/sprites/environment/terrain_farmland.png",
	"res://assets/sprites/environment/terrain_stone.png",
]

# ── 地形生成参数 ──────────────────────────────────────────────────────────────
const FARM_RADIUS  := 6
const STONE_HI     := 0.30
const STONE_FREQ   := 0.022
const WARP_STR     := 10.0
const WARP_FREQ    := 0.030
const SMOOTH_ITERS := 3
const PATH_RADIUS  := 1
const RING_POINTS  := 5


# ─────────────────────────────────────────────────────────────────────────────
#  TileSet 构建
# ─────────────────────────────────────────────────────────────────────────────

func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)

	ts.add_terrain_set()
	ts.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	for i in TERRAIN_COUNT:
		ts.add_terrain(TERRAIN_SET)
		ts.set_terrain_name(TERRAIN_SET, i, TERRAIN_NAMES[i])
		ts.set_terrain_color(TERRAIN_SET, i, TERRAIN_COLORS[i])

	# 枚举全部 47 种 blob tile，每种地形用独立 source
	var blob_tiles := _enumerate_blob_tiles()
	for terrain_id in TERRAIN_COUNT:
		var src := TileSetAtlasSource.new()
		src.texture = _load_terrain_texture(terrain_id)
		src.texture_region_size = TILE_SIZE
		for idx in blob_tiles.size():
			var coords := Vector2i(idx % ATLAS_COLS, idx / ATLAS_COLS)
			_setup_blob_tile(src, coords, terrain_id, blob_tiles[idx])
		ts.add_source(src, terrain_id)  # source_id = terrain_id

	return ts


# 枚举 47 种 blob 组合，返回有序 Array（与 atlas 行列一一对应）
# 顺序：sides 0-15，每个 sides 下 corner_mask 从 0 到 2^(有效角数)-1
func _enumerate_blob_tiles() -> Array:
	var tiles := []
	for sides in 16:
		var n := (sides >> 3) & 1
		var e := (sides >> 2) & 1
		var s := (sides >> 1) & 1
		var w := (sides >> 0) & 1
		# 只有两侧边都连通时，对应角才有意义（blob 规则）
		var relevant: Array = []
		if n and e: relevant.append("ne")
		if s and e: relevant.append("se")
		if s and w: relevant.append("sw")
		if n and w: relevant.append("nw")
		for corner_mask in (1 << relevant.size()):
			var tile := {n=n, e=e, s=s, w=w, ne=0, se=0, sw=0, nw=0}
			for ci in relevant.size():
				if (corner_mask >> ci) & 1:
					tile[relevant[ci]] = 1
			tiles.append(tile)
	return tiles  # 共 47 项


func _setup_blob_tile(src: TileSetAtlasSource, coords: Vector2i, terrain_id: int, b: Dictionary) -> void:
	src.create_tile(coords)
	var td: TileData = src.get_tile_data(coords, 0)
	td.terrain_set = TERRAIN_SET
	td.terrain     = terrain_id
	if b.n:  td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE,             terrain_id)
	if b.e:  td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE,           terrain_id)
	if b.s:  td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,          terrain_id)
	if b.w:  td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE,            terrain_id)
	if b.ne: td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,     terrain_id)
	if b.se: td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,  terrain_id)
	if b.sw: td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,   terrain_id)
	if b.nw: td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,      terrain_id)


# ─────────────────────────────────────────────────────────────────────────────
#  程序化地形生成
# ─────────────────────────────────────────────────────────────────────────────

func generate(tilemap: TileMap, seed_val: int) -> void:
	var map := _build_map(seed_val)
	map = _smooth(map)
	_carve_paths(map, seed_val)
	tilemap.clear()
	_apply_terrain(tilemap, map, MAP_SIZE, MAP_SIZE, -MAP_HALF, -MAP_HALF)
	init_biome_noise(seed_val)


# Biome 噪声基于世界 seed，与 tile 生成同步。
func init_biome_noise(seed_val: int) -> void:
	_biome_noise = _make_noise(seed_val + 1000, BIOME_FREQ, 2)


# 按世界坐标查 biome。预设地图模式下也用同一噪声（地图 id hash 作为 seed）。
func get_biome_at(pos: Vector2) -> BiomeData:
	var biomes := ItemDatabase.get_all_biomes()
	if biomes.is_empty():
		return null
	if _biome_noise == null:
		init_biome_noise(0)
	# 用 [TILE_SIZE] 把世界坐标转成噪声坐标
	var n := _biome_noise.get_noise_2d(pos.x, pos.y)
	# n ∈ [-1, 1] 等分给 N 个 biome
	var idx := clampi(int((n + 1.0) * 0.5 * biomes.size()), 0, biomes.size() - 1)
	return biomes[idx]


func _apply_terrain(tilemap: TileMap, map: Array, w: int, h: int, ox: int, oy: int) -> void:
	# 预建 blob bitmask → atlas坐标 查找表，绕开 set_cells_terrain_connect 的传播开销
	var lookup: Dictionary = {}
	var blob_tiles := _enumerate_blob_tiles()
	for idx in blob_tiles.size():
		var b: Dictionary = blob_tiles[idx]
		var key: int = (b.n << 7) | (b.e << 6) | (b.s << 5) | (b.w << 4) \
					 | (b.ne << 3) | (b.se << 2) | (b.sw << 1) | b.nw
		lookup[key] = Vector2i(idx % ATLAS_COLS, idx / ATLAS_COLS)

	var w1 := w - 1
	var h1 := h - 1
	for row in h:
		for col in w:
			var tid: int = map[row * w + col]
			var n_v: int  = 1 if (row > 0  and map[(row - 1) * w + col]     == tid) else 0
			var s_v: int  = 1 if (row < h1 and map[(row + 1) * w + col]     == tid) else 0
			var e_v: int  = 1 if (col < w1 and map[row * w + col + 1]       == tid) else 0
			var ww_v: int = 1 if (col > 0  and map[row * w + col - 1]       == tid) else 0
			var ne_v: int = 1 if (n_v == 1 and e_v  == 1 and map[(row-1)*w + col+1] == tid) else 0
			var se_v: int = 1 if (s_v == 1 and e_v  == 1 and map[(row+1)*w + col+1] == tid) else 0
			var sw_v: int = 1 if (s_v == 1 and ww_v == 1 and map[(row+1)*w + col-1] == tid) else 0
			var nw_v: int = 1 if (n_v == 1 and ww_v == 1 and map[(row-1)*w + col-1] == tid) else 0
			var key: int = (n_v << 7) | (e_v << 6) | (s_v << 5) | (ww_v << 4) \
						 | (ne_v << 3) | (se_v << 2) | (sw_v << 1) | nw_v
			tilemap.set_cell(0, Vector2i(ox + col, oy + row), tid, lookup.get(key, Vector2i.ZERO))


# ─────────────────────────────────────────────────────────────────────────────
#  图片地图生成
# ─────────────────────────────────────────────────────────────────────────────

func generate_from_image(tilemap: TileMap, image_path: String) -> Dictionary:
	var file_bytes := FileAccess.get_file_as_bytes(image_path)
	if file_bytes.is_empty():
		push_error("地图文件不存在: " + image_path)
		return {}
	var img := Image.new()
	if img.load_png_from_buffer(file_bytes) != OK:
		push_error("地图图片解析失败: " + image_path)
		return {}

	var img_w  := img.get_width()
	var img_h  := img.get_height()
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
				map[iy * img_w + ix] = TERRAIN_GRASS
			else:
				map[iy * img_w + ix] = _match_terrain_color(col)

	tilemap.clear()
	_apply_terrain(tilemap, map, img_w, img_h, -half_w, -half_h)
	init_biome_noise(image_path.hash())
	return markers


func _match_terrain_color(col: Color) -> int:
	const PALETTE := [
		[TERRAIN_GRASS,    0.290, 0.541, 0.157],
		[TERRAIN_PATH,     0.784, 0.659, 0.314],
		[TERRAIN_FARMLAND, 0.482, 0.361, 0.165],
		[TERRAIN_STONE,    0.502, 0.502, 0.502],
		[TERRAIN_STONE,    0.251, 0.251, 0.251],
	]
	var best := TERRAIN_GRASS
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
		["next_0", 1.0, 0.0, 0.0],
		["next_1", 1.0, 0.4, 0.0],
		["next_2", 1.0, 0.0, 1.0],
		["prev",   0.0, 0.0, 1.0],
	]
	for e in MARKERS:
		var d: float = (col.r - e[1]) * (col.r - e[1]) \
					 + (col.g - e[2]) * (col.g - e[2]) \
					 + (col.b - e[3]) * (col.b - e[3])
		if d < 0.003:
			return e[0]
	return ""


# ─────────────────────────────────────────────────────────────────────────────
#  地形噪声生成
# ─────────────────────────────────────────────────────────────────────────────

func _build_map(seed_val: int) -> Array:
	var n_terrain := _make_noise(seed_val,     STONE_FREQ, 4)
	var n_wx      := _make_noise(seed_val + 1, WARP_FREQ,  2)
	var n_wy      := _make_noise(seed_val + 2, WARP_FREQ,  2)
	var n_farm    := _make_noise(seed_val + 3, 0.08,       2)
	var map := []
	map.resize(MAP_SIZE * MAP_SIZE)
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var fx := float(x)
			var fy := float(y)
			var sx := fx + n_wx.get_noise_2d(fx, fy) * WARP_STR
			var sy := fy + n_wy.get_noise_2d(fx + 91.3, fy + 91.3) * WARP_STR
			var noise_val := n_terrain.get_noise_2d(sx, sy)
			var farm_r    := float(FARM_RADIUS) + n_farm.get_noise_2d(fx, fy) * 2.5
			if Vector2(fx, fy).length() < farm_r:
				map[_idx(x, y)] = TERRAIN_FARMLAND
			elif noise_val > STONE_HI:
				map[_idx(x, y)] = TERRAIN_STONE
			else:
				map[_idx(x, y)] = TERRAIN_GRASS
	return map


func _smooth(map: Array) -> Array:
	var cur := map.duplicate()
	var nxt  := map.duplicate()
	for _iter in SMOOTH_ITERS:
		for y in range(-MAP_HALF, MAP_HALF):
			for x in range(-MAP_HALF, MAP_HALF):
				if cur[_idx(x, y)] == TERRAIN_FARMLAND:
					nxt[_idx(x, y)] = TERRAIN_FARMLAND
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
						if t == TERRAIN_STONE: n_stone += 1
						elif t == TERRAIN_GRASS: n_grass += 1
				if n_stone * 2 > n_total:   nxt[_idx(x, y)] = TERRAIN_STONE
				elif n_grass * 2 > n_total: nxt[_idx(x, y)] = TERRAIN_GRASS
				else:                        nxt[_idx(x, y)] = cur[_idx(x, y)]
		# 引用交换代替 nxt.duplicate()，避免每次拷贝 40,000 元素
		var tmp: Array = cur
		cur = nxt
		nxt = tmp
	return cur


func _carve_paths(map: Array, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var origin := _farmland_exit(map, rng)
	var landmarks: Array[Vector2i] = [origin]
	for i in range(RING_POINTS):
		var angle := (float(i) / float(RING_POINTS)) * TAU + rng.randf_range(-0.2, 0.2)
		var dist  := rng.randf_range(35.0, 80.0)
		landmarks.append(Vector2i(
			clampi(roundi(cos(angle) * dist), -MAP_HALF + 4, MAP_HALF - 4),
			clampi(roundi(sin(angle) * dist), -MAP_HALF + 4, MAP_HALF - 4)
		))
	for i in range(1, landmarks.size()):
		_draw_path(map, origin, landmarks[i], false)
	for i in range(1, landmarks.size()):
		_draw_path(map, landmarks[i], landmarks[i % (landmarks.size() - 1) + 1], true)


func _farmland_exit(map: Array, rng: RandomNumberGenerator) -> Vector2i:
	var angle := rng.randf() * TAU
	for r in range(1, MAP_HALF):
		var px := roundi(cos(angle) * float(r))
		var py := roundi(sin(angle) * float(r))
		if px <= -MAP_HALF or px >= MAP_HALF or py <= -MAP_HALF or py >= MAP_HALF:
			break
		if map[_idx(px, py)] == TERRAIN_GRASS:
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
				if force or map[_idx(bx, by)] == TERRAIN_GRASS:
					map[_idx(bx, by)] = TERRAIN_PATH


# ─────────────────────────────────────────────────────────────────────────────
#  工具
# ─────────────────────────────────────────────────────────────────────────────

func _idx(x: int, y: int) -> int:
	return (y + MAP_HALF) * MAP_SIZE + (x + MAP_HALF)


func _make_noise(seed_val: int, freq: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type         = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed               = seed_val
	n.frequency          = freq
	n.fractal_type       = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves    = octaves
	n.fractal_lacunarity = 2.0
	n.fractal_gain       = 0.5
	return n


func _load_terrain_texture(terrain_id: int) -> ImageTexture:
	var path := TERRAIN_ATLAS_PATHS[terrain_id]
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img:
			return ImageTexture.create_from_image(img)
	return _gen_fallback_texture(terrain_id)


func _gen_fallback_texture(terrain_id: int) -> ImageTexture:
	const CELL := 64
	var img := Image.create(ATLAS_COLS * CELL, ATLAS_ROWS * CELL, false, Image.FORMAT_RGBA8)
	var base: Color = TERRAIN_COLORS[terrain_id]
	for row in ATLAS_ROWS:
		for col in ATLAS_COLS:
			var idx := row * ATLAS_COLS + col
			var c := base if idx < 47 else Color(0, 0, 0, 0)
			# 用轻微明度变化区分各 tile，方便无美术时目视调试
			c = c.lightened(float(idx % 8) * 0.02).darkened(float(idx / 8) * 0.03)
			for py in CELL:
				for px in CELL:
					img.set_pixel(col * CELL + px, row * CELL + py, c)
	return ImageTexture.create_from_image(img)
