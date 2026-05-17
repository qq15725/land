extends Node

# 每日轮换的天气系统。新一天开始 → 按当前季节权重随机选天气。
# 影响层面：
#   - 作物生长速度（FarmPlot 查询 growth_multiplier）
#   - HUD weather_icon
#   - WorldWeatherFX（粒子 + 闪电）由 world 监听 weather_changed 信号挂

signal weather_changed(weather_id: String)

const DATA_PATH := "res://data/weather.json"

var _all: Array = []                # WeatherData dict 数组
var current_id: String = "clear"
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_data()
	# 启动时按当前季节摇一次
	_roll_for_season(TimeSystem.current_season())
	TimeSystem.day_started.connect(_on_day_started)

func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("weather.json 不存在")
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_all = parsed as Array

func _on_day_started(_d: int) -> void:
	_roll_for_season(TimeSystem.current_season())

func _roll_for_season(season: String) -> void:
	if _all.is_empty():
		return
	var total := 0.0
	for w in _all:
		total += float((w as Dictionary).get("season_weights", {}).get(season, 0))
	if total <= 0.0:
		_set_current("clear")
		return
	var roll := _rng.randf() * total
	var acc := 0.0
	for w in _all:
		var weight := float((w as Dictionary).get("season_weights", {}).get(season, 0))
		acc += weight
		if roll <= acc:
			_set_current((w as Dictionary).get("id", "clear"))
			return
	_set_current("clear")

func _set_current(id: String) -> void:
	if id == current_id:
		# 首次启动也要发一次信号，让 world 初始化视觉
		weather_changed.emit(current_id)
		return
	current_id = id
	weather_changed.emit(current_id)

func get_current() -> Dictionary:
	for w in _all:
		if (w as Dictionary).get("id", "") == current_id:
			return w as Dictionary
	return {}

func is_raining() -> bool:
	var c := get_current()
	return bool(c.get("rain", false))

func is_snowing() -> bool:
	var c := get_current()
	return bool(c.get("snow", false))

func is_thundering() -> bool:
	var c := get_current()
	return bool(c.get("thunder", false))

func growth_multiplier() -> float:
	var c := get_current()
	return float(c.get("growth_multiplier", 1.0))

func icon_index() -> int:
	var c := get_current()
	return int(c.get("icon_index", 0))

func display_name() -> String:
	var c := get_current()
	return c.get("display_name", "晴")
