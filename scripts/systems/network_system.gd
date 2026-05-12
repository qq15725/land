extends Node

# 多人协议层（G1）。
#
# 设计：host-authoritative，房主即权威。单机视为 1 人房间，默认挂载
# OfflineMultiplayerPeer —— multiplayer.is_server() 返回 true，
# get_unique_id() 返回 1，RPC 在本地直接执行，业务代码可以完全按多人路径写
# 而不需要 if-else 分支。
#
# 所有业务系统判断"我是否是权威"统一用 Network.is_server()，不要直接读
# multiplayer.is_server()，便于未来切换实现。

signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected

enum Mode { SINGLEPLAYER, HOST, CLIENT }

const DEFAULT_PORT := 24565
const DEFAULT_MAX_CLIENTS := 4
const SERVER_PEER_ID := 1

var mode: Mode = Mode.SINGLEPLAYER

func _ready() -> void:
	_enter_singleplayer()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ─── 查询 ────────────────────────────────────────────────────────────────

func is_server() -> bool:
	return multiplayer.is_server()

func is_singleplayer() -> bool:
	return mode == Mode.SINGLEPLAYER

func local_peer_id() -> int:
	return multiplayer.get_unique_id()

func connected_peers() -> PackedInt32Array:
	return multiplayer.get_peers()

# 包括 server 自己（peer_id = 1）在内的全部玩家 peer_id。
# server 节点上 peers 列表不含自己，需要补上。
func all_peer_ids() -> Array[int]:
	var result: Array[int] = []
	if mode == Mode.SINGLEPLAYER:
		result.append(SERVER_PEER_ID)
		return result
	if is_server():
		result.append(SERVER_PEER_ID)
	for id in multiplayer.get_peers():
		result.append(id)
	return result

# ─── 模式切换 ────────────────────────────────────────────────────────────

func start_host(port: int = DEFAULT_PORT, max_clients: int = DEFAULT_MAX_CLIENTS) -> Error:
	_close_current_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("无法监听端口 %d（错误 %d）" % [port, err])
		_enter_singleplayer()
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	return OK

func join(address: String, port: int = DEFAULT_PORT) -> Error:
	_close_current_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		push_error("无法连接 %s:%d（错误 %d）" % [address, port, err])
		_enter_singleplayer()
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	return OK

func close() -> void:
	_close_current_peer()
	_enter_singleplayer()

func _enter_singleplayer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.SINGLEPLAYER

func _close_current_peer() -> void:
	var p := multiplayer.multiplayer_peer
	if p == null:
		return
	if p is OfflineMultiplayerPeer:
		return
	if p.has_method("close"):
		p.close()

# ─── 内部回调 ────────────────────────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)

func _on_connected_to_server() -> void:
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()
	_enter_singleplayer()

func _on_server_disconnected() -> void:
	server_disconnected.emit()
	_enter_singleplayer()
