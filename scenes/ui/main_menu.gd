extends Control

const WorldScene := preload("res://scenes/world/world.tscn")

# ── 占位颜色（贴图到位后替换各 _build_* 函数里对应的 ColorRect / StyleBoxFlat）──
const C_BG         := Color(0.12, 0.17, 0.09)
const C_PANEL      := Color(0.30, 0.19, 0.09)
const C_PANEL_BDR  := Color(0.52, 0.34, 0.14)
const C_SLOT_BG    := Color(0.22, 0.14, 0.07)
const C_SLOT_HOVER := Color(0.30, 0.20, 0.10)
const C_SLOT_BDR   := Color(0.48, 0.30, 0.13)
const C_THUMB_OK   := Color(0.16, 0.28, 0.12)
const C_THUMB_EMPTY := Color(0.18, 0.15, 0.12)
const C_BTN_GREEN  := Color(0.26, 0.50, 0.21)
const C_BTN_BROWN  := Color(0.40, 0.25, 0.10)
const C_DELETE     := Color(0.65, 0.12, 0.10)

# ── 文字颜色 ─────────────────────────────────────────────────────────────────
const C_TITLE   := Color(0.96, 0.77, 0.28)
const C_SUB     := Color(0.84, 0.78, 0.62)
const C_FEATURE := Color(0.76, 0.70, 0.54)
const C_SLOT_H  := Color(0.95, 0.90, 0.74)
const C_SLOT_S  := Color(0.70, 0.64, 0.48)
const C_EMPTY   := Color(0.52, 0.48, 0.40)
const C_VER     := Color(0.48, 0.44, 0.36)

var _update_btn: Button = null
var _new_game_panel: Control = null
var _update_dialog: Control = null
var _slots_vbox: VBoxContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.theme
	_build_layout()
	UpdateSystem.update_available.connect(_on_update_available)


func _build_layout() -> void:
	# 背景
	# TODO: 替换为 TextureRect，texture = load("res://assets/sprites/ui/main_menu_bg.png")
	#       stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 主布局（留外边距）
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left",   64)
	root.add_theme_constant_override("margin_right",  64)
	root.add_theme_constant_override("margin_top",    40)
	root.add_theme_constant_override("margin_bottom", 40)
	add_child(root)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	root.add_child(hbox)
	hbox.add_child(_build_left())
	hbox.add_child(_build_right())

	# 右下角版本号
	var ver := Label.new()
	ver.text = GameManager.VERSION
	ver.add_theme_font_size_override("font_size", 11)
	ver.modulate = C_VER
	ver.anchor_left   = 1.0
	ver.anchor_top    = 1.0
	ver.anchor_right  = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left   = -80
	ver.offset_top    = -28
	add_child(ver)


