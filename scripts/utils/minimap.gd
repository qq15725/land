class_name Minimap
extends Control

# 小地图实绘组件。叠在 hud_minimap.png 圆框内，每帧绘制：
# - 玩家居中黄点
# - 附近建筑（棕）/ 怪物（红）/ 农田（绿）按比例缩放定位

const SCALE := 8.0           # 1 minimap px = 8 world px
const VIEW_RADIUS := 78      # 内圆有效半径（hud_minimap.png 外环 16px）
const TILE_SIZE := 16        # 世界 tile 像素尺寸
const BG_COLOR := Color(0.12, 0.16, 0.10, 0.85)  # 内圆暗背景
const PLAYER_COLOR := Color(1.0, 0.95, 0.3)
const BUILDING_COLOR := Color(0.7, 0.5, 0.3)
const CREATURE_COLOR := Color(0.95, 0.3, 0.3)
const FARM_COLOR := Color(0.4, 0.85, 0.4)
const POI_COLOR := Color(1.0, 0.6, 0.2)

# 地形 source_id → minimap 色块（与 world_generator 的 TERRAIN_COLORS 对应）
const TERRAIN_TINTS := {
	0: Color(0.22, 0.45, 0.15),  # grass
	1: Color(0.65, 0.55, 0.32),  # path
	2: Color(0.38, 0.28, 0.14),  # farmland
	3: Color(0.40, 0.40, 0.40),  # stone
}

var _player: Node2D = null
var _terrain_map: TileMap = null

func setup(player: Node2D) -> void:
	_player = player
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 查找世界 TerrainMap（与玩家在同一 world 节点下）
	var world := player.get_tree().get_first_node_in_group("world")
	if world:
		_terrain_map = world.get_node_or_null("TerrainMap") as TileMap

func _process(_delta: float) -> void:
	if _player and is_instance_valid(_player):
		queue_redraw()

func _draw() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var center: Vector2 = size * 0.5
	var ppos := _player.global_position

	# 内圆暗背景（让地形/实体点更清晰）
	draw_circle(center, VIEW_RADIUS, BG_COLOR)

	# 采样玩家附近 terrain，按 tile 画色点
	if _terrain_map:
		var step := 4  # 每 4 个 tile 采一次（降密度避免卡）
		var ptile := Vector2i(int(ppos.x / TILE_SIZE), int(ppos.y / TILE_SIZE))
		var rng := int(VIEW_RADIUS * SCALE / TILE_SIZE) + 1
		for dy in range(-rng, rng + 1, step):
			for dx in range(-rng, rng + 1, step):
				var t := ptile + Vector2i(dx, dy)
				var sid := _terrain_map.get_cell_source_id(0, t)
				if sid < 0:
					continue
				var d := Vector2(dx * TILE_SIZE, dy * TILE_SIZE) / SCALE
				if d.length() > VIEW_RADIUS:
					continue
				var col: Color = TERRAIN_TINTS.get(sid, Color(0.3, 0.3, 0.3))
				draw_rect(Rect2(center + d - Vector2(1.5, 1.5), Vector2(3, 3)), col, true)

	# 同级（YSortLayer）的其他实体
	var layer: Node = _player.get_parent()
	if layer:
		for child in layer.get_children():
			if child == _player or not (child is Node2D):
				continue
			var c := child as Node2D
			var d := (c.global_position - ppos) / SCALE
			if d.length() > VIEW_RADIUS:
				continue
			var color: Color
			if c is FarmPlot:
				color = FARM_COLOR
			elif c is BuildingBase:
				color = BUILDING_COLOR
			elif c is Creature:
				color = CREATURE_COLOR
			else:
				continue
			draw_circle(center + d, 2.0, color)

	# 玩家点（最上层）
	draw_circle(center, 3.0, PLAYER_COLOR)
	# 朝向小三角（指向最近移动方向）
	if _player.has_method("get") and "velocity" in _player:
		var vel: Vector2 = _player.velocity
		if vel.length() > 1.0:
			var dir := vel.normalized()
			var tip := center + dir * 8.0
			var left := center + dir.rotated(PI - 0.4) * 4.0
			var right := center + dir.rotated(PI + 0.4) * 4.0
			draw_colored_polygon(PackedVector2Array([tip, left, right]), PLAYER_COLOR)
