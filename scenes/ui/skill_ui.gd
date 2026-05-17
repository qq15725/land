extends DraggablePanel

# 技能面板：按 K 键打开。每个技能一行，含图标 + 名字 + 等级 + 经验进度条。

var _list: VBoxContainer

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(320, 320)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	EventBus.skill_leveled_up.connect(func(_id, _lv): if visible: _refresh())

func _build_layout() -> void:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "技能"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	header.add_child(make_close_button())

	vbox.add_child(HSeparator.new())

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	vbox.add_child(_list)

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	for skill in SkillSystem.get_all_skills():
		_list.add_child(_make_row(skill))

func _make_row(skill: SkillData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# 占位图标（借用 items.png 中的一个格子）
	var icon_box := Panel.new()
	icon_box.custom_minimum_size = Vector2(48, 48)
	icon_box.add_theme_stylebox_override("panel", UIStyle.make_slot_style(false))
	var icon_rect := TextureRect.new()
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 6
	icon_rect.offset_right = -6
	icon_rect.offset_top = 6
	icon_rect.offset_bottom = -6
	icon_rect.texture = _make_skill_icon_atlas(skill)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_box.add_child(icon_rect)
	row.add_child(icon_box)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var p: Dictionary = _local_progress(skill.id)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = skill.display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % int(p.get("level", 0))
	lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	name_row.add_child(lv_lbl)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = p.get("ratio", 0.0)
	bar.custom_minimum_size = Vector2(0, 14)
	info.add_child(bar)

	var xp_lbl := Label.new()
	if p.get("max_level", false):
		xp_lbl.text = "已满级"
	else:
		xp_lbl.text = "%d / %d xp" % [int(p.get("into_level", 0)), int(p.get("span", 1))]
	xp_lbl.add_theme_font_size_override("font_size", 10)
	xp_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	info.add_child(xp_lbl)

	return row

# 借用物品图标表展示技能图标（直到有独立的技能图标 sheet）。
func _make_skill_icon_atlas(skill: SkillData) -> Texture2D:
	return ItemDatabase.get_icon_at_grid(skill.icon_grid)

# 取本地玩家的技能进度（G4 后数据下沉到 player.skills 组件）。
func _local_progress(skill_id: String) -> Dictionary:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return {}
	var p := players[0] as Player
	return p.skills.get_progress(skill_id) if p and p.skills else {}

func _unhandled_input(event: InputEvent) -> void:
	# K 键改由 talent_tree.gd 接管。本面板仅在外部（如 talent_tree 内"等级"按钮）显式 show 时显示。
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
