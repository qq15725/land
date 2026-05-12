extends Node

signal build_mode_entered(building: BuildingData)
signal build_mode_exited
signal building_placed(building: BuildingData, pos: Vector2)

var current_building: BuildingData = null
var is_building: bool = false

var _thumb_cache: Dictionary = {}

func _ready() -> void:
	pass

# 建造菜单缩略图：优先用 BuildingData.sprite_path，缺失时按 id 生成色块占位。
func get_thumb_texture(building: BuildingData) -> Texture2D:
	if building == null:
		return null
	if _thumb_cache.has(building.id):
		return _thumb_cache[building.id]
	var tex: Texture2D = null
	var path := building.sprite_path
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		tex = _make_placeholder_thumb(building.id)
	_thumb_cache[building.id] = tex
	return tex

func _make_placeholder_thumb(seed_id: String) -> ImageTexture:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var hue := absf(float(seed_id.hash() % 1000) / 1000.0)
	img.fill(Color.from_hsv(hue, 0.45, 0.65))
	var edge := Color.from_hsv(hue, 0.7, 0.35)
	for x in size:
		img.set_pixel(x, 0, edge)
		img.set_pixel(x, size - 1, edge)
	for y in size:
		img.set_pixel(0, y, edge)
		img.set_pixel(size - 1, y, edge)
	return ImageTexture.create_from_image(img)

func get_all_buildings() -> Array:
	return ItemDatabase.get_all_buildings()

func can_afford(building: BuildingData, player: Player) -> bool:
	if player == null or player.inventory == null:
		return false
	for cost in building.cost:
		if not player.inventory.has_item(cost["item"], cost["amount"]):
			return false
	return true

func enter_build_mode(building: BuildingData) -> void:
	current_building = building
	is_building = true
	build_mode_entered.emit(building)

func exit_build_mode() -> void:
	current_building = null
	is_building = false
	build_mode_exited.emit()

# 仅 server 应该调用（PlayerActions 已经做权威性判断）。
func place_building(pos: Vector2, player: Player) -> bool:
	if not is_building or current_building == null:
		return false
	if not can_afford(current_building, player):
		return false
	for cost in current_building.cost:
		player.inventory.remove_item(cost["item"], cost["amount"])
	building_placed.emit(current_building, pos)
	exit_build_mode()
	return true
