extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3

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
	return {
		"day": (result as Dictionary).get("day", 1),
		"phase": (result as Dictionary).get("phase", "day"),
		"season": (result as Dictionary).get("season", "春季"),
		"money": (result as Dictionary).get("money", 0),
		"saved_at": (result as Dictionary).get("saved_at", ""),
	}

func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _collect(world: Node2D) -> Dictionary:
	var player: Player = world.get_node("YSortLayer/Player")
	var ts: Variant = world.get("terrain_seed")
	# 把当前 active chunk 状态同步到 ChunkManager._snapshots
	ChunkManager.snapshot_active_chunks()
	var data := {
		"saved_at": Time.get_datetime_string_from_system(),
		"day": TimeSystem.current_day,
		"phase": "night" if TimeSystem.is_night() else "day",
		"phase_elapsed": TimeSystem.phase_elapsed,
		"terrain_seed": ts if ts is int else 0,
		"player_pos": {"x": player.global_position.x, "y": player.global_position.y},
		"player_hp": player.health.current_health,
		"money": player.inventory.gold,
		"inventory": _save_inventory(player.inventory),
		"equipped": _save_equipped(player.inventory),
		"skills": SkillSystem.export_state(),
		"chunk_snapshots": ChunkManager.export_snapshots(),
		"buildings": _save_buildings(world),
	}
	return data

func _apply(data: Dictionary, world: Node2D) -> void:
	var player: Player = world.get_node("YSortLayer/Player")

	TimeSystem.current_day = data.get("day", 1)
	TimeSystem.phase_elapsed = data.get("phase_elapsed", 0.0)
	TimeSystem.current_phase = TimeSystem.Phase.NIGHT if data.get("phase") == "night" else TimeSystem.Phase.DAY

	var seed_val: int = data.get("terrain_seed", 0)
	if seed_val == 0:
		seed_val = randi()
	world.set("terrain_seed", seed_val)
	var tm := world.get_node_or_null("TerrainMap") as TileMap
	if tm:
		WorldGenerator.generate(tm, seed_val)

	var pos: Dictionary = data.get("player_pos", {})
	player.global_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	player.health.current_health = data.get("player_hp", player.health.max_health)
	player.inventory.gold = int(data.get("money", 0))
	player.inventory.gold_changed.emit(player.inventory.gold)

	_load_inventory(player.inventory, data.get("inventory", []))
	_load_equipped(player.inventory, data.get("equipped", {}))
	SkillSystem.import_state(data.get("skills", {}))
	# 新存档使用 chunk_snapshots；旧存档 resource_nodes 兜底
	ChunkManager.clear_state()
	if data.has("chunk_snapshots"):
		ChunkManager.import_snapshots(data["chunk_snapshots"])
	else:
		_migrate_legacy_resource_nodes(data.get("resource_nodes", []))
	await _load_buildings(world, data.get("buildings", []), data.get("farm_plots", []))

# --- 背包 ---

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

# --- 资源节点（统一走 ChunkManager.snapshots） ---

const _ResourceNodeScene := preload("res://scenes/world/resource.tscn")

# 旧存档把 ResourceNode 平铺在 resource_nodes 数组里。
# 按位置归到对应 chunk 的 snapshot，world.gd._update_chunks 加载附近 chunk 时会从中还原。
func _migrate_legacy_resource_nodes(data: Array) -> void:
	for entry in data:
		var rid: String = entry.get("resource_id", "")
		if rid.is_empty():
			continue
		var pos := Vector2(entry.get("x", 0.0), entry.get("y", 0.0))
		var chunk := ChunkManager.world_to_chunk(pos)
		ChunkManager.import_snapshots([{
			"kind": "resource",
			"id": rid,
			"x": pos.x,
			"y": pos.y,
			"depleted": entry.get("depleted", false),
			"chunk_x": chunk.x,
			"chunk_y": chunk.y,
		}])

# --- 建筑（含 FarmPlot，统一路径） ---

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

# 第二个参数仅用于兼容旧存档（farm_plots 数组）。
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

	# 旧存档：buildings 不含 FarmPlot，需要从 legacy farm_plots 字段补建。
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

# 兼容旧存档（"type": scene_path）和新格式（"id": building_id）。
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
