extends Node

# 成就 / 图鉴系统。监听 EventBus 累积统计，达成阈值自动解锁 + 发奖励。
# 进度持久化到 user://achievements.json（独立于游戏存档槽，跨档共享）。

signal achievement_unlocked(id: String)
signal progress_changed(id: String, current: int, goal: int)

const DATA_PATH := "res://data/achievements.json"
const SAVE_PATH := "user://achievements.json"

var _all: Array = []                        # 数据 entry 数组
var _progress: Dictionary = {}              # id → int 当前累积
var _unlocked: Dictionary = {}              # id → true

func _ready() -> void:
	_load_data()
	_load_progress()
	EventBus.resource_collected.connect(_on_resource_collected)
	EventBus.creature_killed.connect(_on_creature_killed)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.item_sold.connect(_on_item_sold)
	EventBus.item_crafted.connect(_on_item_crafted)
	TimeSystem.day_started.connect(_on_day_started)

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_all = parsed

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_progress = (parsed as Dictionary).get("progress", {})
		_unlocked = (parsed as Dictionary).get("unlocked", {})

func _save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"progress": _progress, "unlocked": _unlocked}, "\t"))

func get_all() -> Array:
	return _all

func is_unlocked(id: String) -> bool:
	return _unlocked.has(id) and bool(_unlocked[id])

func current(id: String) -> int:
	return int(_progress.get(id, 0))

# ─── 统计累积 ────────────────────────────────────────────────────────────

func _bump(event: String, target_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var changed := false
	for a in _all:
		var ad := a as Dictionary
		if ad.get("event", "") != event:
			continue
		var t: String = ad.get("target_id", "")
		if not t.is_empty() and t != target_id:
			continue
		var id: String = ad.get("id", "")
		if _unlocked.get(id, false):
			continue
		var cur: int = int(_progress.get(id, 0)) + amount
		_progress[id] = cur
		progress_changed.emit(id, cur, int(ad.get("goal", 1)))
		if cur >= int(ad.get("goal", 1)):
			_unlock(ad)
		changed = true
	if changed:
		_save_progress()

func _unlock(ad: Dictionary) -> void:
	var id: String = ad.get("id", "")
	_unlocked[id] = true
	# 发奖励：直接给本地玩家加金币
	var reward: int = int(ad.get("reward_gold", 0))
	if reward > 0:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			for p in tree.get_nodes_in_group("player"):
				var pl := p as Player
				if pl and pl.inventory and pl.peer_id == Network.local_peer_id():
					pl.inventory.add_gold(reward)
					break
	achievement_unlocked.emit(id)

# ─── 事件桥 ──────────────────────────────────────────────────────────────

func _on_resource_collected(resource_type_id: String, _player_id: int) -> void:
	_bump("resource_collected", resource_type_id, 1)

func _on_creature_killed(creature: CreatureData, _player_id: int) -> void:
	if creature:
		_bump("creature_killed", creature.id, 1)

func _on_crop_harvested(crop: CropData, _player_id: int) -> void:
	if crop:
		_bump("crop_harvested", crop.id, 1)

func _on_item_sold(item: ItemData, amount: int, gold: int) -> void:
	# item_sold_gold 累计金币；item_sold_count 按 item id 累积数量
	_bump("item_sold_gold", "", gold)
	if item:
		_bump("item_sold_count", item.id, amount)

func _on_item_crafted(recipe: RecipeData) -> void:
	if recipe and recipe.output_item:
		_bump("item_crafted", recipe.output_item.id, recipe.output_amount)

func _on_day_started(d: int) -> void:
	for a in _all:
		var ad := a as Dictionary
		if ad.get("event", "") != "day_milestone":
			continue
		var id: String = ad.get("id", "")
		if _unlocked.get(id, false):
			continue
		if d >= int(ad.get("goal", 1)):
			_progress[id] = d
			_unlock(ad)
	_save_progress()
