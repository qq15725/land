extends Node

# 节日 / 季节事件系统。每个新一天检查 (season, day_in_season) 是否触发节日。
# 节日只持续当天，第二天 day_started 触发时自动失效。

signal festival_started(festival_id: String)
signal festival_ended(festival_id: String)

const DATA_PATH := "res://data/festivals.json"

var _all: Array = []
var current_id: String = ""    # "" = 今天没有节日

func _ready() -> void:
	_load_data()
	TimeSystem.day_started.connect(_on_day_started)
	# 启动当天也检查一次
	call_deferred("_check_today")

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_all = parsed as Array

func _on_day_started(_d: int) -> void:
	_check_today()

func _check_today() -> void:
	var season := TimeSystem.current_season()
	var d := TimeSystem.day_in_season()
	var found_id := ""
	for f in _all:
		var fd := f as Dictionary
		if fd.get("season", "") == season and int(fd.get("day_in_season", 0)) == d:
			found_id = fd.get("id", "")
			break
	if found_id == current_id:
		return
	if not current_id.is_empty():
		festival_ended.emit(current_id)
	current_id = found_id
	if not current_id.is_empty():
		festival_started.emit(current_id)

func get_current() -> Dictionary:
	for f in _all:
		var fd := f as Dictionary
		if fd.get("id", "") == current_id:
			return fd
	return {}

func is_active(id: String) -> bool:
	return current_id == id

func growth_bonus() -> float:
	var c := get_current()
	return float(c.get("growth_bonus", 1.0))

func display_name() -> String:
	var c := get_current()
	return c.get("display_name", "")

func description() -> String:
	var c := get_current()
	return c.get("description", "")
