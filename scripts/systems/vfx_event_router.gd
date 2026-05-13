extends Node

# VFX 事件路由：把全局事件（升级 / 收获 / 建造）转成粒子反馈。
# 装备变更在 Player 自己监听（InventoryComponent 是组件级信号，无法全局接）。
#
# 设计原则：只负责"事件 → 粒子"映射，不参与游戏逻辑。
# 加新事件粒子只在这里 connect 一行 + 加一个 vfx scene。

func _ready() -> void:
	EventBus.skill_leveled_up.connect(_on_leveled_up)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	# BuildingSystem 是 autoload，确保它已加载（项目 autoload 顺序里在 VFXLibrary 之前）
	if Engine.has_singleton("BuildingSystem") or get_node_or_null("/root/BuildingSystem") != null:
		BuildingSystem.building_placed.connect(_on_building_placed)

func _on_leveled_up(_skill_id: String, _new_level: int) -> void:
	var p := _local_player()
	if p == null:
		return
	VFXLibrary.spawn("levelup_burst", p.get_parent(), p.global_position + Vector2(0, -16), 0.0, Color(1.0, 0.9, 0.35, 0.85))

func _on_crop_harvested(_crop: CropData, player_id: int) -> void:
	var p := _player_for(player_id)
	if p == null:
		return
	VFXLibrary.spawn("harvest_pop", p.get_parent(), p.global_position + Vector2(0, -8), 0.0, Color(0.5, 0.9, 0.4, 0.85))

func _on_building_placed(_building: BuildingData, pos: Vector2) -> void:
	# 找一个合适 parent：world 节点（与建筑同层）
	var world := get_tree().get_first_node_in_group("world")
	if world == null:
		return
	VFXLibrary.spawn("place_dust", world, pos, 0.0, Color(0.75, 0.65, 0.45, 0.7))

# ─── helper ──────────────────────────────────────────────────────────────

func _local_player() -> Player:
	# 单机：唯一玩家；多人：本机玩家（peer_id meta 匹配）
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	if Network.is_singleplayer():
		return players[0] as Player
	var local_id := Network.local_peer_id()
	for p in players:
		if int(p.get_meta("peer_id", 0)) == local_id:
			return p as Player
	return null

func _player_for(player_id: int) -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	if Network.is_singleplayer():
		return players[0] as Player
	for p in players:
		if int(p.get_meta("peer_id", 0)) == player_id:
			return p as Player
	return null
