extends CanvasLayer

const JOY_RADIUS := 70.0
const JOY_DEAD_ZONE := 0.15

var _joy_touch_id: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_active: bool = false

var _outer: Control
var _knob: Control
var _pressed_moves: Array[String] = []


func _ready() -> void:
	layer = 8
	if OS.get_name() != "Android":
		queue_free()
		return
	_build_joystick()
	_build_buttons()


func _build_joystick() -> void:
	_outer = Control.new()
	_outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_outer)

	var outer_ring := ColorRect.new()
	outer_ring.name = "OuterRing"
	outer_ring.custom_minimum_size = Vector2(JOY_RADIUS * 2, JOY_RADIUS * 2)
	outer_ring.color = Color(1, 1, 1, 0.15)
	outer_ring.visible = false
	_outer.add_child(outer_ring)

	_knob = ColorRect.new()
	_knob.custom_minimum_size = Vector2(40, 40)
	_knob.color = Color(1, 1, 1, 0.45)
	_knob.visible = false
	_outer.add_child(_knob)

	_outer.set_process_input(true)


func _build_buttons() -> void:
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.set_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.offset_left = -180
	anchor.offset_top = -180
	anchor.offset_right = -20
	anchor.offset_bottom = -20
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)

	_add_action_btn(anchor, "攻击", "attack", Vector2(120, 80))
	_add_action_btn(anchor, "交互\n[E]", "interact", Vector2(40, 20))


func _add_action_btn(parent: Control, label: String, action: String, pos: Vector2) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(72, 72)
	btn.position = pos
	btn.button_down.connect(func(): Input.action_press(action))
	btn.button_up.connect(func(): Input.action_release(action))
	parent.add_child(btn)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var half_w := get_viewport().get_visible_rect().size.x * 0.5
	if event.pressed:
		if _joy_touch_id == -1 and event.position.x < half_w:
			_joy_touch_id = event.index
			_joy_center = event.position
			_joy_active = true
			_show_joystick(event.position)
	else:
		if event.index == _joy_touch_id:
			_joy_touch_id = -1
			_joy_active = false
			_hide_joystick()
			_release_all_moves()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _joy_active or event.index != _joy_touch_id:
		return
	var delta := event.position - _joy_center
	var dist := delta.length()
	var dir := delta / max(dist, 1.0)
	var strength := clampf(dist / JOY_RADIUS, 0.0, 1.0)

	_move_knob(_joy_center + dir * minf(dist, JOY_RADIUS))

	if strength < JOY_DEAD_ZONE:
		_release_all_moves()
		return

	_set_move("move_up",    maxf(0.0, -dir.y) * strength)
	_set_move("move_down",  maxf(0.0,  dir.y) * strength)
	_set_move("move_left",  maxf(0.0, -dir.x) * strength)
	_set_move("move_right", maxf(0.0,  dir.x) * strength)


func _set_move(action: String, strength: float) -> void:
	if strength > JOY_DEAD_ZONE:
		Input.action_press(action, strength)
		if action not in _pressed_moves:
			_pressed_moves.append(action)
	else:
		Input.action_release(action)
		_pressed_moves.erase(action)


func _release_all_moves() -> void:
	for a in _pressed_moves:
		Input.action_release(a)
	_pressed_moves.clear()


func _show_joystick(center: Vector2) -> void:
	var outer_ring := _outer.get_node("OuterRing") as ColorRect
	outer_ring.position = center - Vector2(JOY_RADIUS, JOY_RADIUS)
	outer_ring.visible = true
	_knob.visible = true
	_move_knob(center)


func _move_knob(pos: Vector2) -> void:
	_knob.position = pos - Vector2(20, 20)


func _hide_joystick() -> void:
	_outer.get_node("OuterRing").visible = false
	_knob.visible = false
