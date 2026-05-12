extends Node

# 简易音效系统。
# data/sounds.json 格式：[{"id": "pickup", "path": "res://assets/audio/pickup.wav", "volume_db": 0.0}]
# 接口：play("pickup")；通过 EventBus 自动播放常见事件。

const CONFIG_PATH := "res://data/sounds.json"
const POOL_SIZE := 6

var _streams: Dictionary = {}          # id -> AudioStream
var _volumes: Dictionary = {}          # id -> volume_db
var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0

func _ready() -> void:
	_load_config()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	EventBus.item_picked_up.connect(func(_i, _a): play("pickup"))
	EventBus.player_damaged.connect(func(_a): play("hurt"))
	EventBus.player_died.connect(func(): play("death"))
	EventBus.resource_depleted.connect(func(_n): play("collect"))
	EventBus.item_crafted.connect(func(_r): play("craft"))
	EventBus.item_used.connect(func(_i): play("use"))
	EventBus.trade_completed.connect(func(_g, _r): play("trade"))
	BuildingSystem.building_placed.connect(func(_b, _p): play("place"))

func play(id: String) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		return
	var p := _players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = _volumes.get(id, 0.0)
	p.play()

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
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStream
		if stream:
			_streams[id] = stream
			_volumes[id] = float(entry.get("volume_db", 0.0))
