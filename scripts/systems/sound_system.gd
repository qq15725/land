extends Node

# 简易音效与 BGM 系统。
# data/sounds.json 同时定义 SFX 和 BGM：
#   {"id": "pickup",   "path": "...", "volume_db": -4.0}            ← SFX
#   {"id": "bgm_day",  "path": "...", "volume_db": -10.0, "loop": true}  ← BGM
# 接口：
#   play(id)          一次性 SFX
#   play_bgm(id)      切换循环 BGM（相同 id 重复调用 noop）
#   stop_bgm()        停止 BGM

const CONFIG_PATH := "res://data/sounds.json"
const SETTINGS_PATH := "user://settings.json"
const SFX_POOL_SIZE := 6
const BUS_SFX := "SFX"
const BUS_BGM := "BGM"

var _streams: Dictionary = {}          # id -> AudioStream
var _volumes: Dictionary = {}          # id -> volume_db
var _loops: Dictionary = {}            # id -> bool（是否 BGM）
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_idx: int = 0

var _bgm_player: AudioStreamPlayer = null
var _current_bgm_id: String = ""

# 设置：线性音量 [0, 1]，初始为 1.0
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var bgm_volume: float = 1.0
var fullscreen: bool = false

func _ready() -> void:
	_ensure_buses()
	_load_config()
	_load_settings()
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)

	_apply_audio_settings()
	_apply_display_settings()

	EventBus.item_picked_up.connect(func(_i, _a): play("pickup"))
	EventBus.player_damaged.connect(func(_a): play("hurt"))
	EventBus.player_died.connect(func(): play("death"))
	EventBus.resource_depleted.connect(func(_rid, _pid): play("collect"))
	EventBus.item_crafted.connect(func(_r): play("craft"))
	EventBus.item_used.connect(func(_i): play("use"))
	EventBus.trade_completed.connect(func(_g, _r): play("trade"))
	BuildingSystem.building_placed.connect(func(_b, _p): play("place"))

	TimeSystem.day_started.connect(func(_d): _refresh_world_bgm())
	TimeSystem.night_started.connect(func(_d): _refresh_world_bgm())

	# C3：全局监听 Button 节点，自动连 pressed → ui_click
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Button:
		(node as Button).pressed.connect(func(): play("ui_click"))

func play(id: String) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return
	var p := _sfx_players[_next_sfx_idx]
	_next_sfx_idx = (_next_sfx_idx + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = _volumes.get(id, 0.0)
	p.play()

func play_bgm(id: String) -> void:
	if id == _current_bgm_id and _bgm_player.playing:
		return
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		# 无音频文件时静默切换记录，不报错
		_current_bgm_id = id
		_bgm_player.stop()
		return
	_current_bgm_id = id
	_bgm_player.stream = stream
	_bgm_player.volume_db = _volumes.get(id, -10.0)
	_bgm_player.play()

func stop_bgm() -> void:
	_current_bgm_id = ""
	_bgm_player.stop()

# world.gd 进入场景时调一次；昼夜切换由 TimeSystem 信号自动驱动
func play_world_bgm() -> void:
	_refresh_world_bgm()

func _refresh_world_bgm() -> void:
	play_bgm("bgm_night" if TimeSystem.is_night() else "bgm_day")

func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_SFX)
	if AudioServer.get_bus_index(BUS_BGM) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_BGM)

# ─── 设置接口 ────────────────────────────────────────────────────────────────

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func set_bgm_volume(v: float) -> void:
	bgm_volume = clampf(v, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func set_fullscreen(v: bool) -> void:
	fullscreen = v
	_apply_display_settings()
	_save_settings()

func _apply_audio_settings() -> void:
	AudioServer.set_bus_volume_db(0, _linear_to_db(master_volume))
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _linear_to_db(sfx_volume))
	var bgm_idx := AudioServer.get_bus_index(BUS_BGM)
	if bgm_idx != -1:
		AudioServer.set_bus_volume_db(bgm_idx, _linear_to_db(bgm_volume))

func _apply_display_settings() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _linear_to_db(v: float) -> float:
	if v <= 0.0001:
		return -80.0
	return linear_to_db(v)

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data == null:
		return
	master_volume = float((data as Dictionary).get("master_volume", 1.0))
	sfx_volume = float((data as Dictionary).get("sfx_volume", 1.0))
	bgm_volume = float((data as Dictionary).get("bgm_volume", 1.0))
	fullscreen = bool((data as Dictionary).get("fullscreen", false))

func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"bgm_volume": bgm_volume,
		"fullscreen": fullscreen,
	}, "\t"))

# ─── 数据加载 ────────────────────────────────────────────────────────────────

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var result: Variant = JSON.parse_string(file.get_as_text())
	if result == null:
		push_error("sounds.json 解析失败")
		return
	for entry in (result as Array):
		var id: String = entry.get("id", "")
		var path: String = entry.get("path", "")
		if id.is_empty() or path.is_empty():
			continue
		_volumes[id] = float(entry.get("volume_db", 0.0))
		_loops[id] = bool(entry.get("loop", id.begins_with("bgm_")))
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStream
		if stream:
			_streams[id] = stream
