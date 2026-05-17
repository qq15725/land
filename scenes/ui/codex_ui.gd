extends DraggablePanel

# 图鉴 / 成就面板。
# 显示所有成就 + 当前进度 + 奖励，监听 AchievementSystem 信号自动刷新。

var _list: VBoxContainer

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(520, 480)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	AchievementSystem.achievement_unlocked.connect(_on_unlocked)
	AchievementSystem.progress_changed.connect(_on_progress)

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
	title.text = "图鉴 / 成就"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(make_close_button())

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func toggle() -> void:
	if visible:
		hide()
	else:
		_refresh()
		show()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for a in AchievementSystem.get_all():
		_list.add_child(_make_row(a as Dictionary))

func _make_row(ad: Dictionary) -> Control:
	var id: String = ad.get("id", "")
	var unlocked := AchievementSystem.is_unlocked(id)
	var cur := AchievementSystem.current(id)
	var goal: int = int(ad.get("goal", 1))

	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(0, 56)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.20, 0.12, 0.95) if unlocked else Color(0.10, 0.10, 0.12, 0.95)
	sb.border_color = Color(1.0, 0.85, 0.3) if unlocked else Color(0.4, 0.4, 0.4)
	sb.set_border_width_all(1)
	for r in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(r, 4)
	root.add_theme_stylebox_override("panel", sb)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	root.add_child(h)

	# 图标
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(44, 44)
	var g: Array = ad.get("icon_grid", [0, 0])
	icon_rect.texture = ItemDatabase.get_icon_at_grid(Vector2i(int(g[0]), int(g[1])))
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not unlocked:
		icon_rect.modulate = Color(0.4, 0.4, 0.4)
	h.add_child(icon_rect)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)

	var name_row := HBoxContainer.new()
	info.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = ad.get("display_name", "?")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if unlocked:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	name_row.add_child(name_lbl)
	var prog_lbl := Label.new()
	prog_lbl.text = "✓ 已完成" if unlocked else "%d / %d" % [mini(cur, goal), goal]
	prog_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78) if unlocked else Color(0.75, 0.75, 0.75))
	name_row.add_child(prog_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = ad.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.65))
	info.add_child(desc_lbl)

	var reward: int = int(ad.get("reward_gold", 0))
	if reward > 0:
		var rew_lbl := Label.new()
		rew_lbl.text = "奖励：+%d G" % reward
		rew_lbl.add_theme_font_size_override("font_size", 10)
		rew_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		info.add_child(rew_lbl)

	return root

func _on_unlocked(_id: String) -> void:
	if visible:
		_refresh()

func _on_progress(_id: String, _cur: int, _goal: int) -> void:
	if visible:
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
