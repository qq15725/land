class_name Minimap
extends Control

# 小地图实绘组件。叠在 hud_minimap.png 圆框内，每帧绘制：
# - 玩家居中黄点
# - 附近建筑（棕）/ 怪物（红）/ 农田（绿）按比例缩放定位

const SCALE := 8.0           # 1 minimap px = 8 world px
const VIEW_RADIUS := 78      # 内圆有效半径（hud_minimap.png 外环 16px）
const PLAYER_COLOR := Color(1.0, 0.95, 0.3)
const BUILDING_COLOR := Color(0.7, 0.5, 0.3)
const CREATURE_COLOR := Color(0.95, 0.3, 0.3)
const FARM_COLOR := Color(0.4, 0.85, 0.4)
const POI_COLOR := Color(1.0, 0.6, 0.2)

var _player: Node2D = null

func setup(player: Node2D) -> void:
	_player = player
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if _player and is_instance_valid(_player):
		queue_redraw()

func _draw() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var center: Vector2 = size * 0.5
	var ppos := _player.global_position

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
