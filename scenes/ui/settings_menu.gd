class_name SettingsMenu
extends Control

# 全局设置面板。挂在 CanvasLayer 上，主菜单/暂停菜单都用同一个实例。
# 调用 open() 弹出，关闭后自动 hide。所有改动通过 SoundSystem 持久化。

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_layout()

func _build_layout() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.theme = UIStyle.theme
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	_add_slider(vbox, "主音量", SoundSystem.master_volume, func(v): SoundSystem.set_master_volume(v))
	_add_slider(vbox, "音效音量", SoundSystem.sfx_volume, func(v): SoundSystem.set_sfx_volume(v))
	_add_slider(vbox, "音乐音量", SoundSystem.bgm_volume, func(v): SoundSystem.set_bgm_volume(v))

	vbox.add_child(HSeparator.new())

	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 12)
	vbox.add_child(fs_row)
	var fs_label := Label.new()
	fs_label.text = "全屏"
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_row.add_child(fs_label)
	var fs_check := CheckBox.new()
	fs_check.button_pressed = SoundSystem.fullscreen
	fs_check.toggled.connect(func(p): SoundSystem.set_fullscreen(p))
	fs_row.add_child(fs_check)

	vbox.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)

func _add_slider(vbox: VBoxContainer, label_text: String, init: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = init
	slider.custom_minimum_size = Vector2(180, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % int(init * 100.0)
	value_lbl.custom_minimum_size = Vector2(48, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_lbl)

	slider.value_changed.connect(func(v: float):
		value_lbl.text = "%d%%" % int(v * 100.0)
		on_change.call(v)
	)

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close()
		get_viewport().set_input_as_handled()
