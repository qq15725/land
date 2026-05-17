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
const TalentTreeScene := preload("res://scenes/ui/talent_tree.tscn")
const ClassSelectScene := preload("res://scenes/ui/class_select.tscn")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")
const CodexUIScene := preload("res://scenes/ui/codex_ui.tscn")

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

const AUTOSAVE_INTERVAL := 300.0         # 自动保存间隔（秒）
const MIN_SPAWN_DIST := 80.0
const CREATURE_SPAWN_RADIUS := 500.0
const CREATURE_MIN_DIST := 200.0

# 整图 prefab 生成参数（饥荒式一次性 loading 生成）
const ROOM_COUNT := 60                   # Voronoi room 数（地图越大越多）
const SPAWN_RESERVE_TILES := 4           # 玩家出生点周围 reserve 的半径（tile）

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
var _weather_layer: CanvasLayer = null
var _rain_particles: CPUParticles2D = null
var _snow_particles: CPUParticles2D = null
var _thunder_flash: ColorRect = null
var _thunder_timer: float = 0.0

var terrain_map: TileMapLayer = null
var terrain_seed: int = 0
var map_markers: Dictionary = {}   # "next_0"/"next_1"/"next_2"/"prev" → Vector2i
var current_map_id: String = ""    # 当前地图 id，如 "0"、"0-1"
var _portal_cooldown: float = 0.0

var _loading_layer: CanvasLayer = null
var _loading_label: Label = null
var _loading_bar: ProgressBar = null


func _ready() -> void:
	add_to_group("world")
	_setup_loading_ui()
	_set_loading("初始化...", 0.05)
	ChunkManager.clear_state()
	_setup_terrain()
	_setup_multiplayer_spawner()
	# 静态 Player 节点 = 本地 host 的玩家（peer_id = 自己的 peer_id）
	player.peer_id = Network.local_peer_id()
	_setup_ui()
	if SaveSystem.slot_exists(GameManager.current_save_slot):
		_set_loading("读取存档...", 0.15)
		await SaveSystem.load_save(GameManager.current_save_slot, self)
	else:
		_set_loading("生成地形...", 0.15)
		await _load_map("0")
	# 整图一次性生成 prefab（读档则还原快照，否则按 seed 程序化生成）。
	# 多人模式下只 server 撒，client 通过 MultiplayerSpawner 自动同步。
	if ChunkManager.has_pending_restore():
		_set_loading("还原资源...", 0.85)
		_restore_world_from_snapshot()
	elif Network.is_server():
		await _populate_world(terrain_seed)
	_set_loading("完成", 1.0)
	_hide_loading()
	_maybe_show_class_select()
	BuildingSystem.build_mode_entered.connect(_on_build_mode_entered)
	BuildingSystem.build_mode_exited.connect(_on_build_mode_exited)
	BuildingSystem.building_placed.connect(_on_building_placed)
	TimeSystem.night_started.connect(_on_night_started)
	TimeSystem.day_started.connect(_on_day_started)
	TimeSystem.day_started.connect(func(_d): _autosave("新的一天"))
	SoundSystem.play_world_bgm()
	_setup_weather_fx()
	WeatherSystem.weather_changed.connect(_on_weather_changed)
	_on_weather_changed(WeatherSystem.current_id)
	# 多人：监听玩家进出
	Network.peer_joined.connect(_on_peer_joined)
	Network.peer_left.connect(_on_peer_left)

