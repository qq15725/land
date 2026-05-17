extends DraggablePanel

# 技能树面板（K 键）。
# 节点 + 父子连线版：每个 ActiveSkillData 是一个节点；parent_skill_id 决定上方连线。
# 顶部 tab 切换：通用 / 当前职业。

const SLOT_KEYS := ["J", "Q", "E", "R", "G"]
const CLASS_NAMES := {"warrior": "战士", "mage": "法师", "archer": "弓手"}

const NODE_W := 92
const NODE_H := 132
const NODE_GAP_X := 32
const NODE_GAP_Y := 40

var _player: Player = null
var _class_lbl: Label
var _sp_lbl: Label
var _tab_row: HBoxContainer
var _tree_canvas: TreeCanvas         # 内部类，绘制节点 + 连线
var _tab_btns: Array[Button] = []
var _tab_class_ids: Array[String] = []
var _current_tab: int = 0

# ─── 内嵌：TreeCanvas 用于绘制连线 ───────────────────────────────────────
class TreeCanvas extends Control:
	# {from_node: Control, to_node: Control}
	var edges: Array = []

	func _draw() -> void:
		for e in edges:
			var a: Control = e["from"]
			var b: Control = e["to"]
			if a == null or b == null:
				continue
			var a_pt := a.position + Vector2(a.size.x * 0.5, a.size.y)        # 父节点底部中点
			var b_pt := b.position + Vector2(b.size.x * 0.5, 0)               # 子节点顶部中点
			var mid_y := (a_pt.y + b_pt.y) * 0.5
			var col := Color(0.6, 0.55, 0.4, 0.9)
			draw_line(a_pt, Vector2(a_pt.x, mid_y), col, 2.0)
			draw_line(Vector2(a_pt.x, mid_y), Vector2(b_pt.x, mid_y), col, 2.0)
			draw_line(Vector2(b_pt.x, mid_y), b_pt, col, 2.0)

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(720, 540)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	EventBus.skill_points_changed.connect(_on_sp_changed)
	EventBus.active_skill_learned.connect(_on_skill_learned)
	EventBus.player_class_changed.connect(_on_class_changed)

func _build_layout() -> void:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# 头部
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "技能树"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(make_close_button())

	# 状态条
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 16)
	vbox.add_child(status)
	_class_lbl = Label.new()
	_class_lbl.text = "职业：—"
	_class_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(_class_lbl)
	_sp_lbl = Label.new()
	_sp_lbl.text = "SP 0"
	_sp_lbl.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	status.add_child(_sp_lbl)

	vbox.add_child(HSeparator.new())

	# tab
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(_tab_row)

	# 树画布（在 ScrollContainer 里）
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 420)
	vbox.add_child(scroll)
	_tree_canvas = TreeCanvas.new()
	_tree_canvas.custom_minimum_size = Vector2(660, 420)
	scroll.add_child(_tree_canvas)

func _switch_tab(idx: int) -> void:
	_current_tab = idx
	for i in _tab_btns.size():
		_tab_btns[i].button_pressed = (i == idx)
	_refresh()

func _ensure_player() -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		_player = (players[0] as Player) if not players.is_empty() else null

