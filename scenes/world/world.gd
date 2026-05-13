extends Node2D

const CreatureScene := preload("res://scenes/entities/creature/creature.tscn")
const ResourceNodeScene := preload("res://scenes/world/resource.tscn")
const PlayerScene := preload("res://scenes/entities/player/player.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const InventoryUIScene := preload("res://scenes/ui/inventory_ui.tscn")
const CraftingUIScene := preload("res://scenes/ui/crafting_ui.tscn")
const BuildMenuUIScene := preload("res://scenes/ui/build_menu_ui.tscn")
const StorageUIScene := preload("res://scenes/ui/storage_ui.tscn")
const TradeUIScene := preload("res://scenes/ui/trade_ui.tscn")
const SkillUIScene := preload("res://scenes/ui/skill_ui.tscn")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")

# 所有动态 spawn 的 scene 路径，server 端 add_child 后 MultiplayerSpawner
# 会自动通知 client 端 spawn 对应 scene（同节点路径下）。
const SPAWNABLE_SCENES: PackedStringArray = [
	"res://scenes/entities/player/player.tscn",
	"res://scenes/entities/creature/creature.tscn",
	"res://scenes/entities/drop_item/drop_item.tscn",
	"res://scenes/world/resource.tscn",
	"res://scenes/farm/farm_plot.tscn",
	"res://scenes/farm/animal.tscn",
]

const SPAWN_RADIUS_TILES := 64           # 资源覆盖半径（tile）
const ACTIVE_RADIUS_TILES := 64          # 玩家附近多少 tile 范围内的 chunk 保持 active
const CHUNK_UPDATE_INTERVAL := 1.0       # 每 N 秒检查一次 chunk
const AUTOSAVE_INTERVAL := 300.0         # 自动保存间隔（秒）
const MIN_SPAWN_DIST := 80.0
const CREATURE_SPAWN_RADIUS := 500.0
const CREATURE_MIN_DIST := 200.0

var _chunk_update_timer: float = 0.0
var _autosave_timer: float = 0.0

const TILE_SIZE := 16.0
const PORTAL_RADIUS := 2        # 触发范围（格）
const PORTAL_COOLDOWN := 1.5    # 切换后冷却（秒），防止瞬间反复触发

@onready var y_sort_layer: Node2D = $YSortLayer
@onready var player: Player = $YSortLayer/Player

var _build_preview: Node2D = null
var _hud: Control = null
var _day_overlay: ColorRect = null
var _canvas_modulate: CanvasModulate = null
var _pause_menu: Control = null

var terrain_map: TileMap = null
var terrain_seed: int = 0
var map_markers: Dictionary = {}   # "next_0"/"next_1"/"next_2"/"prev" → Vector2i
var current_map_id: String = ""    # 当前地图 id，如 "0"、"0-1"
var _portal_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("world")
	ChunkManager.clear_state()
	_setup_terrain()
	_setup_multiplayer_spawner()
	# 静态 Player 节点 = 本地 host 的玩家（peer_id = 自己的 peer_id）
	player.peer_id = Network.local_peer_id()
	_setup_ui()
	if SaveSystem.slot_exists(GameManager.current_save_slot):
		await SaveSystem.load_save(GameManager.current_save_slot, self)
	else:
		_load_map("0")
	_update_chunks()
	BuildingSystem.build_mode_entered.connect(_on_build_mode_entered)
	BuildingSystem.build_mode_exited.connect(_on_build_mode_exited)
	BuildingSystem.building_placed.connect(_on_building_placed)
	TimeSystem.night_started.connect(_on_night_started)
	TimeSystem.day_started.connect(_on_day_started)
	TimeSystem.day_started.connect(func(_d): _autosave("新的一天"))
	SoundSystem.play_world_bgm()
	# 多人：监听玩家进出
	Network.peer_joined.connect(_on_peer_joined)
	Network.peer_left.connect(_on_peer_left)

# 在 YSortLayer 挂 MultiplayerSpawner，server 在该层 add_child 会自动同步到 client。
# 仅多人模式启用：单机下 OfflineMultiplayerPeer 不需要同步，挂 spawner 反而会
# 拦截 ChunkManager 等动态 add_child 的节点（要求 force_readable_name=true）。
func _setup_multiplayer_spawner() -> void:
	if Network.is_singleplayer():
		return
	var spawner := MultiplayerSpawner.new()
	spawner.name = "EntitySpawner"
	spawner.spawn_path = y_sort_layer.get_path()
	for scene_path in SPAWNABLE_SCENES:
		spawner.add_spawnable_scene(scene_path)
	add_child(spawner)

func _on_peer_joined(peer_id: int) -> void:
	if not Network.is_server():
		return
	# 在 YSortLayer 下 spawn 一个 Player 给该 peer
	var p := PlayerScene.instantiate() as Player
	p.peer_id = peer_id
	p.name = "Player_%d" % peer_id
	p.global_position = player.global_position + Vector2(randf_range(-32, 32), randf_range(-32, 32))
	y_sort_layer.add_child(p, true)

func _on_peer_left(peer_id: int) -> void:
	if not Network.is_server():
		return
	for p in y_sort_layer.get_children():
		if p is Player and (p as Player).peer_id == peer_id:
			p.queue_free()
			return

# 找到本地玩家（peer_id 匹配自己的 player 节点）并初始化 HUD
func _setup_hud_for_local_player() -> void:
	var local := _find_local_player()
	if local != null:
		_hud.setup(local.health, local.inventory)
		return
	# 还没 spawn 到本地玩家（client 端），监听 spawner 等待
	var spawner: MultiplayerSpawner = get_node_or_null("EntitySpawner")
	if spawner:
		spawner.spawned.connect(_on_entity_spawned)

func _find_local_player() -> Player:
	for p in get_tree().get_nodes_in_group("player"):
		var pl := p as Player
		if pl and pl.peer_id == Network.local_peer_id():
			return pl
	return null

func _on_entity_spawned(node: Node) -> void:
	if node is Player and (node as Player).peer_id == Network.local_peer_id():
		_hud.setup((node as Player).health, (node as Player).inventory)

func _load_map(map_id: String) -> void:
	current_map_id = map_id
	if GameManager.world_type == "preset":
		var img_path := "res://assets/maps/" + map_id + ".png"
		if FileAccess.file_exists(img_path):
			map_markers = WorldGenerator.generate_from_image(terrain_map, img_path)
		else:
			push_error("预设地图不存在: " + img_path + "，回退到程序化生成")
			_gen_random()
	else:
		_gen_random()

func _gen_random() -> void:
	terrain_seed = randi()
	WorldGenerator.generate(terrain_map, terrain_seed)


func _check_portals(delta: float) -> void:
	if map_markers.is_empty() or GameManager.world_type != "preset":
		return
	if _portal_cooldown > 0.0:
		_portal_cooldown -= delta
		return
	var pt := Vector2i(
		floori(player.global_position.x / TILE_SIZE),
		floori(player.global_position.y / TILE_SIZE)
	)
	for key in map_markers:
		var mt: Vector2i = map_markers[key]
		if absi(pt.x - mt.x) <= PORTAL_RADIUS and absi(pt.y - mt.y) <= PORTAL_RADIUS:
			_travel(key)
			return


func _travel(marker_key: String) -> void:
	var target_id: String
	var spawn_key: String

	if marker_key.begins_with("next_"):
		var idx := marker_key.substr(5)          # "0" / "1" / "2"
		target_id = current_map_id + "-" + idx
		spawn_key = "prev"
	elif marker_key == "prev":
		if not "-" in current_map_id:
			return                               # 根节点无父级
		var last_dash := current_map_id.rfind("-")
		var last_idx := current_map_id.substr(last_dash + 1)
		target_id = current_map_id.substr(0, last_dash)
		spawn_key = "next_" + last_idx
	else:
		return

	# 清除当前地图的临时实体（地图切换重置 chunk 状态）
	for node in y_sort_layer.get_children():
		if node is ResourceNode or node is Creature:
			node.queue_free()
	ChunkManager.clear_state()

	_load_map(target_id)
	_update_chunks()
	_portal_cooldown = PORTAL_COOLDOWN

	# 传送玩家到目标地图入口
	if spawn_key in map_markers:
		var st: Vector2i = map_markers[spawn_key]
		player.global_position = Vector2(
			st.x * TILE_SIZE + TILE_SIZE * 0.5,
			st.y * TILE_SIZE + TILE_SIZE * 0.5
		)


func _setup_terrain() -> void:
	terrain_map = TileMap.new()
	terrain_map.name = "TerrainMap"
	terrain_map.tile_set = WorldGenerator.create_tileset()
	terrain_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(terrain_map)
	move_child(terrain_map, 0)
	# 全局色温调节（影响所有 CanvasItem，不影响 CanvasLayer 上的 UI）
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.color = Color.WHITE
	add_child(_canvas_modulate)

func _setup_ui() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)

	_day_overlay = ColorRect.new()
	_day_overlay.color = Color(0.0, 0.0, 0.1, 0.0)
	_day_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_day_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(_day_overlay)

	_hud = HUDScene.instantiate()
	hud_layer.add_child(_hud)
	# 等找到本地玩家再 setup HUD（多人 client 时本地玩家是 spawner 后 add 的）
	_setup_hud_for_local_player()

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var inventory_ui := InventoryUIScene.instantiate()
	ui_layer.add_child(inventory_ui)
	inventory_ui.setup(player.inventory)

	var crafting_ui := CraftingUIScene.instantiate()
	ui_layer.add_child(crafting_ui)
	crafting_ui.setup(player.inventory)

	var build_menu := BuildMenuUIScene.instantiate()
	ui_layer.add_child(build_menu)
	build_menu.setup(player.inventory)

	var storage_ui := StorageUIScene.instantiate()
	ui_layer.add_child(storage_ui)
	storage_ui.setup(player.inventory)

	var trade_ui := TradeUIScene.instantiate()
	ui_layer.add_child(trade_ui)
	trade_ui.setup(player.inventory)

	var skill_ui := SkillUIScene.instantiate()
	ui_layer.add_child(skill_ui)

	_pause_menu = PauseMenuScene.instantiate()
	ui_layer.add_child(_pause_menu)

	var mobile_controls: Node = load("res://scenes/ui/mobile_controls.gd").new()
	add_child(mobile_controls)

