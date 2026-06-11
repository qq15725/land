class_name LargeMap
extends Control

# 大地图（全屏）。挂在 HUD 🗺 按钮，玩家居中显示更大范围的地形与实体标记。
# 复用 Minimap 的绘制思路，但视野更大、带图例、可点击/按 M 关闭。

const SCALE := 4.0           # 1 屏幕 px = 4 world px（比小地图视野大）
const TILE_SIZE := 16
const STEP := 2              # terrain 采样步长（降密度）
const MARGIN := 48.0

const BG_COLOR := Color(0.05, 0.07, 0.05, 0.93)
const PLAYER_COLOR := Color(1.0, 0.95, 0.3)
const BUILDING_COLOR := Color(0.7, 0.5, 0.3)
const CREATURE_COLOR := Color(0.95, 0.3, 0.3)
const FARM_COLOR := Color(0.4, 0.85, 0.4)
const RESOURCE_COLOR := Color(0.55, 0.75, 0.45)
const TERRAIN_TINTS := {
	0: Color(0.22, 0.45, 0.15),
	1: Color(0.65, 0.55, 0.32),
	2: Color(0.38, 0.28, 0.14),
	3: Color(0.40, 0.40, 0.40),
}

var _player: Node2D = null
var _terrain_map: TileMapLayer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # 拦截点击（点空白关闭）
	visible = false
	_build_chrome()

func setup(player: Node2D) -> void:
	_player = player
	var world := player.get_tree().get_first_node_in_group("world")
	if world:
		_terrain_map = world.get_node_or_null("TerrainMap") as TileMapLayer

func toggle() -> void:
	visible = not visible

func _build_chrome() -> void:
	var title := Label.new()
	title.text = "🗺 大地图（M / 点击关闭）"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	title.position = Vector2(20, 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var legend := VBoxContainer.new()
	legend.position = Vector2(20, 52)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(legend)
	for entry in [["玩家", PLAYER_COLOR], ["建筑", BUILDING_COLOR], ["农田", FARM_COLOR], ["资源", RESOURCE_COLOR], ["怪物", CREATURE_COLOR]]:
		var l := Label.new()
		l.text = "● " + entry[0]
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", entry[1])
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		legend.add_child(l)

func _process(_delta: float) -> void:
	if visible and _player and is_instance_valid(_player):
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		visible = false
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_M:
		visible = false
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	if _player == null or not is_instance_valid(_player):
		return
	var center := size * 0.5
	var ppos := _player.global_position
	var view_radius := minf(size.x, size.y) * 0.5 - MARGIN

	# 地形采样
	if _terrain_map:
		var ptile := Vector2i(int(ppos.x / TILE_SIZE), int(ppos.y / TILE_SIZE))
		var rng := int(view_radius * SCALE / TILE_SIZE) + 1
		var block := STEP * TILE_SIZE / SCALE
		for dy in range(-rng, rng + 1, STEP):
			for dx in range(-rng, rng + 1, STEP):
				var t := ptile + Vector2i(dx, dy)
				var sid := _terrain_map.get_cell_source_id(t)
				if sid < 0:
					continue
				var d := Vector2(dx * TILE_SIZE, dy * TILE_SIZE) / SCALE
				if d.length() > view_radius:
					continue
				var col: Color = TERRAIN_TINTS.get(sid, Color(0.3, 0.3, 0.3))
				draw_rect(Rect2(center + d - Vector2(block * 0.5, block * 0.5), Vector2(block, block)), col, true)

	# 实体标记
	var layer: Node = _player.get_parent()
	if layer:
		for child in layer.get_children():
			if child == _player or not (child is Node2D):
				continue
			var c := child as Node2D
			var d := (c.global_position - ppos) / SCALE
			if d.length() > view_radius:
				continue
			var color: Color
			if c is FarmPlot:
				color = FARM_COLOR
			elif c is ResourceNode:
				color = RESOURCE_COLOR
			elif c is BuildingBase:
				color = BUILDING_COLOR
			elif c is Creature:
				color = CREATURE_COLOR
			else:
				continue
			draw_circle(center + d, 3.0, color)

	# 玩家点 + 朝向
	draw_circle(center, 5.0, PLAYER_COLOR)
	if "velocity" in _player:
		var vel: Vector2 = _player.velocity
		if vel.length() > 1.0:
			var dir := vel.normalized()
			var tip := center + dir * 12.0
			var l := center + dir.rotated(PI - 0.4) * 6.0
			var r := center + dir.rotated(PI + 0.4) * 6.0
			draw_colored_polygon(PackedVector2Array([tip, l, r]), PLAYER_COLOR)
