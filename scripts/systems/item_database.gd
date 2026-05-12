extends Node

const ICON_SHEET_PATH := "res://assets/sprites/items/icons.png"
const ICON_GRID_COLS := 8
const ICON_GRID_ROWS := 4

var _icon_size: int = 32

var _items: Dictionary = {}
var _buildings: Array = []
var _recipes: Array = []
var _crops: Array = []
var _animals: Dictionary = {}
var _creatures: Dictionary = {}
var _merchants: Array = []
var _resource_nodes: Array = []
var _biomes: Array = []

var _icon_sheet: Texture2D = null
var _icon_cache: Dictionary = {}

func _ready() -> void:
	_icon_sheet = load(ICON_SHEET_PATH) as Texture2D
	if _icon_sheet:
		_icon_size = _icon_sheet.get_width() / ICON_GRID_COLS
	_load_items()
	_load_buildings()
	_load_recipes()
	_load_crops()
	_load_animals()
	_load_creatures()
	_load_merchants()
	_load_resource_nodes()
	_load_biomes()
	_resolve_refs()

func _load_items() -> void:
	for d in _read_json("res://data/items.json"):
		var item := ItemData.new()
		item.id = d.get("id", "")
		item.display_name = d.get("display_name", "")
		item.icon_path = d.get("icon_path", "")
		item.max_stack = d.get("max_stack", 64)
		item.description = d.get("description", "")
		item.heal_amount = d.get("heal_amount", 0.0)
		var c: Array = d.get("color", [1.0, 1.0, 1.0, 1.0])
		item.color = Color(c[0], c[1], c[2], c[3])
		var g: Array = d.get("icon_grid", [0, 0])
		item.icon_grid = Vector2i(int(g[0]), int(g[1]))
		_items[item.id] = item

func _load_buildings() -> void:
	for d in _read_json("res://data/buildings.json"):
		var b := BuildingData.new()
		b.id = d.get("id", "")
		b.display_name = d.get("display_name", "")
		b.category = d.get("category", "building")
		b.scene_path = d.get("scene_path", "")
		b.sprite_path = d.get("sprite_path", "res://assets/sprites/buildings/%s.png" % b.id)
		b.animal_id = d.get("animal_id", "")
		b.connects = d.get("connects", false)
		b.is_gate = d.get("is_gate", false)
		b.custom_render = d.get("custom_render", false)
		for c in d.get("cost", []):
			b.cost.append({"item_id": c["item_id"], "amount": c["amount"], "item": null})
		_buildings.append(b)

func _load_recipes() -> void:
	for d in _read_json("res://data/recipes.json"):
		var r := RecipeData.new()
		r.id = d.get("id", "")
		r.output_item_id = d.get("output_item_id", "")
		r.output_amount = d.get("output_amount", 1)
		r.required_station = d.get("required_station", "")
		for ing in d.get("ingredients", []):
			r.ingredients.append({"item_id": ing["item_id"], "amount": ing["amount"], "item": null})
		_recipes.append(r)

func _load_crops() -> void:
	for d in _read_json("res://data/crops.json"):
		var c := CropData.new()
		c.id = d.get("id", "")
		c.display_name = d.get("display_name", "")
		c.seed_item_id = d.get("seed_item_id", "")
		c.output_item_id = d.get("output_item_id", "")
		c.output_amount = d.get("output_amount", 1)
		c.growth_time = d.get("growth_time", 20.0)
		c.bonus_drop = d.get("bonus_drop", {})
		c.allowed_seasons = d.get("allowed_seasons", [])
		_crops.append(c)

func _load_animals() -> void:
	for d in _read_json("res://data/animals.json"):
		var a := AnimalData.new()
		a.id = d.get("id", "")
		a.display_name = d.get("display_name", "")
		a.sprite_path = "res://assets/animals/%s.png" % a.id
		a.feed_item_id = d.get("feed_item_id", "")
		a.produce_item_id = d.get("produce_item_id", "")
		a.produce_amount = d.get("produce_amount", 1)
		a.produce_time = d.get("produce_time", 30.0)
		a.wander_radius = d.get("wander_radius", 60.0)
		var c: Array = d.get("color", [1.0, 1.0, 1.0, 1.0])
		a.color = Color(c[0], c[1], c[2], c[3])
		_animals[a.id] = a

func _load_creatures() -> void:
	for d in _read_json("res://data/creatures.json"):
		var c := CreatureData.new()
		c.id = d.get("id", "")
		c.display_name = d.get("display_name", "")
		c.sprite_path = "res://assets/creatures/%s.png" % c.id
		c.max_health = d.get("max_health", 30.0)
		c.move_speed = d.get("move_speed", 60.0)
		c.attack_damage = d.get("attack_damage", 8.0)
		c.attack_range = d.get("attack_range", 28.0)
		c.attack_cooldown = d.get("attack_cooldown", 1.2)
		c.detection_radius = d.get("detection_radius", 150.0)
		c.wander_radius = d.get("wander_radius", 200.0)
		c.sprite_scale = d.get("sprite_scale", 1.0)
		c.drop_table = d.get("drop_table", [])
		_creatures[c.id] = c