func _process(delta: float) -> void:
	if _build_preview:
		var mpos := get_global_mouse_position()
		if BuildingSystem.current_building and BuildingSystem.current_building.connects:
			mpos = mpos.snapped(Vector2(TILE_SIZE, TILE_SIZE))
		_build_preview.global_position = mpos
	_update_day_overlay()
	_check_portals(delta)
	_chunk_update_timer += delta
	if _chunk_update_timer >= CHUNK_UPDATE_INTERVAL:
		_chunk_update_timer = 0.0
		_update_chunks()
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_autosave("自动保存")

func _autosave(reason: String) -> void:
	SaveSystem.save(GameManager.current_save_slot, self)
	if _hud and _hud.has_method("show_toast"):
		_hud.show_toast("✓ %s" % reason, 2.0)

func _update_day_overlay() -> void:
	# 颜色分级：白天接近中性（不染色资源/UI）；黎明/黄昏暖橙；夜晚冷蓝
	const DAY := Color(1.0, 1.0, 1.0)
	const DUSK := Color(1.10, 0.88, 0.72)
	const NIGHT := Color(0.55, 0.65, 0.92)
	var target: Color
	var ratio := TimeSystem.get_phase_ratio()
	if TimeSystem.is_night():
		if ratio < 0.15:
			target = DUSK.lerp(NIGHT, ratio / 0.15)
		elif ratio > 0.85:
			target = NIGHT.lerp(DUSK, (ratio - 0.85) / 0.15)
		else:
			target = NIGHT
	else:
		if ratio < 0.1:
			target = DUSK.lerp(DAY, ratio / 0.1)
		elif ratio > 0.9:
			target = DAY.lerp(DUSK, (ratio - 0.9) / 0.1)
		else:
			target = DAY
	if _canvas_modulate:
		_canvas_modulate.color = _canvas_modulate.color.lerp(target, 0.05)
	# 保留 _day_overlay 透明（不再使用纯黑蒙板）
	if _day_overlay:
		_day_overlay.color = Color(0, 0, 0, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not BuildingSystem.is_building:
		if _pause_menu and not _pause_menu.visible:
			_pause_menu.open()
			get_viewport().set_input_as_handled()
			return
	if not BuildingSystem.is_building:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var place_pos := get_global_mouse_position()
			if BuildingSystem.current_building and BuildingSystem.current_building.connects:
				place_pos = place_pos.snapped(Vector2(TILE_SIZE, TILE_SIZE))
			PlayerActions.request_place_building(place_pos)
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			BuildingSystem.exit_build_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		BuildingSystem.exit_build_mode()
		get_viewport().set_input_as_handled()

func _on_build_mode_entered(building: BuildingData) -> void:
	if building.scene_path.is_empty():
		return
	_build_preview = (load(building.scene_path) as PackedScene).instantiate()
	_build_preview.modulate = Color(0.4, 1.0, 0.4, 0.55)
	for child in _build_preview.get_children():
		if child is CollisionShape2D or child is CollisionObject2D:
			child.set_deferred("disabled", true)
	y_sort_layer.add_child(_build_preview)
	if _build_preview.has_method("setup_preview"):
		_build_preview.setup_preview(building)

func _on_build_mode_exited() -> void:
	if _build_preview:
		_build_preview.queue_free()
		_build_preview = null

func _on_building_placed(building: BuildingData, pos: Vector2) -> void:
	var node := (load(building.scene_path) as PackedScene).instantiate() as Node2D
	node.global_position = pos
	y_sort_layer.add_child(node)
	if node.has_method("on_placed"):
		node.on_placed(building)

func _on_night_started(_day: int) -> void:
	_spawn_night_creatures()

func _on_day_started(_day: int) -> void:
	pass

func _update_chunks() -> void:
	var player_tile := Vector2i(
		floori(player.global_position.x / TILE_SIZE),
		floori(player.global_position.y / TILE_SIZE)
	)
	var wanted := ChunkManager.chunks_in_radius(player_tile, ACTIVE_RADIUS_TILES)
	var wanted_set: Dictionary = {}
	for c in wanted:
		wanted_set[c] = true

	# 卸载远处的 chunk
	for chunk in ChunkManager.get_active_chunks():
		if not wanted_set.has(chunk):
			ChunkManager.deactivate_chunk(chunk)

	# 加载新进入的 chunk
	for chunk in wanted:
		if not ChunkManager.is_active(chunk):
			_activate_chunk(chunk)

func _activate_chunk(chunk: Vector2i) -> void:
	ChunkManager.mark_active(chunk)
	if ChunkManager.has_snapshot(chunk):
		_restore_chunk_from_snapshot(chunk)
	else:
		_spawn_chunk_resources(chunk)

func _restore_chunk_from_snapshot(chunk: Vector2i) -> void:
	for entry in ChunkManager.get_snapshot(chunk):
		if entry.get("kind", "") != "resource":
			continue
		var node: ResourceNode = ResourceNodeScene.instantiate()
		node.resource_id = entry.get("id", "")
		node.position = Vector2(entry.get("x", 0.0), entry.get("y", 0.0))
		y_sort_layer.add_child(node)
		if entry.get("depleted", false):
			node.call_deferred("restore_from_save", 0.0)
		ChunkManager.register_entity(chunk, node)

func _spawn_chunk_resources(chunk: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var node_types := ItemDatabase.get_all_resource_nodes()
	if node_types.is_empty():
		return
	var biomes_exist := not ItemDatabase.get_all_biomes().is_empty()
	var global_total := 0.0
	for nd in node_types:
		global_total += nd.spawn_weight
	for i in ChunkManager.RESOURCES_PER_CHUNK:
		var pos := ChunkManager.random_in_chunk(rng, chunk)
		if pos.distance_to(player.global_position) < MIN_SPAWN_DIST:
			continue
		var chosen: ResourceNodeData = null
		if biomes_exist:
			var biome := WorldGenerator.get_biome_at(pos)
			if biome and rng.randf() > biome.spawn_density:
				continue
			chosen = _pick_resource_by_biome(rng, node_types, biome)
		if chosen == null:
			chosen = _pick_resource_global(rng, node_types, global_total)
		if chosen == null:
			continue
		var node: ResourceNode = ResourceNodeScene.instantiate()
		node.resource_id = chosen.id
		node.position = pos
		y_sort_layer.add_child(node)
		ChunkManager.register_entity(chunk, node)

func _pick_resource_by_biome(rng: RandomNumberGenerator, node_types: Array, biome: BiomeData) -> ResourceNodeData:
	if biome == null or biome.resource_weights.is_empty():
		return null
	var total := 0.0
	for w in biome.resource_weights.values():
		total += float(w)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	var acc := 0.0
	for res_id in biome.resource_weights:
		acc += float(biome.resource_weights[res_id])
		if roll <= acc:
			for nd in node_types:
				if nd.id == res_id:
					return nd
			return null
	return null

func _pick_resource_global(rng: RandomNumberGenerator, node_types: Array, total_weight: float) -> ResourceNodeData:
	if total_weight <= 0.0:
		return null
	var roll := rng.randf() * total_weight
	var acc := 0.0
	for nd in node_types:
		acc += nd.spawn_weight
		if roll <= acc:
			return nd
	return node_types[0]

func _spawn_night_creatures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var all_creatures := ItemDatabase.get_all_creatures()
	if all_creatures.is_empty():
		return
	var count := rng.randi_range(3, 6)
	for i in count:
		var pos := _random_pos(rng, CREATURE_MIN_DIST, CREATURE_SPAWN_RADIUS)
		var chosen := _pick_creature_for_pos(rng, all_creatures, pos)
		if chosen == null:
			continue
		var creature: Creature = CreatureScene.instantiate()
		creature.data = chosen
		creature.position = pos
		y_sort_layer.add_child(creature)

func _pick_creature_for_pos(rng: RandomNumberGenerator, all_creatures: Array, pos: Vector2) -> CreatureData:
	var biome := WorldGenerator.get_biome_at(pos)
	if biome and not biome.creature_weights.is_empty():
		var total := 0.0
		for w in biome.creature_weights.values():
			total += float(w)
		if total > 0.0:
			var roll := rng.randf() * total
			var acc := 0.0
			for cid in biome.creature_weights:
				acc += float(biome.creature_weights[cid])
				if roll <= acc:
					var c := ItemDatabase.get_creature(cid)
					if c:
						return c
					break
	return all_creatures[rng.randi() % all_creatures.size()]

func _random_pos(rng: RandomNumberGenerator, min_dist: float, max_dist: float) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(min_dist, max_dist)
	return Vector2(cos(angle), sin(angle)) * dist
