class_name FenceWood
extends BuildingBase

const CELL := 16.0

var _connected := {"n": false, "s": false, "e": false, "w": false}

func _ready() -> void:
	super._ready()
	add_to_group("fence")
	_update_connections()
	_notify_neighbors()

func _exit_tree() -> void:
	_notify_neighbors()

func _update_connections() -> void:
	var offsets := {"n": Vector2(0, -CELL), "s": Vector2(0, CELL), "e": Vector2(CELL, 0), "w": Vector2(-CELL, 0)}
	for dir in offsets:
		_connected[dir] = _find_fence_at(global_position + offsets[dir]) != null
	queue_redraw()

func _notify_neighbors() -> void:
	for offset in [Vector2(0, -CELL), Vector2(0, CELL), Vector2(CELL, 0), Vector2(-CELL, 0)]:
		var neighbor := _find_fence_at(global_position + offset)
		if neighbor and neighbor.has_method("_update_connections"):
			neighbor._update_connections()

func _find_fence_at(pos: Vector2) -> Node2D:
	for node in get_tree().get_nodes_in_group("fence"):
		if node != self and node.global_position.distance_to(pos) < CELL * 0.4:
			return node as Node2D
	return null

func _draw() -> void:
	_draw_fence(Color(0.55, 0.38, 0.22))

func _draw_fence(color: Color) -> void:
	var h := CELL * 0.5
	var has_n := _connected.get("n", false)
	var has_s := _connected.get("s", false)
	var has_e := _connected.get("e", false)
	var has_w := _connected.get("w", false)
	var any_h := has_e or has_w
	var any_v := has_n or has_s

	# 中心柱
	draw_rect(Rect2(-2.0, -4.0, 4.0, 8.0), color)

	# 横向梁（E-W）
	if has_e:
		draw_rect(Rect2(2.0, -2.5, h - 2.0, 2.0), color)
		draw_rect(Rect2(2.0, 1.0, h - 2.0, 2.0), color)
	if has_w:
		draw_rect(Rect2(-h, -2.5, h - 2.0, 2.0), color)
		draw_rect(Rect2(-h, 1.0, h - 2.0, 2.0), color)

	# 纵向梁（N-S）
	if has_n:
		draw_rect(Rect2(-1.0, -h, 2.0, h - 4.0), color)
	if has_s:
		draw_rect(Rect2(-1.0, 4.0, 2.0, h - 4.0), color)

	# 完全孤立时显示短横梁占位
	if not any_h and not any_v:
		draw_rect(Rect2(-h + 2.0, -1.0, CELL - 4.0, 2.0), color)
