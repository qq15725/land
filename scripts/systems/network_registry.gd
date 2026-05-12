extends Node

# 实体注册表（G2）。
#
# 所有跨网络/跨持久化引用的实体（Player / Building / FarmPlot / Animal /
# Creature / DropItem / ResourceNode）启动时通过 attach(self) 注册并获得
# 稳定的 int network_id。RPC、存档、事件信号传 id 而非 Node 引用。
#
# 单机模式下也工作：Network.is_server() 为 true 时本地分配 id，next_id 由
# SaveSystem 持久化避免读档冲突。client 模式下 spawn 由 server 携带 id 传
# 来（G8 接通），attach 用 forced_id 显式注入。

const INVALID_ID := 0
# 0..999 保留给静态/特殊用途；从 1000 开始分配实体 id
const FIRST_DYNAMIC_ID := 1000

var _next_id: int = FIRST_DYNAMIC_ID
var _id_to_node: Dictionary = {}  # int → Node
var _node_to_id: Dictionary = {}  # Node → int

func attach(node: Node, forced_id: int = 0) -> int:
	var id := forced_id
	if id <= 0:
		if not Network.is_server():
			push_error("[NetworkRegistry] non-server attaching '%s' without forced id" % node.name)
			return INVALID_ID
		id = _allocate_id()
	if _id_to_node.has(id):
		var old: Node = _id_to_node[id]
		push_warning("[NetworkRegistry] id %d collision: existing=%s new=%s" % [id, old.name if old else "<freed>", node.name])
	_id_to_node[id] = node
	_node_to_id[node] = id
	node.set_meta("network_id", id)
	if not node.tree_exited.is_connected(_on_node_exited):
		node.tree_exited.connect(_on_node_exited.bind(node))
	return id

func _allocate_id() -> int:
	var id := _next_id
	_next_id += 1
	return id

func _on_node_exited(node: Node) -> void:
	var id: int = _node_to_id.get(node, INVALID_ID)
	if id == INVALID_ID:
		return
	_id_to_node.erase(id)
	_node_to_id.erase(node)

func get_node_by_id(id: int) -> Node:
	return _id_to_node.get(id, null)

func get_id(node: Node) -> int:
	return _node_to_id.get(node, INVALID_ID)

func has_id(id: int) -> bool:
	return _id_to_node.has(id)

func count() -> int:
	return _id_to_node.size()

# ─── 存档 ────────────────────────────────────────────────────────────────

func export_state() -> Dictionary:
	return {"next_id": _next_id}

func import_state(data: Dictionary) -> void:
	# 不能让 _next_id 回退，否则会与已 attach 实体（如 Player）的 id 冲突。
	var saved := int(data.get("next_id", FIRST_DYNAMIC_ID))
	_next_id = maxi(_next_id, maxi(FIRST_DYNAMIC_ID, saved))

func reset() -> void:
	_id_to_node.clear()
	_node_to_id.clear()
	_next_id = FIRST_DYNAMIC_ID
