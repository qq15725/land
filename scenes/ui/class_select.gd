extends PanelContainer

# 职业选择面板。
# 出现时机：world._setup_ui_layer 时若玩家 class_id 为空则自动 show；
# 也可由技能树"切换职业"按钮手动打开。

var _grid: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	# 半透明背景
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", sb)
	_build_layout()

func _build_layout() -> void:
	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "选择你的职业"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "选择后将影响 HP / MP 上限与可学习的技能。可以稍后在技能面板（K）中切换。"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	_grid = HBoxContainer.new()
	_grid.add_theme_constant_override("separation", 12)
	_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_grid)

	# 关闭按钮
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom)
	var skip_btn := Button.new()
	skip_btn.text = "稍后再选"
	skip_btn.pressed.connect(hide)
	bottom.add_child(skip_btn)

	_refresh_classes()

func _refresh_classes() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for cls in ItemDatabase.get_all_classes():
		_grid.add_child(_make_card(cls as ClassData))

func _make_card(cls: ClassData) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.4, 0.4, 0.45)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var inner_margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner_margin.add_theme_constant_override(s, 10)
	card.add_child(inner_margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	inner_margin.add_child(content)

	# 图标
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(72, 72)
	icon_rect.texture = ItemDatabase.get_icon_at_grid(cls.icon_grid)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon_rect)

	var name_lbl := Label.new()
	name_lbl.text = cls.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	content.add_child(name_lbl)

	var stats_lbl := Label.new()
	stats_lbl.text = "HP %+d  MP %+d  回蓝 %+.1f/s" % [int(cls.hp_bonus), int(cls.mp_bonus), cls.mp_regen_bonus]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 10)
	stats_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	content.add_child(stats_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = cls.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(desc_lbl)

	var choose_btn := Button.new()
	choose_btn.text = "选择"
	var captured_id := cls.id
	choose_btn.pressed.connect(func(): _on_choose(captured_id))
	content.add_child(choose_btn)

	return card

func _on_choose(class_id: String) -> void:
	PlayerActions.request_set_class(class_id)
	hide()