func _build_left() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_stretch_ratio = 0.42
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)

	# "Land" Logo
	# TODO: 替换为 TextureRect，texture = load("res://assets/sprites/ui/title_land.png")
	#       custom_minimum_size = Vector2(320, 100)，expand_mode = EXPAND_FIT_WIDTH
	var title := Label.new()
	title.text = "Land"
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = C_TITLE
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "休闲生存经营"
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = C_SUB
	vbox.add_child(sub)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)

	for line in ["采集・建造・种菜", "养殖・交易・探索"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# 叶片图标占位
		# TODO: 替换为 TextureRect，region = Rect2(0, 0, 32, 32)，
		#       texture = load("res://assets/sprites/ui/menu_icons.png")
		var leaf := ColorRect.new()
		leaf.color = Color(0.28, 0.62, 0.20)
		leaf.custom_minimum_size = Vector2(16, 16)
		leaf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(leaf)

		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = C_FEATURE
		row.add_child(lbl)

		vbox.add_child(row)

	return vbox


func _build_right() -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_stretch_ratio = 0.58
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER

	# 木质面板
	# TODO: 换成 StyleBoxTexture，texture = load("res://assets/sprites/ui/panel_wood.png")
	#       margin_all = 32，draw_center = true
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL
	ps.border_color = C_PANEL_BDR
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(4)
	ps.content_margin_left   = 20
	ps.content_margin_right  = 20
	ps.content_margin_top    = 20
	ps.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", ps)
	wrapper.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	_slots_vbox = VBoxContainer.new()
	_slots_vbox.add_theme_constant_override("separation", 8)
	inner.add_child(_slots_vbox)
	_refresh_slots()

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	inner.add_child(sp)

	# 底部按钮行
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	inner.add_child(btn_row)

	# TODO: 按钮贴图到位后换成 StyleBoxTexture(btn_green/brown.png)，margin = 16
	_update_btn = _make_action_btn("⚙  检查更新", C_BTN_GREEN)
	_update_btn.pressed.connect(_on_check_update_pressed)
	btn_row.add_child(_update_btn)

	var quit_btn := _make_action_btn("⮐  退出游戏", C_BTN_BROWN)
	quit_btn.pressed.connect(func(): get_tree().quit())
	btn_row.add_child(quit_btn)

	return wrapper


func _make_action_btn(txt: String, base: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(148, 42)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color.WHITE)
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		match state:
			"hover":   s.bg_color = base.lightened(0.18)
			"pressed": s.bg_color = base.darkened(0.18)
			_:         s.bg_color = base
		s.border_color = base.lightened(0.30)
		s.set_border_width_all(2)
		s.set_corner_radius_all(3)
		s.content_margin_left  = 14
		s.content_margin_right = 14
		btn.add_theme_stylebox_override(state, s)
	return btn


func _refresh_slots() -> void:
	for child in _slots_vbox.get_children():
		child.queue_free()
	for i in SaveSystem.MAX_SLOTS:
		_slots_vbox.add_child(_make_slot_row(i))


func _make_slot_row(slot: int) -> Button:
	var frame := Button.new()
	frame.custom_minimum_size = Vector2(0, 76)
	frame.alignment = HORIZONTAL_ALIGNMENT_LEFT
	frame.focus_mode = Control.FOCUS_NONE

	# 槽框样式
	# TODO: 换成 StyleBoxTexture(slot_frame.png，margin_all = 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = C_SLOT_BG if state == "normal" else C_SLOT_HOVER
		s.border_color = C_SLOT_BDR
		s.set_border_width_all(2)
		s.set_corner_radius_all(3)
		s.content_margin_left   = 10
		s.content_margin_right  = 10
		s.content_margin_top    = 8
		s.content_margin_bottom = 8
		frame.add_theme_stylebox_override(state, s)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(row)

	if SaveSystem.slot_exists(slot):
		var info   := SaveSystem.get_slot_info(slot)
		var day    : int    = info.get("day", 1)
		var phase  : String = info.get("phase", "day")
		var season : String = info.get("season", "春季")
		var money  : int    = info.get("money", 0)

		# 缩略图占位
		# TODO: 换成 TextureRect，texture = load("res://assets/sprites/ui/save_thumb_farm.png")
		var thumb := ColorRect.new()
		thumb.color = C_THUMB_OK
		thumb.custom_minimum_size = Vector2(96, 58)
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(thumb)

		# 文字区
		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.alignment = BoxContainer.ALIGNMENT_CENTER
		info_box.add_theme_constant_override("separation", 4)
		info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(info_box)

		var h_lbl := Label.new()
		h_lbl.text = "存档 %d    第 %d 天  %s" % [slot + 1, day, "夜晚" if phase == "night" else "白天"]
		h_lbl.add_theme_font_size_override("font_size", 14)
		h_lbl.modulate = C_SLOT_H
		h_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(h_lbl)

		var s_lbl := Label.new()
		s_lbl.text = "%s・家园等级 1・资金 %d" % [season, money]
		s_lbl.add_theme_font_size_override("font_size", 11)
		s_lbl.modulate = C_SLOT_S
		s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_box.add_child(s_lbl)

		# 删除按钮
		# TODO: 换成 TextureButton，texture_normal = icon_trash.png 32×32 区域
		var del_btn := Button.new()
		del_btn.custom_minimum_size = Vector2(36, 36)
		del_btn.text = "🗑"
		del_btn.add_theme_font_size_override("font_size", 16)
		del_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		del_btn.add_theme_color_override("font_color", Color.WHITE)
		var ds := StyleBoxFlat.new()
		ds.bg_color = C_DELETE
		ds.border_color = C_DELETE.lightened(0.25)
		ds.set_border_width_all(1)
		ds.set_corner_radius_all(3)
		ds.content_margin_left  = 4
		ds.content_margin_right = 4
		del_btn.add_theme_stylebox_override("normal", ds)
		var ds_h := ds.duplicate() as StyleBoxFlat
		ds_h.bg_color = C_DELETE.lightened(0.15)
		del_btn.add_theme_stylebox_override("hover", ds_h)
		del_btn.pressed.connect(func(): _on_delete_pressed(del_btn, slot))
		row.add_child(del_btn)

		frame.pressed.connect(func(): _start_game(slot))

	else:
		# 空档位缩略图占位
		# TODO: 换成 TextureRect，texture = load("res://assets/sprites/ui/save_thumb_empty.png")
		var thumb := ColorRect.new()
		thumb.color = C_THUMB_EMPTY
		thumb.custom_minimum_size = Vector2(96, 58)
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(thumb)

		var empty_lbl := Label.new()
		empty_lbl.text = "存档 %d    （空档位）" % (slot + 1)
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.modulate = C_EMPTY
		empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(empty_lbl)

		frame.pressed.connect(func(): _show_new_game_panel(slot))

	return frame


func _on_delete_pressed(del_btn: Button, slot: int) -> void:
	if del_btn.get_meta("confirming", false):
		SaveSystem.delete_slot(slot)
		_refresh_slots()
	else:
		del_btn.set_meta("confirming", true)
		del_btn.text = "?"
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(del_btn):
				del_btn.remove_meta("confirming")
				del_btn.text = "🗑"
		, CONNECT_ONE_SHOT)


