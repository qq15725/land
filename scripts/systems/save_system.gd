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
	var result := JSON.parse_string(file.get_as_text())
	if result == null:
		return false
	_apply(result, world)
	return true

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % slot)

func get_slot_info(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var result := JSON.parse_string(file.get_as_text())
	if result == null:
		return {}
	return {
		"day": result.get("day", 1),
		"phase": result.get("phase", "白天"),
		"saved_at": result.get("saved_at", ""),
	}

func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _collect(world: Node2D) -> Dictionary:
	var player: Player = world.get_node("YSortLayer/Player")
	var data := {
		"saved_at": Time.get_datetime_string_from_system(),
		"day": TimeSystem.current_day,
		"phase": "night" if TimeSystem.is_night() else "day",
		"phase_elapsed": TimeSystem.phase_elapsed,
		"player_pos": {"x": player.global_position.x, "y": player.global_position.y},
		"player_hp": player.health.current_health,
		"inventory": _save_inventory(player.inventory),
		"resource_nodes": _save_resource_nodes(world),
		"farm_plots": _save_farm_plots(world),
		"buildings": _save_buildings(world),
	}
	return data

func _apply(data: Dictionary, world: Node2D) -> void:
	var player: Player = world.get_node("YSortLayer/Player")

	TimeSystem.current_day = data.get("day", 1)
	TimeSystem.phase_elapsed = data.get("phase_elapsed", 0.0)
	TimeSystem.current_phase = TimeSystem.Phase.NIGHT if data.get("phase") == "night" else TimeSystem.Phase.DAY

	var pos: Dictionary = data.get("player_pos", {})
	player.global_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	player.health.current_health = data.get("player_hp", player.health.max_health)

	_load_inventory(player.inventory, data.get("inventory", []))
	_load_resource_nodes(world, data.get("resource_nodes", []))
	_load_farm_plots(world, data.get("farm_plots", []))

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

# --- 资源节点 ---

func _save_resource_nodes(world: Node2D) -> Array:
	var result := []
	for node in world.get_node("YSortLayer").get_children():
		if node is ResourceNode:
			result.append({
				"type": node.scene_file_path,
				"x": node.global_position.x,
				"y": node.global_position.y,
				"depleted": node.is_depleted(),
				"regen_timer": node.get_regen_timer(),
			})
	return result

func _load_resource_nodes(world: Node2D, data: Array) -> void:
	var layer: Node2D = world.get_node("YSortLayer")
	for node in layer.get_children():
		if node is ResourceNode:
			node.queue_free()
	await world.get_tree().process_frame
	for entry in data:
		var scene := load(entry.get("type", "")) as PackedScene
		if not scene:
			continue
		var node: ResourceNode = scene.instantiate()
		node.global_position = Vector2(entry.get("x", 0.0), entry.get("y", 0.0))
		layer.add_child(node)
		if entry.get("depleted", false):
			node.restore_from_save(entry.get("regen_timer", 0.0))

# --- 农田 ---

func _save_farm_plots(world: Node2D) -> Array:
	var result := []
	for node in world.get_node("YSortLayer").get_children():
		if node is FarmPlot:
			var entry := {
				"x": node.global_position.x,
				"y": node.global_position.y,
				"state": node.get_save_state(),
			}
			result.append(entry)
	return result

func _load_farm_plots(world: Node2D, data: Array) -> void:
	var layer: Node2D = world.get_node("YSortLayer")
	var plots := []
	for node in layer.get_children():
		if node is FarmPlot:
			plots.append(node)
	for i in mini(data.size(), plots.size()):
		plots[i].load_save_state(data[i].get("state", {}))

# --- 建筑 ---

func _save_buildings(world: Node2D) -> Array:
	var result := []
	for node in world.get_node("YSortLayer").get_children():
		if node is BuildingBase and not node is FarmPlot:
			result.append({
				"type": node.scene_file_path,
				"x": node.global_position.x,
				"y": node.global_position.y,
			})
	return result
