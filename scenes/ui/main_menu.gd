extends Control

const WorldScene := preload("res://scenes/world/world.tscn")

# 配色
const C_BG       := Color(0.07, 0.06, 0.04)
const C_BG_LEFT  := Color(0.05, 0.09, 0.05)
const C_TITLE    := Color(0.95, 0.90, 0.70)
const C_SUB      := Color(0.60, 0.75, 0.50)
const C_VER      := Color(0.40, 0.40, 0.35)
const C_LABEL    := Color(0.70, 0.65, 0.50)

var _update_btn: Button = null
var _new_game_panel: Control = null
var _update_dialog: Control = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.theme
	_build_layout()
	UpdateSystem.update_available.connect(_on_update_available)

func _build_layout() -> void:
	# 整体深色背景
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 左侧装饰色带
	var left_strip := ColorRect.new()
	left_strip.color = C_BG_LEFT
	left_strip.anchor_right = 0.38
	left_strip.anchor_bottom = 1.0
	add_child(left_strip)

	# 主布局：左右分栏
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	hbox.add_child(_build_left_panel())
	hbox.add_child(_build_right_panel())

	# 右下角版本号
	var ver := Label.new()
	ver.text = GameManager.VERSION
	ver.add_theme_font_size_override("font_size", 11)
	ver.modulate = C_VER
	ver.anchor_left = 1.0
	ver.anchor_top = 1.0
	ver.anchor_right = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -80
	ver.offset_top = -28
	add_child(ver)


func _build_left_panel() -> Control:
	var left := MarginContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.38
	left.add_theme_constant_override("margin_left", 48)
	left.add_theme_constant_override("margin_right", 32)
	left.add_theme_constant_override("margin_top", 0)
	left.add_theme_constant_override("margin_bottom", 0)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	left.add_child(vbox)

	# 游戏标题
	var title := Label.new()
	title.text = "Land"
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = C_TITLE
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "休闲生存经营"
	sub.add_theme_font_size_override("font_size", 16)
	sub.modulate = C_SUB
	vbox.add_child(sub)

	# 间距
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(spacer)

	# 特性标签
	for line in ["· 采集 · 建造 · 种菜", "· 养殖 · 交易 · 探索"]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = C_LABEL
		vbox.add_child(lbl)

	return left


func _build_right_panel() -> Control:
	var right := MarginContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.62
	right.add_theme_constant_override("margin_left", 48)
	right.add_theme_constant_override("margin_right", 64)
	right.add_theme_constant_override("margin_top", 0)
	right.add_theme_constant_override("margin_bottom", 0)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	right.add_child(vbox)

	# 存档区标题
	var save_lbl := Label.new()
	save_lbl.text = "选择存档"
	save_lbl.add_theme_font_size_override("font_size", 14)
	save_lbl.modulate = C_LABEL
	vbox.add_child(save_lbl)

	# 存档槽列表
	var slots_panel := PanelContainer.new()
	vbox.add_child(slots_panel)

	var slots_margin := MarginContainer.new()
	slots_margin.add_theme_constant_override("margin_left", 12)
	slots_margin.add_theme_constant_override("margin_right", 12)
	slots_margin.add_theme_constant_override("margin_top", 12)
	slots_margin.add_theme_constant_override("margin_bottom", 12)
	slots_panel.add_child(slots_margin)

	var slots_vbox := VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 8)
	slots_margin.add_child(slots_vbox)

	for i in SaveSystem.MAX_SLOTS:
		slots_vbox.add_child(_make_slot_button(i))

	# 底部工具按钮行
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_update_btn = Button.new()
	_update_btn.text = "检查更新"
	_update_btn.custom_minimum_size = Vector2(130, 36)
	_update_btn.pressed.connect(_on_check_update_pressed)
	btn_row.add_child(_update_btn)

	var quit_btn := Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(130, 36)
	quit_btn.pressed.connect(func(): get_tree().quit())
	btn_row.add_child(quit_btn)

	return right


func _make_slot_button(slot: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if SaveSystem.slot_exists(slot):
		var info := SaveSystem.get_slot_info(slot)
		btn.text = "  存档 %d    第 %d 天  %s" % [
			slot + 1,
			info.get("day", 1),
			"夜晚" if info.get("phase") == "night" else "白天",
		]
		btn.pressed.connect(func(): _start_game(slot))
	else:
		btn.text = "  存档 %d    （空档位）" % (slot + 1)
		btn.pressed.connect(func(): _show_new_game_panel(slot))
	return btn


func _on_check_update_pressed() -> void:
	_update_btn.text = "检查中..."
	_update_btn.disabled = true
	UpdateSystem.update_available.disconnect(_on_update_available)
	UpdateSystem.update_available.connect(func(version, changelog):
		_update_btn.text = "检查更新"
		_update_btn.disabled = false
		_on_update_available(version, changelog)
	, CONNECT_ONE_SHOT)
	get_tree().create_timer(8.0).timeout.connect(func():
		if _update_btn and _update_btn.disabled:
			_update_btn.text = "已是最新版本"
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
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
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
