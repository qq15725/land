extends Node

# 任务系统（E6）。数据驱动的线性任务链：前几个是新手引导，之后是持续目标。
# 监听 EventBus 事件推进当前任务，完成发奖励（金币/物品）并解锁下一个。
# 进度持久化 user://quests.json（全局，独立于存档槽，类似成就）。
# HUD 监听 quests_changed 显示右上任务框。

const SAVE_PATH := "user://quests.json"

signal quests_changed(quests: Array)

var _quests: Array = []   # 有序任务定义
var _index: int = 0
var _progress: int = 0
var _all_done: bool = false

func _ready() -> void:
	_load_defs()
	_load_progress()
	if _all_done:
		return
	EventBus.item_picked_up.connect(_on_gather)
	EventBus.creature_killed.connect(_on_kill)
	EventBus.crop_harvested.connect(_on_harvest)
	EventBus.item_crafted.connect(_on_craft)
	EventBus.item_sold.connect(_on_sell)
	BuildingSystem.building_placed.connect(_on_build)

func _load_defs() -> void:
	var f := FileAccess.open("res://data/quests.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Array:
			_quests = d

func _current() -> Dictionary:
	return _quests[_index] if _index < _quests.size() else {}

# 供 HUD ready 后主动拉取
func refresh() -> void:
	if _all_done or _index >= _quests.size():
		quests_changed.emit([])
		return
	var q := _current()
	quests_changed.emit([{"name": q.get("name", "?"), "cur": _progress, "goal": int(q.get("count", 1))}])

func _bump(amount: int = 1) -> void:
	if _all_done or _index >= _quests.size():
		return
	_progress += amount
	if _progress >= int(_current().get("count", 1)):
		_complete()
	else:
		refresh()

func _complete() -> void:
	var q := _current()
	_grant_reward(q)
	_toast("✅ 任务完成：%s" % q.get("name", ""))
	_index += 1
	_progress = 0
	if _index >= _quests.size():
		_all_done = true
		_toast("🎉 所有任务完成，自由发展吧！")
	else:
		_toast("📋 新任务：%s" % _current().get("name", ""))
	_save_progress()
	refresh()

func _grant_reward(q: Dictionary) -> void:
	var p := _find_player()
	if p == null:
		return
	var gold := int(q.get("reward_gold", 0))
	if gold > 0:
		p.inventory.add_gold(gold)
	var item_id: String = q.get("reward_item", "")
	if not item_id.is_empty():
		var it := ItemDatabase.get_item(item_id)
		if it:
			p.inventory.add_item(it, int(q.get("reward_amount", 1)))

func _find_player() -> Player:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Player:
			return p
	return null

# ─── 事件推进 ───
func _on_gather(item: ItemData, amount: int) -> void:
	if _current().get("type", "") != "gather":
		return
	var tgt: String = _current().get("target", "")
	if tgt.is_empty() or (item != null and item.id == tgt):
		_bump(amount)

func _on_kill(_c: CreatureData, _pid: int) -> void:
	if _current().get("type", "") == "kill":
		_bump(1)

func _on_harvest(_c: CropData, _pid: int) -> void:
	if _current().get("type", "") == "harvest":
		_bump(1)

func _on_craft(_r: RecipeData) -> void:
	if _current().get("type", "") == "craft":
		_bump(1)

func _on_build(_b: BuildingData, _pos: Vector2) -> void:
	if _current().get("type", "") == "build":
		_bump(1)

func _on_sell(_item: ItemData, _amount: int, gold_received: int) -> void:
	if _current().get("type", "") == "earn":
		_bump(gold_received)

func _toast(msg: String) -> void:
	UINotify.toast(get_tree(), msg, 2.4)

func _save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"index": _index, "progress": _progress, "done": _all_done}))

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			_index = int(d.get("index", 0))
			_progress = int(d.get("progress", 0))
			_all_done = bool(d.get("done", false))