func _load_merchants() -> void:
	for d in _read_json("res://data/trades.json"):
		var m := MerchantData.new()
		m.id = d.get("id", "")
		m.display_name = d.get("display_name", "商人")
		m.visit_interval = d.get("visit_interval", 180.0)
		m.stay_duration = d.get("stay_duration", 90.0)
		var c: Array = d.get("color", [0.4, 0.6, 0.9, 1.0])
		m.color = Color(c[0], c[1], c[2], c[3])
		for t in d.get("trades", []):
			m.trades.append({
				"give_item_id": t["give_item_id"],
				"give_amount": t["give_amount"],
				"receive_item_id": t["receive_item_id"],
				"receive_amount": t["receive_amount"],
				"give_item": null,
				"receive_item": null,
			})
		_merchants.append(m)

func _load_resource_nodes() -> void:
	for d in _read_json("res://data/resources.json"):
		var n := ResourceNodeData.new()
		n.id = d.get("id", "")
		n.display_name = d.get("display_name", "")
		n.drop_item_id = d.get("drop_item_id", "")
		n.drop_amount = d.get("drop_amount", 3)
		n.respawn_time = d.get("respawn_time", 30.0)
		n.tool_required = d.get("tool_required", "")
		n.spawn_weight = d.get("spawn_weight", 1.0)
		var cs: Array = d.get("collision_size", [16, 16])
		n.collision_size = Vector2(cs[0], cs[1])
		n.collision_offset_y = d.get("collision_offset_y", 0.0)
		n.visual_offset_y = d.get("visual_offset_y", 0.0)
		n.frame_height = d.get("frame_height", 64)
		n.drop_table = d.get("drop_table", [])
		_resource_nodes.append(n)

func _load_biomes() -> void:
	for d in _read_json("res://data/biomes.json"):
		var b := BiomeData.new()
		b.id = d.get("id", "")
		b.display_name = d.get("display_name", "")
		b.spawn_density = float(d.get("spawn_density", 1.0))
		b.resource_weights = d.get("resource_weights", {})
		b.creature_weights = d.get("creature_weights", {})
		_biomes.append(b)

func _resolve_refs() -> void:
	for b in _buildings:
		for c in b.cost:
			c["item"] = _items.get(c["item_id"])
	for r in _recipes:
		r.output_item = _items.get(r.output_item_id)
		for ing in r.ingredients:
			ing["item"] = _items.get(ing["item_id"])
	for c in _crops:
		c.seed_item = _items.get(c.seed_item_id)
		c.output_item = _items.get(c.output_item_id)
	for a in _animals.values():
		a.feed_item = _items.get(a.feed_item_id)
		a.produce_item = _items.get(a.produce_item_id)
	for m in _merchants:
		for t in m.trades:
			t["give_item"] = _items.get(t["give_item_id"])
			t["receive_item"] = _items.get(t["receive_item_id"])
	for n in _resource_nodes:
		n.drop_item = _items.get(n.drop_item_id)

# --- 查询接口 ---

func get_item(id: String) -> ItemData:
	return _items.get(id, null)

func get_icon_size() -> int:
	return _icon_size

# 返回 item 在图标表中的 AtlasTexture（已缓存）。
# icons.png 缺失或字段为空时回退到一个纯色占位 ImageTexture。
func get_item_icon(item: ItemData) -> Texture2D:
	if item == null:
		return null
	var key: String = item.id
	if _icon_cache.has(key):
		return _icon_cache[key]
	var tex: Texture2D
	if _icon_sheet:
		var atlas := AtlasTexture.new()
		atlas.atlas = _icon_sheet
		atlas.region = Rect2(
			item.icon_grid.x * _icon_size,
			item.icon_grid.y * _icon_size,
			_icon_size, _icon_size
		)
		tex = atlas
	else:
		tex = _make_color_icon(item.color)
	_icon_cache[key] = tex
	return tex

func _make_color_icon(c: Color) -> ImageTexture:
	var img := Image.create(_icon_size, _icon_size, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func get_crop_for_seed(item: ItemData) -> CropData:
	for crop in _crops:
		if (crop as CropData).seed_item == item:
			return crop
	return null

func get_crop_by_id(id: String) -> CropData:
	for crop in _crops:
		if (crop as CropData).id == id:
			return crop
	return null

func get_animal(id: String) -> AnimalData:
	return _animals.get(id, null)

func get_creature(id: String) -> CreatureData:
	return _creatures.get(id, null)

func get_all_creatures() -> Array:
	return _creatures.values()

func get_building(id: String) -> BuildingData:
	for b in _buildings:
		if (b as BuildingData).id == id:
			return b
	return null

func get_all_buildings() -> Array:
	return _buildings

func get_all_recipes() -> Array:
	return _recipes

func get_all_merchants() -> Array:
	return _merchants

func get_all_resource_nodes() -> Array:
	return _resource_nodes

func get_resource_node(id: String) -> ResourceNodeData:
	for n in _resource_nodes:
		if n.id == id:
			return n
	return null

func get_all_biomes() -> Array:
	return _biomes

func get_biome(id: String) -> BiomeData:
	for b in _biomes:
		if b.id == id:
			return b
	return null

func _read_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("JSON 文件不存在: " + path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var result: Variant = JSON.parse_string(file.get_as_text())
	if result == null:
		push_error("JSON 解析失败: " + path)
		return []
	return result as Array
