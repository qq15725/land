extends Node

# 新手引导任务链（轻量）。
#
# 用现有 EventBus / BuildingSystem 事件驱动 4 个阶段目标，给开局的玩家
# 「下一步做什么」的牵引。不引入新玩法、不加硬压力。
# 全局只跑一遍：完成后写 user://tutorial.json，之后不再显示（独立于存档槽）。

const SAVE_PATH := "user://tutorial.json"

# HUD 监听此信号刷新右上任务框；payload 为 set_quests 接受的格式
signal quests_changed(quests: Array)

var _steps: Array = [
	{"id": "gather_wood",     "name": "采集木头（砍树）", "goal": 5, "cur": 0},
	{"id": "build_workbench", "name": "建造工作台",       "goal": 1, "cur": 0},
	{"id": "harvest_crop",    "name": "种植并收获作物",   "goal": 1, "cur": 0},
	{"id": "first_trade",     "name": "与商人完成交易",   "goal": 1, "cur": 0},
]
var _index: int = 0
var _done: bool = false

func _ready() -> void:
	_load()
	if _done:
		return
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.trade_completed.connect(_on_trade_completed)
	BuildingSystem.building_placed.connect(_on_building_placed)

func _current() -> Dictionary:
	return _steps[_index] if _index < _steps.size() else {}

# 供 HUD 在 ready 后主动拉取当前任务
func refresh() -> void:
	if _done or _index >= _steps.size():
		quests_changed.emit([])
	else:
		quests_changed.emit([_current()])

func _advance(step_id: String, n: int = 1) -> void:
	if _done or _index >= _steps.size():
		return
	var cur := _current()
	if cur.get("id", "") != step_id:
		return
	cur["cur"] = mini(int(cur["goal"]), int(cur["cur"]) + n)
	if int(cur["cur"]) >= int(cur["goal"]):
		_toast("✅ 完成：%s" % cur["name"])
		_index += 1
		if _index >= _steps.size():
			_done = true
			_save()
			_toast("🎉 新手指引完成，自由探索吧！")
		else:
			_toast("📋 新任务：%s" % _current()["name"])
	refresh()

func _on_item_picked_up(item: ItemData, amount: int) -> void:
	if item and item.id == "wood":
		_advance("gather_wood", amount)

func _on_building_placed(building: BuildingData, _pos: Vector2) -> void:
	if building and building.id == "workbench":
		_advance("build_workbench", 1)

func _on_crop_harvested(_crop: CropData, _player_id: int) -> void:
	_advance("harvest_crop", 1)

func _on_trade_completed(_give: ItemData, _receive: ItemData) -> void:
	_advance("first_trade", 1)

func _toast(msg: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("hud"):
		if n.has_method("show_toast"):
			n.show_toast(msg, 2.4)
			return

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"done": _done}))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			_done = bool(d.get("done", false))
