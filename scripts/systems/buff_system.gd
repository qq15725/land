extends Node

# Buff 数据库 + 全局事件桥。
# BuffSystem 自己不持有状态；状态在每个 player 的 BuffComponent 上。
# 这里 autoload 仅负责加载 buff 定义 + 监听全局事件（节日开始 → 给本地玩家挂 buff）。

const DATA_PATH := "res://data/buffs.json"

var _buffs: Dictionary = {}    # id → Dictionary

func _ready() -> void:
	_load()
	FestivalSystem.festival_started.connect(_on_festival_started)

func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		for b in parsed:
			_buffs[(b as Dictionary).get("id", "")] = b

func get_buff(id: String) -> Dictionary:
	return _buffs.get(id, {})

func get_all() -> Array:
	return _buffs.values()

func _on_festival_started(fid: String) -> void:
	# 丰收节自动给所有玩家挂 harvest_blessing
	if fid != "autumn_harvest":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for p in tree.get_nodes_in_group("player"):
		var bc := (p as Node).get_node_or_null("BuffComponent") as BuffComponent
		if bc:
			bc.add_buff("harvest_blessing")
