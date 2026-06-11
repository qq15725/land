class_name AutomationNode
extends BuildingBase

# 自动化节点基类（传送带 / 抽取器 / 放入器的父类）。
# 占一个格子，有朝向；放置时注册到 AutomationSystem，销毁时注销。

const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]  # 上 右 下 左

var facing: int = 1
var grid_pos: Vector2i
var _moved_this_tick := false
var _arrow: Polygon2D
var _node_built := false

func setup_preview(data: BuildingData) -> void:
	super.setup_preview(data)
	_build_node_visual()
	_update_facing_visual()

func on_placed(data: BuildingData = null) -> void:
	setup_preview(data)
	grid_pos = AutomationSystem.world_to_grid(global_position)
	AutomationSystem.register(self)

func _exit_tree() -> void:
	AutomationSystem.unregister(self)

func set_facing(f: int) -> void:
	facing = ((f % 4) + 4) % 4
	_update_facing_visual()

func front_cell() -> Vector2i:
	return grid_pos + DIRS[facing]

func back_cell() -> Vector2i:
	return grid_pos + DIRS[(facing + 2) % 4]

# ─── 视觉（占位几何，美术后续替换） ───
func _node_color() -> Color:
	return Color(0.55, 0.55, 0.6, 0.95)

func _build_node_visual() -> void:
	if _node_built:
		return
	_node_built = true
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])
	base.color = _node_color()
	base.position = Vector2(0, -8)
	add_child(base)
	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(0, -5), Vector2(5, 2), Vector2(-5, 2)])
	_arrow.color = Color(1, 1, 1, 0.85)
	_arrow.position = Vector2(0, -8)
	add_child(_arrow)

func _update_facing_visual() -> void:
	if _arrow:
		_arrow.rotation = facing * PI / 2.0  # 箭头默认朝上(facing 0)

# ─── 物品流接口（子类按需实现） ───
func tick() -> void:
	pass

func can_accept(_item: ItemData) -> bool:
	return false

func push_item(_item: ItemData) -> bool:
	return false

func peek_item() -> ItemData:
	return null

func take_item() -> ItemData:
	return null

# ─── 存档 ───
func get_save_state() -> Dictionary:
	return {"facing": facing}

func load_save_state(data: Dictionary) -> void:
	set_facing(int(data.get("facing", 1)))