func _on_check_update_pressed() -> void:
	_update_btn.text = "检查中..."
	_update_btn.disabled = true
	UpdateSystem.update_available.disconnect(_on_update_available)
	UpdateSystem.update_available.connect(func(version, changelog):
		_update_btn.text = "⚙  检查更新"
		_update_btn.disabled = false
		_on_update_available(version, changelog)
	, CONNECT_ONE_SHOT)
	get_tree().create_timer(8.0).timeout.connect(func():
		if _update_btn and _update_btn.disabled:
			_update_btn.text = "✓  已是最新"
			_update_btn.disabled = false
	, CONNECT_ONE_SHOT)
	UpdateSystem.check()


func _show_new_game_panel(slot: int) -> void:
	if _new_game_panel:
		_new_game_panel.queue_free()

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_new_game_panel = overlay

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   40)
	margin.add_theme_constant_override("margin_right",  40)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "新建游戏 — 存档 %d" % (slot + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var random_btn := Button.new()
	random_btn.text = "随机世界\n每次不同的程序化地图"
	random_btn.custom_minimum_size = Vector2(300, 60)
	random_btn.pressed.connect(func():
		GameManager.world_type = "random"
		_close_new_game_panel()
		_start_game(slot)
	)
	vbox.add_child(random_btn)

	var preset_btn := Button.new()
	preset_btn.text = "固定地图\n使用预设设计图（0.png）"
	preset_btn.custom_minimum_size = Vector2(300, 60)
	preset_btn.pressed.connect(func():
		GameManager.world_type = "preset"
		_close_new_game_panel()
		_start_game(slot)
	)
	vbox.add_child(preset_btn)

	vbox.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.pressed.connect(_close_new_game_panel)
	vbox.add_child(back_btn)


func _close_new_game_panel() -> void:
	if _new_game_panel:
		_new_game_panel.queue_free()
		_new_game_panel = null


func _on_update_available(version: String, changelog: String) -> void:
	if _update_dialog == null:
		_update_dialog = load("res://scenes/ui/update_dialog.gd").new()
		add_child(_update_dialog)
	_update_dialog.show_update(version, changelog)


func _start_game(slot: int) -> void:
	GameManager.current_save_slot = slot
	get_tree().change_scene_to_packed(WorldScene)