func _setup_weather_fx() -> void:
	_weather_layer = CanvasLayer.new()
	_weather_layer.layer = 4
	add_child(_weather_layer)

	# 雨
	_rain_particles = CPUParticles2D.new()
	_rain_particles.amount = 200
	_rain_particles.lifetime = 1.2
	_rain_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain_particles.emission_rect_extents = Vector2(800, 8)
	_rain_particles.position = Vector2(640, -40)
	_rain_particles.direction = Vector2(0.1, 1.0)
	_rain_particles.spread = 5.0
	_rain_particles.initial_velocity_min = 720.0
	_rain_particles.initial_velocity_max = 920.0
	_rain_particles.scale_amount_min = 1.0
	_rain_particles.scale_amount_max = 2.5
	_rain_particles.color = Color(0.7, 0.85, 1.0, 0.55)
	_rain_particles.emitting = false
	_weather_layer.add_child(_rain_particles)

	# 雪
	_snow_particles = CPUParticles2D.new()
	_snow_particles.amount = 120
	_snow_particles.lifetime = 6.0
	_snow_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow_particles.emission_rect_extents = Vector2(800, 8)
	_snow_particles.position = Vector2(640, -40)
	_snow_particles.direction = Vector2(0.0, 1.0)
	_snow_particles.spread = 25.0
	_snow_particles.initial_velocity_min = 60.0
	_snow_particles.initial_velocity_max = 100.0
	_snow_particles.angular_velocity_min = -90.0
	_snow_particles.angular_velocity_max = 90.0
	_snow_particles.scale_amount_min = 2.0
	_snow_particles.scale_amount_max = 4.0
	_snow_particles.color = Color(1.0, 1.0, 1.0, 0.85)
	_snow_particles.emitting = false
	_weather_layer.add_child(_snow_particles)

	# 雷暴闪光
	_thunder_flash = ColorRect.new()
	_thunder_flash.anchor_right = 1.0
	_thunder_flash.anchor_bottom = 1.0
	_thunder_flash.color = Color(1, 1, 1, 0)
	_thunder_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_layer.add_child(_thunder_flash)

func _on_weather_changed(_id: String) -> void:
	if _rain_particles:
		_rain_particles.emitting = WeatherSystem.is_raining()
	if _snow_particles:
		_snow_particles.emitting = WeatherSystem.is_snowing()
	if WeatherSystem.is_thundering():
		_thunder_timer = randf_range(4.0, 9.0)

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
			map_markers = await WorldGenerator.generate_from_image(terrain_map, img_path)
			terrain_seed = img_path.hash()
		else:
			push_error("预设地图不存在: " + img_path + "，回退到程序化生成")
			await _gen_random()
	else:
		await _gen_random()

func _gen_random() -> void:
	terrain_seed = randi()
	await WorldGenerator.generate(terrain_map, terrain_seed)


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

	# 清除当前地图的临时实体（切图时整图重生）
	for node in y_sort_layer.get_children():
		if node is ResourceNode or node is Creature:
			node.queue_free()
	ChunkManager.clear_state()

	await _load_map(target_id)
	_show_loading()
	await _populate_world(terrain_seed)
	_hide_loading()
	_portal_cooldown = PORTAL_COOLDOWN

	# 传送玩家到目标地图入口
	if spawn_key in map_markers:
		var st: Vector2i = map_markers[spawn_key]
		player.global_position = Vector2(
			st.x * TILE_SIZE + TILE_SIZE * 0.5,
			st.y * TILE_SIZE + TILE_SIZE * 0.5
		)


func _maybe_show_class_select() -> void:
	# 仅当本地玩家从未选过职业（class_id 为空）时弹出。读档恢复后由此判断，避免重弹。
	var local := _find_local_player()
	if local == null or local.active_skills == null:
		return
	if not local.active_skills.class_id.is_empty():
		return
	var cs := _find_class_select()
	if cs:
		cs.show()

func _find_class_select() -> Control:
	for layer in get_children():
		if layer is CanvasLayer:
			var n := (layer as CanvasLayer).get_node_or_null("ClassSelect")
			if n:
				return n as Control
	return null


func _setup_loading_ui() -> void:
	_loading_layer = CanvasLayer.new()
	_loading_layer.layer = 100
	add_child(_loading_layer)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	_loading_label = Label.new()
	_loading_label.text = "加载中..."
	_loading_label.add_theme_font_size_override("font_size", 28)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_loading_label)

	_loading_bar = ProgressBar.new()
	_loading_bar.custom_minimum_size = Vector2(360, 14)
	_loading_bar.max_value = 1.0
	_loading_bar.value = 0.0
	_loading_bar.show_percentage = false
	box.add_child(_loading_bar)


func _set_loading(text: String, pct: float) -> void:
	if _loading_label:
		_loading_label.text = text
	if _loading_bar:
		_loading_bar.value = pct


func _show_loading() -> void:
	if _loading_layer:
		_loading_layer.visible = true


func _hide_loading() -> void:
	if _loading_layer:
		_loading_layer.visible = false


