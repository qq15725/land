extends Node

## 视野迷雾（战争迷雾）系统。
## 网格化，每格三态——未探索(全黑) / 已探索(半明,仅地形) / 当前可见(全亮+实体显示)。
## 单一真相来源：可见集既驱动遮罩 shader（阶段1），又控制 YSortLayer 下动态实体的 visible。
##
## 阶段0：可见集计算(射线 LOS) + 实体可见性控制。
## 单机先行：set_observer(本地玩家)，纯本地零 RPC；多人时每客户端各盯自己的玩家。

const CELL := 16          # 迷雾格边长 = 1 tile
const VIEW_RADIUS := 9    # 视野半径（格）
const EXPLORED_ALPHA := 140  # 已探索半暗的目标 alpha（≈0.55×255）
const SIGHT_BLOCK_MIN_H := 8.0  # 碰撞框高度≥此值才挡视线（滤掉花/蘑菇/小灌木等矮物）

# 网格几何（取自 WorldGenerator.last_map_*）
var _origin := Vector2i(-160, -160)
var _w := 320
var _h := 320

var _explored := PackedByteArray()   # 0=未探索 1=已探索（阶段2持久化）
var _blocker := PackedByteArray()    # 0=通透 1=遮挡视线
var _visible: Dictionary = {}        # Vector2i → true，当前帧可见集
var _prev_cell := Vector2i(0x7fffffff, 0x7fffffff)

var _observer: Node2D = null
var _dynamic: Array[Node2D] = []     # 受可见性控制的动态实体

var _fog_img: Image = null           # 三态网格纹理（r 通道存目标 alpha）
var _fog_tex: ImageTexture = null

var _map_id: String = ""             # 当前地图 id（per-map 记忆）
var _memory: Dictionary = {}         # map_id → PackedByteArray（已探索记忆，持久化）


func setup_grid(origin: Vector2i, w: int, h: int, map_id: String = "") -> void:
	_flush()  # 切图前先把当前地图的探索记忆存回 _memory
	_map_id = map_id
	_origin = origin
	_w = maxi(1, w)
	_h = maxi(1, h)
	# 恢复该地图的探索记忆；尺寸不匹配（地图变了）则重建
	var saved: Variant = _memory.get(map_id, null)
	if saved is PackedByteArray and (saved as PackedByteArray).size() == _w * _h:
		_explored = (saved as PackedByteArray).duplicate()
	else:
		_explored = PackedByteArray()
		_explored.resize(_w * _h)
	_blocker = PackedByteArray()
	_blocker.resize(_w * _h)
	_visible.clear()
	_prev_cell = Vector2i(0x7fffffff, 0x7fffffff)
	_ensure_fog_texture()


func set_observer(node: Node2D) -> void:
	_observer = node
	_prev_cell = Vector2i(0x7fffffff, 0x7fffffff)  # 强制下一帧重算


# ── 动态实体注册（实体 _ready 里紧随 NetworkRegistry.attach 调用）──
func register_dynamic(node: Node2D) -> void:
	if node in _dynamic:
		return
	_dynamic.append(node)
	if not node.tree_exited.is_connected(_on_dynamic_exited):
		node.tree_exited.connect(_on_dynamic_exited.bind(node))


func _on_dynamic_exited(node: Node2D) -> void:
	_dynamic.erase(node)


# ── 坐标换算 ──
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))


func _in_bounds(gx: int, gy: int) -> bool:
	return gx >= _origin.x and gx < _origin.x + _w and gy >= _origin.y and gy < _origin.y + _h


func _idx(gx: int, gy: int) -> int:
	return (gy - _origin.y) * _w + (gx - _origin.x)


# ── 遮挡位图 ──
func is_blocker_cell(gx: int, gy: int) -> bool:
	if not _in_bounds(gx, gy):
		return true  # 界外视为遮挡
	return _blocker[_idx(gx, gy)] != 0


func _mark_blocker_rect(rect: Rect2) -> void:
	var c0 := world_to_cell(rect.position)
	var c1 := world_to_cell(rect.position + rect.size)
	for gy in range(c0.y, c1.y + 1):
		for gx in range(c0.x, c1.x + 1):
			if _in_bounds(gx, gy):
				_blocker[_idx(gx, gy)] = 1


# 从 YSortLayer 的遮挡实体（树/石/建筑，StaticBody2D + 矩形碰撞）全量重建 blocker
func rebuild_blockers(y_sort_layer: Node) -> void:
	for i in range(_blocker.size()):
		_blocker[i] = 0
	for e in y_sort_layer.get_children():
		var rect: Variant = _occluder_rect(e)
		if rect != null:
			_mark_blocker_rect(rect)
	_prev_cell = Vector2i(0x7fffffff, 0x7fffffff)  # blocker 变了，强制重算


