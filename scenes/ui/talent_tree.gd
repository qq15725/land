extends DraggablePanel

# 技能树面板（K 键）。
# 内容：当前职业 + SP + 切职业按钮 + 技能列表（按职业分组）
# 每行技能：图标 / 名字 / 等级 / 描述 / [学习] / 4 个装配按钮 Q/E/R/G

const SLOT_KEYS := ["J", "Q", "E", "R", "G"]
const CLASS_NAMES := {"warrior": "战士", "mage": "法师", "archer": "弓手"}

var _player: Player = null
var _class_lbl: Label
var _sp_lbl: Label
var _tab_row: HBoxContainer
var _list: VBoxContainer
var _tab_btns: Array[Button] = []
var _tab_class_ids: Array[String] = []
var _current_tab: int = 0

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(560, 480)
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

	# 头部：标题 + 关闭
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "技能"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	# 状态条：职业 / SP
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

	# 职业 tab（动态：通用 + 当前职业），在 _refresh 中重建
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(_tab_row)

	# 技能列表（滚动）
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

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
	for c in _list.get_children():
		c.queue_free()
	if _player == null:
		return
	var act: PlayerActiveSkills = _player.active_skills
	var cls_id: String = act.class_id
	var cls: ClassData = ItemDatabase.get_class_data(cls_id) if not cls_id.is_empty() else null
	_class_lbl.text = "职业：%s" % (cls.display_name if cls != null else "通用")
	_sp_lbl.text = "SP %d" % act.skill_points

	_rebuild_tabs(cls_id)
	var tab_class: String = _tab_class_ids[_current_tab]
	for s in ItemDatabase.get_all_active_skills():
		var sd := s as ActiveSkillData
		if sd.class_id != tab_class:
			continue
		_list.add_child(_make_row(sd))

# 按当前职业重建 tab：通用 + 自己职业（无职业时只有通用）
func _rebuild_tabs(cls_id: String) -> void:
	var ids: Array[String] = [""]
	var names: Array[String] = ["通用"]
	if not cls_id.is_empty():
		ids.append(cls_id)
		names.append(CLASS_NAMES.get(cls_id, cls_id))
	if ids == _tab_class_ids:
		# 结构未变，只刷新按钮按下状态
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

func _make_row(skill: ActiveSkillData) -> Control:
	var act: PlayerActiveSkills = _player.active_skills
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.10, 0.12, 0.85)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	row.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	# 图标
	var icon_box := Panel.new()
	icon_box.custom_minimum_size = Vector2(48, 48)
	icon_box.add_theme_stylebox_override("panel", UIStyle.make_slot_style(false))
	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 6
	icon_rect.offset_right = -6
	icon_rect.offset_top = 6
	icon_rect.offset_bottom = -6
	icon_rect.texture = ItemDatabase.get_icon_at_grid(skill.icon_grid)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_box.add_child(icon_rect)
	hbox.add_child(icon_box)

	# 信息列
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var cur_level := act.get_skill_level(skill.id)
	var name_row := HBoxContainer.new()
	info.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = skill.display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d / %d" % [cur_level, skill.max_level]
	lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	name_row.add_child(lv_lbl)

	var meta_lbl := Label.new()
	meta_lbl.text = "MP %d  CD %.1fs  Lv.要求 %d  SP %d" % [int(skill.mp_cost), skill.cooldown, skill.unlock_level, skill.sp_cost]
	meta_lbl.add_theme_font_size_override("font_size", 10)
	meta_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	info.add_child(meta_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = skill.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.65))
	info.add_child(desc_lbl)

	# 按钮列：学习 + 装配 Q/E/R/G
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	hbox.add_child(actions)

	var learn_btn := Button.new()
	learn_btn.custom_minimum_size = Vector2(96, 24)
	if cur_level >= skill.max_level:
		learn_btn.text = "已满级"
		learn_btn.disabled = true
	elif not act.can_learn(skill):
		learn_btn.text = "学习 (-%d SP)" % skill.sp_cost
		learn_btn.disabled = true
	else:
		learn_btn.text = "学习 (-%d SP)" % skill.sp_cost
		learn_btn.pressed.connect(func(): PlayerActions.request_learn_skill(skill.id))
	actions.add_child(learn_btn)

	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 2)
	actions.add_child(equip_row)
	for slot_i in range(1, 5):  # 槽 1-4 = Q/E/R/G（槽 0 = J 固定为 basic_swing）
		var sb_btn := Button.new()
		sb_btn.text = SLOT_KEYS[slot_i]
		sb_btn.custom_minimum_size = Vector2(22, 22)
		var is_equipped: bool = _player.equipped_skills[slot_i] == skill.id
		sb_btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if is_equipped else Color(0.7, 0.7, 0.7))
		var captured_slot := slot_i
		var captured_id := skill.id
		sb_btn.pressed.connect(func(): _on_equip_clicked(captured_slot, captured_id, is_equipped))
		if not act.is_learned(skill.id):
			sb_btn.disabled = true
		equip_row.add_child(sb_btn)

	return row

func _on_equip_clicked(slot: int, skill_id: String, was_equipped: bool) -> void:
	# 已装则卸下，未装则装入
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