func _setup_terrain() -> void:
	terrain_map = TileMapLayer.new()
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

	var talent_tree := TalentTreeScene.instantiate()
	ui_layer.add_child(talent_tree)

	var class_select := ClassSelectScene.instantiate()
	class_select.name = "ClassSelect"
	ui_layer.add_child(class_select)

	var codex_ui := CodexUIScene.instantiate()
	codex_ui.name = "CodexUI"
	ui_layer.add_child(codex_ui)

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
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_autosave("自动保存")
	_tick_thunder(delta)

func _tick_thunder(delta: float) -> void:
	if _thunder_flash == null:
		return
	if WeatherSystem.is_thundering():
		_thunder_timer -= delta
		if _thunder_timer <= 0.0:
			_thunder_flash.color = Color(1, 1, 1, 0.7)
			_thunder_timer = randf_range(5.0, 12.0)
	_thunder_flash.color.a = move_toward(_thunder_flash.color.a, 0.0, delta * 3.0)

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
	# 每个季节最后一天的夜晚刷 Boss
	if TimeSystem.day_in_season() == TimeSystem.DAYS_PER_SEASON:
		_spawn_season_boss()

func _spawn_season_boss() -> void:
	var boss_id := "season_bear"   # 先固定，后续可按季节扩展
	var data := ItemDatabase.get_creature(boss_id)
	if data == null or not data.is_boss:
		return
	# 已经有 boss 时不重复
	if not get_tree().get_nodes_in_group("boss").is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pos := player.global_position + Vector2(cos(rng.randf() * TAU), sin(rng.randf() * TAU)) * 320.0
	var boss: Creature = CreatureScene.instantiate()
	boss.data = data
	boss.position = pos
	y_sort_layer.add_child(boss)
	if _hud and _hud.has_method("show_toast"):
		_hud.show_toast("⚔ %s 出现了！" % data.display_name, 4.0)

func _on_day_started(_day: int) -> void:
	pass

# 整图一次性生成：Voronoi room → count/distribute/setpiece 三 pass 撒 prefab。
func _populate_world(seed_val: int) -> void:
	_set_loading("划分区域...", 0.45)
	var w := WorldGenerator.last_map_w
	var h := WorldGenerator.last_map_h
	var origin := WorldGenerator.last_map_origin
	var graph := RoomGraph.new(self)
	await graph.build(w, h, ROOM_COUNT, seed_val, origin)

	_set_loading("撒资源...", 0.75)
	var populator := PrefabPopulator.new(graph, y_sort_layer, ResourceNodeScene, seed_val)
	# reserve 玩家出生点周围若干格，防止 prefab 卡住出生位置
	var player_tile := Vector2i(
		floori(player.global_position.x / TILE_SIZE),
		floori(player.global_position.y / TILE_SIZE)
	)
	var r := SPAWN_RESERVE_TILES
	populator.reserve_world_tiles(Rect2i(
		player_tile - Vector2i(r, r),
		Vector2i(r * 2 + 1, r * 2 + 1)
	))
	await populator.populate()

	# 新生成的 ResourceNode 登记到 ChunkManager 供存档用
	for n in y_sort_layer.get_children():
		if n is ResourceNode:
			ChunkManager.register_entity(n)


# 读档：根据扁平 entity 快照重建所有 ResourceNode。
func _restore_world_from_snapshot() -> void:
	var pending := ChunkManager.consume_pending_snapshot()
	for entry in pending:
		if entry.get("kind", "") != "resource":
			continue
		var node: ResourceNode = ResourceNodeScene.instantiate()
		node.resource_id = entry.get("id", "")
		node.position = Vector2(entry.get("x", 0.0), entry.get("y", 0.0))
		y_sort_layer.add_child(node)
		if entry.get("depleted", false):
			node.call_deferred("restore_from_save", 0.0)
		ChunkManager.register_entity(node)

func _spawn_night_creatures() -> void:
	# 夏至日：今晚不刷怪
	if FestivalSystem.is_active("summer_solstice"):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var all_creatures := ItemDatabase.get_all_creatures()
	if all_creatures.is_empty():
		return
	var count := rng.randi_range(3, 6)
	# 夜间只刷 nocturnal/hostile，排除 passive
	var hostile: Array = []
	for c in all_creatures:
		var cd := c as CreatureData
		if not cd.passive and not cd.is_boss:
			hostile.append(cd)
	if hostile.is_empty():
		return
	for i in count:
		var pos := _random_pos(rng, CREATURE_MIN_DIST, CREATURE_SPAWN_RADIUS)
		var chosen := _pick_creature_for_pos(rng, hostile, pos)
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