func _occluder_rect(e: Node) -> Variant:
	# 只有高大静态物体挡视线：树/石/矿/灌木丛/建筑。矮物（花/蘑菇/小灌木）放行。
	if not (e is StaticBody2D):
		return null
	var col := e.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not (col.shape is RectangleShape2D):
		return null
	var sz: Vector2 = (col.shape as RectangleShape2D).size
	if sz.y < SIGHT_BLOCK_MIN_H:
		return null  # 矮物体不挡视线
	var center: Vector2 = (e as Node2D).global_position + col.position
	return Rect2(center - sz * 0.5, sz)


# ── 可见性更新（world 每帧调；换格才重算可见集，每帧应用实体显隐）──
func update_visibility() -> void:
	if _observer == null or not is_instance_valid(_observer):
		return
	var pc := world_to_cell(_observer.global_position)
	if pc != _prev_cell:
		_prev_cell = pc
		_recompute(pc)
		_update_fog_texture()
	_apply_entity_visibility()


func _recompute(center: Vector2i) -> void:
	_visible.clear()
	var r2 := VIEW_RADIUS * VIEW_RADIUS
	for gy in range(center.y - VIEW_RADIUS, center.y + VIEW_RADIUS + 1):
		for gx in range(center.x - VIEW_RADIUS, center.x + VIEW_RADIUS + 1):
			var dx := gx - center.x
			var dy := gy - center.y
			if dx * dx + dy * dy > r2:
				continue
			if _los_clear(center, gx, gy):
				_mark_visible(gx, gy)


func _mark_visible(gx: int, gy: int) -> void:
	if not _in_bounds(gx, gy):
		return
	_visible[Vector2i(gx, gy)] = true
	_explored[_idx(gx, gy)] = 1


# Bresenham 视线：起点→终点途中（不含两端）遇 blocker 即被挡
func _los_clear(a: Vector2i, x1: int, y1: int) -> bool:
	var x0 := a.x
	var y0 := a.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		if x0 == x1 and y0 == y1:
			return true
		if not (x0 == a.x and y0 == a.y) and is_blocker_cell(x0, y0):
			return false
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return true


func is_visible_cell(c: Vector2i) -> bool:
	return _visible.has(c)


func _apply_entity_visibility() -> void:
	for e in _dynamic:
		if not is_instance_valid(e):
			continue
		var vis := _visible.has(world_to_cell(e.global_position))
		if e.visible != vis:
			e.visible = vis


# ── 遮罩纹理（阶段1）──
func _ensure_fog_texture() -> void:
	if _fog_img == null or _fog_img.get_width() != _w or _fog_img.get_height() != _h:
		_fog_img = Image.create(_w, _h, false, Image.FORMAT_L8)
		_fog_img.fill(Color(1, 1, 1))  # 初始全未探索（alpha=1 全黑）
		_fog_tex = ImageTexture.create_from_image(_fog_img)


func _update_fog_texture() -> void:
	_ensure_fog_texture()
	var data := PackedByteArray()
	data.resize(_w * _h)
	for i in range(_w * _h):
		data[i] = EXPLORED_ALPHA if _explored[i] != 0 else 255
	for c in _visible:
		var lx: int = c.x - _origin.x
		var ly: int = c.y - _origin.y
		if lx >= 0 and lx < _w and ly >= 0 and ly < _h:
			data[ly * _w + lx] = 0
	_fog_img.set_data(_w, _h, false, Image.FORMAT_L8, data)
	_fog_tex.update(_fog_img)


func get_fog_texture() -> Texture2D:
	_ensure_fog_texture()
	return _fog_tex


func grid_world_origin() -> Vector2:
	return Vector2(_origin.x, _origin.y) * CELL


func grid_world_size() -> Vector2:
	return Vector2(_w, _h) * CELL


# ── 存档（阶段2）──
func _flush() -> void:
	if _map_id != "" and _explored.size() > 0:
		_memory[_map_id] = _explored.duplicate()


func export_state() -> Dictionary:
	_flush()
	var out: Dictionary = {}
	for k in _memory:
		out[k] = Marshalls.raw_to_base64(_memory[k])
	return out


func import_state(data: Dictionary) -> void:
	_memory.clear()
	for k in data:
		_memory[k] = Marshalls.base64_to_raw(data[k])