func _refresh() -> void:
	_ensure_player()
	if _player == null:
		return
	var act: PlayerActiveSkills = _player.active_skills
	var cls_id: String = act.class_id
	var cls: ClassData = ItemDatabase.get_class_data(cls_id) if not cls_id.is_empty() else null
	_class_lbl.text = "职业：%s" % (cls.display_name if cls != null else "通用")
	_sp_lbl.text = "SP %d" % act.skill_points

	_rebuild_tabs(cls_id)
	var tab_class: String = _tab_class_ids[_current_tab]

	# 清空 canvas
	for c in _tree_canvas.get_children():
		c.queue_free()
	_tree_canvas.edges.clear()

	# 取本 tab 所有技能
	var skills: Array = []
	for s in ItemDatabase.get_all_active_skills():
		var sd := s as ActiveSkillData
		if sd.class_id == tab_class:
			skills.append(sd)

	# 计算每个技能的 depth
	var depth_map: Dictionary = {}    # id → depth
	var skill_by_id: Dictionary = {}
	for s in skills:
		skill_by_id[s.id] = s
	for s in skills:
		depth_map[s.id] = _calc_depth(s, skill_by_id, {})

	# 按 depth 分组
	var by_depth: Dictionary = {}     # depth → [skill]
	for s in skills:
		var d: int = depth_map[s.id]
		if not by_depth.has(d):
			by_depth[d] = []
		(by_depth[d] as Array).append(s)

	# 排序：每层按 parent 的 x 排序，使连线尽量不交叉
	var node_map: Dictionary = {}     # id → Control
	var sorted_depths: Array = by_depth.keys()
	sorted_depths.sort()
	var max_x := 0
	for depth in sorted_depths:
		var layer: Array = by_depth[depth]
		# 简单：按 id 字典序稳定排
		layer.sort_custom(func(a, b): return a.id < b.id)
		var start_x := NODE_GAP_X
		for i in layer.size():
			var sd: ActiveSkillData = layer[i]
			var node := _make_node(sd)
			node.position = Vector2(start_x + i * (NODE_W + NODE_GAP_X), NODE_GAP_Y + depth * (NODE_H + NODE_GAP_Y))
			_tree_canvas.add_child(node)
			node_map[sd.id] = node
			max_x = maxi(max_x, int(node.position.x + NODE_W))

	# 连父子边
	for s in skills:
		var sd := s as ActiveSkillData
		if sd.parent_skill_id.is_empty():
			continue
		if node_map.has(sd.parent_skill_id):
			_tree_canvas.edges.append({"from": node_map[sd.parent_skill_id], "to": node_map[sd.id]})

	# 调整画布尺寸
	var total_h := (sorted_depths.size() if sorted_depths.size() > 0 else 1) * (NODE_H + NODE_GAP_Y) + NODE_GAP_Y
	_tree_canvas.custom_minimum_size = Vector2(maxi(660, max_x + NODE_GAP_X), total_h)
	_tree_canvas.queue_redraw()

func _calc_depth(s: ActiveSkillData, skill_by_id: Dictionary, visited: Dictionary) -> int:
	if visited.has(s.id):
		return 0  # 环保护
	visited[s.id] = true
	if s.parent_skill_id.is_empty() or not skill_by_id.has(s.parent_skill_id):
		return 0
	return 1 + _calc_depth(skill_by_id[s.parent_skill_id], skill_by_id, visited)

func _rebuild_tabs(cls_id: String) -> void:
	var ids: Array[String] = [""]
	var names: Array[String] = ["通用"]
	if not cls_id.is_empty():
		ids.append(cls_id)
		names.append(CLASS_NAMES.get(cls_id, cls_id))
	if ids == _tab_class_ids:
		for i in _tab_btns.size():
			_tab_btns[i].button_pressed = (i == _current_tab)
		return
	_tab_class_ids = ids
	for b in _tab_btns:
		b.queue_free()
	_tab_btns.clear()
	if _current_tab >= ids.size():
		_current_tab = 0
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.button_pressed = (i == _current_tab)
		var idx := i
		b.pressed.connect(func(): _switch_tab(idx))
		_tab_row.add_child(b)
		_tab_btns.append(b)

