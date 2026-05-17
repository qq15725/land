extends Node

# 存档系统（G7 拆 world / per-player）。
#
# 存档结构 v2：
# {
#   "version": 2,
#   "saved_at": "...",
#   "world": {
#     "day", "phase", "phase_elapsed", "terrain_seed",
#     "chunk_snapshots", "buildings", "network_registry"
#   },
#   "players": [
#     {
#       "peer_id", "pos", "hp", "money",
#       "inventory", "equipped", "skills"
#     },
#     ...
#   ]
# }
#
# 单机：players 数组只有一个元素，peer_id = 1。
# 多人（G8+）：每个加入过的玩家一份记录；读档时按 peer_id 分配。
# 旧 v1 存档（顶层平铺单玩家字段）由 _apply_v1 兼容加载。

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3
const VERSION := 2

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save(slot: int, world: Node2D) -> void:
	var data := _collect(world)
	var path := SAVE_DIR + "slot_%d.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func load_save(slot: int, world: Node2D) -> bool:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var result: Variant = JSON.parse_string(file.get_as_text())
	if result == null:
		return false
	await _apply(result as Dictionary, world)
	return true

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % slot)

func get_slot_info(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var result: Variant = JSON.parse_string(file.get_as_text())
	if result == null:
		return {}
	var d := result as Dictionary
	# v2: world.day / players[0].money；v1: 顶层
	var ver := int(d.get("version", 1))
	if ver >= 2:
		var w: Dictionary = d.get("world", {})
		var ps: Array = d.get("players", [])
		var first: Dictionary = ps[0] if ps.size() > 0 else {}
		return {
			"day": w.get("day", 1),
			"phase": w.get("phase", "day"),
			"season": w.get("season", "春季"),
			"money": first.get("money", 0),
			"saved_at": d.get("saved_at", ""),
		}
	return {
		"day": d.get("day", 1),
		"phase": d.get("phase", "day"),
		"season": d.get("season", "春季"),
		"money": d.get("money", 0),
		"saved_at": d.get("saved_at", ""),
	}

func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# ─── 收集（save） ────────────────────────────────────────────────────────

func _collect(world: Node2D) -> Dictionary:
	ChunkManager.snapshot_active_chunks()
	var ts: Variant = world.get("terrain_seed")
	return {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"world": {
			"day": TimeSystem.current_day,
			"phase": "night" if TimeSystem.is_night() else "day",
			"phase_elapsed": TimeSystem.phase_elapsed,
			"terrain_seed": ts if ts is int else 0,
			"chunk_snapshots": ChunkManager.export_snapshots(),
			"buildings": _save_buildings(world),
			"network_registry": NetworkRegistry.export_state(),
		},
		"players": _collect_players(world),
	}

func _collect_players(world: Node2D) -> Array:
	var result: Array = []
	for p in world.get_tree().get_nodes_in_group("player"):
		var player := p as Player
		var peer_id: int = int(player.get_meta("peer_id", Network.local_peer_id()))
		result.append({
			"peer_id": peer_id,
			"pos": {"x": player.global_position.x, "y": player.global_position.y},
			"hp": player.health.current_health,
			"money": player.inventory.gold,
			"inventory": _save_inventory(player.inventory),
			"equipped": _save_equipped(player.inventory),
			"skills": player.skills.export_state() if player.skills else {},
			"active_skills": player.active_skills.export_state() if player.active_skills else {},
			"equipped_skills": player.equipped_skills.duplicate(),
		})
	return result

# ─── 应用（load） ────────────────────────────────────────────────────────

func _apply(data: Dictionary, world: Node2D) -> void:
	var ver := int(data.get("version", 1))
	if ver >= 2:
		await _apply_v2(data, world)
	else:
		await _apply_v1(data, world)

func _apply_v2(data: Dictionary, world: Node2D) -> void:
	var world_data: Dictionary = data.get("world", {})
	var players_data: Array = data.get("players", [])
	await _apply_world(world_data, world)
	_apply_players(players_data, world)
	await _load_buildings(world, world_data.get("buildings", []))

# 兼容 v1：顶层平铺单玩家字段
func _apply_v1(data: Dictionary, world: Node2D) -> void:
	var world_data := {
		"day": data.get("day", 1),
		"phase": data.get("phase", "day"),
		"phase_elapsed": data.get("phase_elapsed", 0.0),
		"terrain_seed": data.get("terrain_seed", 0),
		"chunk_snapshots": data.get("chunk_snapshots", []),
		"buildings": data.get("buildings", []),
		"network_registry": data.get("network_registry", {}),
	}
	var player_data := {
		"peer_id": Network.SERVER_PEER_ID,
		"pos": data.get("player_pos", {}),
		"hp": data.get("player_hp", 100),
		"money": data.get("money", 0),
		"inventory": data.get("inventory", []),
		"equipped": data.get("equipped", {}),
		"skills": data.get("skills", {}),
	}
	await _apply_world(world_data, world)
	_apply_players([player_data], world)
	# v1 资源节点平铺存档兜底
	if not world_data.has("chunk_snapshots") or (world_data["chunk_snapshots"] as Array).is_empty():
		_migrate_legacy_resource_nodes(data.get("resource_nodes", []))
	await _load_buildings(world, world_data.get("buildings", []), data.get("farm_plots", []))

# ─── 子流程：world ───────────────────────────────────────────────────────

func _apply_world(world_data: Dictionary, world: Node2D) -> void:
	TimeSystem.current_day = world_data.get("day", 1)
	TimeSystem.phase_elapsed = world_data.get("phase_elapsed", 0.0)
	TimeSystem.current_phase = TimeSystem.Phase.NIGHT if world_data.get("phase") == "night" else TimeSystem.Phase.DAY

	var seed_val: int = world_data.get("terrain_seed", 0)
	if seed_val == 0:
		seed_val = randi()
	world.set("terrain_seed", seed_val)
	var tm := world.get_node_or_null("TerrainMap") as TileMapLayer
	if tm:
		await WorldGenerator.generate(tm, seed_val)

	NetworkRegistry.import_state(world_data.get("network_registry", {}))
	ChunkManager.clear_state()
	if world_data.has("chunk_snapshots"):
		ChunkManager.import_snapshots(world_data["chunk_snapshots"])

# ─── 子流程：players ─────────────────────────────────────────────────────

func _apply_players(players_data: Array, world: Node2D) -> void:
	var players := world.get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	# 单机：第一条数据 → 唯一玩家；多人（G8+）：按 peer_id 匹配
	if Network.is_singleplayer():
		if players_data.size() > 0:
			_apply_one_player(players[0] as Player, players_data[0])
		return
	for pd in players_data:
		var pid: int = int(pd.get("peer_id", 0))
		for p in players:
			var player := p as Player
			if int(player.get_meta("peer_id", 0)) == pid:
				_apply_one_player(player, pd)
				break

func _apply_one_player(player: Player, pd: Dictionary) -> void:
	var pos: Dictionary = pd.get("pos", {})
	player.global_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	player.health.current_health = pd.get("hp", player.health.max_health)
	player.inventory.gold = int(pd.get("money", 0))
	player.inventory.gold_changed.emit(player.inventory.gold)
	_load_inventory(player.inventory, pd.get("inventory", []))
	_load_equipped(player.inventory, pd.get("equipped", {}))
	if player.skills:
		player.skills.import_state(pd.get("skills", {}))
	if player.active_skills:
		player.active_skills.import_state(pd.get("active_skills", {}))
	var eq_skills: Array = pd.get("equipped_skills", [])
	if not eq_skills.is_empty():
		for i in mini(eq_skills.size(), player.equipped_skills.size()):
			player.equipped_skills[i] = eq_skills[i]

# ─── 背包 ────────────────────────────────────────────────────────────────

func _save_inventory(inv: InventoryComponent) -> Array:
	var result := []
	for slot in inv.slots:
		if slot.item != null:
			result.append({"id": slot.item.id, "amount": slot.amount})
		else:
			result.append(null)
	return result

func _load_inventory(inv: InventoryComponent, data: Array) -> void:
	for i in mini(data.size(), inv.slots.size()):
		var entry = data[i]
		if entry == null:
			inv.slots[i] = {item = null, amount = 0}
		else:
			var item := ItemDatabase.get_item(entry.get("id", ""))
			inv.slots[i] = {item = item, amount = entry.get("amount", 0)}
	inv.changed.emit()

func _save_equipped(inv: InventoryComponent) -> Dictionary:
	var result := {}
	for slot_type in inv.equipped:
		var it: ItemData = inv.equipped[slot_type]
		if it:
			result[slot_type] = it.id
	return result

func _load_equipped(inv: InventoryComponent, data: Dictionary) -> void:
	inv.equipped.clear()
	for slot_type in data:
		var item := ItemDatabase.get_item(data[slot_type])
		if item:
			inv.equipped[slot_type] = item
			inv.equipment_changed.emit(slot_type)
	inv.changed.emit()

# ─── 资源节点（v1 旧存档兜底） ──────────────────────────────────────────

const _ResourceNodeScene := preload("res://scenes/world/resource.tscn")

func _migrate_legacy_resource_nodes(data: Array) -> void:
	var pending: Array = []
	for entry in data:
		var rid: String = entry.get("resource_id", "")
		if rid.is_empty():
			continue
		pending.append({
			"kind": "resource",
			"id": rid,
			"x": entry.get("x", 0.0),
			"y": entry.get("y", 0.0),
			"depleted": entry.get("depleted", false),
		})
	ChunkManager.import_snapshots(pending)

# ─── 建筑（含 FarmPlot） ────────────────────────────────────────────────

func _save_buildings(world: Node2D) -> Array:
	var result := []
	for node in world.get_node("YSortLayer").get_children():
		var id := _resolve_building_id(node)
		if id.is_empty():
			continue
		var entry := {
			"id": id,
			"x": node.global_position.x,
			"y": node.global_position.y,
		}
		if node.has_method("get_save_state"):
			entry["state"] = node.get_save_state()
		result.append(entry)
	return result

# 第二个参数仅用于兼容旧 v1 存档的 farm_plots 数组
func _load_buildings(world: Node2D, data: Array, legacy_farm_plots: Array = []) -> void:
	var layer: Node2D = world.get_node("YSortLayer")
	for node in layer.get_children():
		if node is BuildingBase or node is FarmPlot or node is Animal:
			node.queue_free()
	await world.get_tree().process_frame

	for entry in data:
		var bd := _entry_to_building_data(entry)
		if bd == null:
			continue
		var node := _spawn_building(layer, bd, Vector2(entry.get("x", 0.0), entry.get("y", 0.0)))
		if node and entry.has("state") and node.has_method("load_save_state"):
			node.load_save_state(entry["state"])

	if not legacy_farm_plots.is_empty():
		var bd := ItemDatabase.get_building("farm_plot")
		if bd:
			for entry in legacy_farm_plots:
				var node := _spawn_building(layer, bd, Vector2(entry.get("x", 0.0), entry.get("y", 0.0)))
				if node and entry.has("state") and node.has_method("load_save_state"):
					node.load_save_state(entry["state"])

func _resolve_building_id(node: Node) -> String:
	if node is BuildingBase:
		var bb := node as BuildingBase
		if bb.building_data:
			return bb.building_data.id
	if node is FarmPlot:
		var fp := node as FarmPlot
		if fp.building_data:
			return fp.building_data.id
		return "farm_plot"
	return ""

func _entry_to_building_data(entry: Dictionary) -> BuildingData:
	var id: String = entry.get("id", "")
	if not id.is_empty():
		return ItemDatabase.get_building(id)
	var scene_path: String = entry.get("type", "")
	if scene_path.is_empty():
		return null
	for b in ItemDatabase.get_all_buildings():
		if b.scene_path == scene_path:
			return b
	return null

func _spawn_building(layer: Node2D, bd: BuildingData, pos: Vector2) -> Node2D:
	if bd.scene_path.is_empty() or not ResourceLoader.exists(bd.scene_path):
		return null
	var node := (load(bd.scene_path) as PackedScene).instantiate() as Node2D
	node.global_position = pos
	layer.add_child(node)
	if node.has_method("on_placed"):
		node.on_placed(bd)
	return node
