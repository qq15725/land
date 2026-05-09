extends Node

const MAP_HALF  := 100
const SOURCE_ID := 0

const ATLAS_GRASS    := Vector2i(0, 0)
const ATLAS_PATH     := Vector2i(1, 0)
const ATLAS_FARMLAND := Vector2i(2, 0)
const ATLAS_STONE    := Vector2i(3, 0)


func create_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)

	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	_fill(img,  0, Color(0.30, 0.60, 0.22))
	_fill(img, 16, Color(0.70, 0.58, 0.38))
	_fill(img, 32, Color(0.38, 0.22, 0.08))
	_fill(img, 48, Color(0.52, 0.52, 0.55))

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
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_val
	noise.frequency = 0.025

	var path_noise := FastNoiseLite.new()
	path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	path_noise.seed = seed_val + 1337
	path_noise.frequency = 0.04

	tilemap.clear()
	for y in range(-MAP_HALF, MAP_HALF):
		for x in range(-MAP_HALF, MAP_HALF):
			var n  := noise.get_noise_2d(float(x), float(y))
			var pn := path_noise.get_noise_2d(float(x), float(y))
			var atlas := ATLAS_GRASS
			if absf(pn) < 0.055:
				atlas = ATLAS_PATH
			elif n > 0.40:
				atlas = ATLAS_STONE
			elif Vector2(x, y).length() < 14.0:
				atlas = ATLAS_FARMLAND
			tilemap.set_cell(0, Vector2i(x, y), SOURCE_ID, atlas)


func _fill(img: Image, offset_x: int, color: Color) -> void:
	for y in 16:
		for x in 16:
			img.set_pixel(offset_x + x, y, color)
