class_name DraggablePanel
extends PanelContainer

const DRAG_REGION_HEIGHT := 36

var _dragging := false
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	theme = UIStyle.theme

func _process(_d: float) -> void:
	# 标题拖拽区显示 MOVE cursor
	if not visible:
		return
	var mp := get_local_mouse_position()
	if Rect2(Vector2.ZERO, size).has_point(mp) and mp.y <= DRAG_REGION_HEIGHT:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW

# 统一关闭按钮工厂。所有面板用此创建关闭按钮，样式 / 行为一致。
func make_close_button() -> Button:
	var b := Button.new()
	b.text = "×"
	b.custom_minimum_size = Vector2(28, 28)
	b.tooltip_text = "关闭"
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.92, 0.85, 0.72))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.4))
	b.pressed.connect(hide)
	return b

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mb.position.y <= DRAG_REGION_HEIGHT:
				_dragging = true
				_detach_anchors()
				_drag_offset = global_position - mb.global_position
				get_viewport().set_input_as_handled()
			elif not mb.pressed and _dragging:
				_dragging = false
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		var new_pos := (event as InputEventMouseMotion).global_position + _drag_offset
		var vp := get_viewport_rect().size
		global_position = Vector2(
			clampf(new_pos.x, 0.0, vp.x - size.x),
			clampf(new_pos.y, 0.0, vp.y - size.y)
		)
		get_viewport().set_input_as_handled()

func _detach_anchors() -> void:
	if anchor_left == 0.0 and anchor_top == 0.0:
		return
	var gp := global_position
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	global_position = gp