func _make_node(skill: ActiveSkillData) -> Control:
	# 冒险岛风格：图标 + 名字 + 等级 Lv X/Max + [+] 学习按钮 + Q/E/R/G 装配
	var act: PlayerActiveSkills = _player.active_skills
	var cur_level := act.get_skill_level(skill.id)
	var is_learned := act.is_learned(skill.id)
	var unlocked := act.is_unlocked(skill)
	var parent_ok := skill.parent_skill_id.is_empty() or act.is_learned(skill.parent_skill_id)
	var can_plus := act.can_learn(skill) and cur_level < skill.max_level

	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(NODE_W, NODE_H)
	root.size = Vector2(NODE_W, NODE_H)
	root.tooltip_text = "%s\n%s\nMP %d  CD %.1fs  Lv≥%d" % [skill.display_name, skill.description, int(skill.mp_cost), skill.cooldown, skill.unlock_level]
	root.add_theme_stylebox_override("panel", _node_style(is_learned, unlocked and parent_ok))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	root.add_child(v)

	# 1) 图标区（占顶部 56px 高）
	var icon_box := Panel.new()
	icon_box.custom_minimum_size = Vector2(NODE_W - 8, 56)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.add_theme_stylebox_override("panel", _icon_inset_style(is_learned))
	v.add_child(icon_box)

	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 4
	icon_rect.offset_right = -4
	icon_rect.offset_top = 4
	icon_rect.offset_bottom = -4
	icon_rect.texture = ItemDatabase.get_skill_icon(skill)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not is_learned or not parent_ok:
		icon_rect.modulate = Color(0.5, 0.5, 0.55)
	icon_box.add_child(icon_rect)

	# 锁标（前置未满足）
	if not parent_ok or (not is_learned and not unlocked):
		var lock := Label.new()
		lock.text = "🔒"
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.add_theme_font_size_override("font_size", 20)
		lock.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
		icon_box.add_child(lock)

	# 2) 技能名（小字）
	var name_lbl := Label.new()
	name_lbl.text = skill.display_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78) if is_learned else Color(0.78, 0.78, 0.78))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	v.add_child(name_lbl)

	# 3) Lv X/Max + [+] 按钮（冒险岛核心元素）
	var lv_row := HBoxContainer.new()
	lv_row.add_theme_constant_override("separation", 4)
	lv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(lv_row)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv %d/%d" % [cur_level, skill.max_level]
	lv_lbl.add_theme_font_size_override("font_size", 10)
	lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if cur_level > 0 else Color(0.7, 0.7, 0.7))
	lv_row.add_child(lv_lbl)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(22, 18)
	plus_btn.add_theme_font_size_override("font_size", 14)
	plus_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if can_plus else Color(0.4, 0.4, 0.4))
	plus_btn.tooltip_text = "学习 (-%d SP)" % skill.sp_cost
	if can_plus:
		plus_btn.pressed.connect(func(): PlayerActions.request_learn_skill(skill.id))
	else:
		plus_btn.disabled = true
	lv_row.add_child(plus_btn)

	# 4) Q/E/R/G 装配（仅已学的主动/buff 技能可装；passive 不可装）
	var equippable := skill.shape != "passive"
	if equippable:
		var equip_row := HBoxContainer.new()
		equip_row.add_theme_constant_override("separation", 1)
		equip_row.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(equip_row)
		for slot_i in range(1, 5):
			var sb_btn := Button.new()
			sb_btn.text = SLOT_KEYS[slot_i]
			sb_btn.custom_minimum_size = Vector2(18, 16)
			sb_btn.add_theme_font_size_override("font_size", 9)
			var is_equipped: bool = _player.equipped_skills[slot_i] == skill.id
			sb_btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if is_equipped else Color(0.7, 0.7, 0.7))
			var captured_slot := slot_i
			var captured_id := skill.id
			sb_btn.pressed.connect(func(): _on_equip_clicked(captured_slot, captured_id, is_equipped))
			if not is_learned:
				sb_btn.disabled = true
			equip_row.add_child(sb_btn)
	else:
		var passive_lbl := Label.new()
		passive_lbl.text = "被动"
		passive_lbl.add_theme_font_size_override("font_size", 9)
		passive_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
		passive_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(passive_lbl)

	return root

func _node_style(is_learned: bool, available: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if is_learned:
		sb.bg_color = Color(0.16, 0.16, 0.20, 0.96)
		sb.border_color = Color(1.0, 0.85, 0.3)
		sb.set_border_width_all(2)
	elif available:
		sb.bg_color = Color(0.10, 0.10, 0.14, 0.96)
		sb.border_color = Color(0.55, 0.55, 0.50)
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.06, 0.06, 0.08, 0.96)
		sb.border_color = Color(0.30, 0.30, 0.30)
		sb.set_border_width_all(1)
	for r in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(r, 4)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _icon_inset_style(is_learned: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.06, 0.95) if is_learned else Color(0.02, 0.02, 0.04, 0.95)
	sb.border_color = Color(0.30, 0.30, 0.30)
	sb.set_border_width_all(1)
	for r in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(r, 3)
	return sb

func _on_equip_clicked(slot: int, skill_id: String, was_equipped: bool) -> void:
	var target_id := "" if was_equipped else skill_id
	PlayerActions.request_equip_skill(slot, target_id)
	_refresh()

# ─── 事件 ────────────────────────────────────────────────────────────────

func _on_sp_changed(_pid: int, _total: int) -> void:
	if visible:
		_refresh()

func _on_skill_learned(_pid: int, _sid: String, _lv: int) -> void:
	if visible:
		_refresh()

func _on_class_changed(_pid: int, _cls: String) -> void:
	if visible:
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_menu"):
		if visible:
			hide()
		else:
			_refresh()
			show()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
