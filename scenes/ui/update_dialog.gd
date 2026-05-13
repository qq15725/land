extends PanelContainer

var _version_lbl: Label
var _changelog_lbl: Label
var _progress_bar: ProgressBar
var _status_lbl: Label
var _update_btn: Button
var _cancel_btn: Button

func _ready() -> void:
	custom_minimum_size = Vector2(400, 300)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	z_index = ZLayer.UI_DIALOG
	_build_layout()
	UpdateSystem.download_progress.connect(_on_progress)
	UpdateSystem.download_complete.connect(_on_complete)
	UpdateSystem.update_error.connect(_on_error)


func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var icon_lbl := Label.new()
	icon_lbl.text = "★"
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(icon_lbl)

	var title := Label.new()
	title.text = "  发现新版本"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_version_lbl = Label.new()
	_version_lbl.add_theme_font_size_override("font_size", 13)
	_version_lbl.modulate = Color(0.6, 0.9, 0.6)
	vbox.add_child(_version_lbl)

	vbox.add_child(HSeparator.new())

	var changelog_title := Label.new()
	changelog_title.text = "更新内容"
	changelog_title.add_theme_font_size_override("font_size", 12)
	changelog_title.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(changelog_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 100)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_changelog_lbl = Label.new()
	_changelog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_changelog_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_changelog_lbl.add_theme_font_size_override("font_size", 12)
	scroll.add_child(_changelog_lbl)

	_progress_bar = ProgressBar.new()
	_progress_bar.visible = false
	_progress_bar.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(_progress_bar)

	_status_lbl = Label.new()
	_status_lbl.visible = false
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_lbl)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(buttons)

	_cancel_btn = Button.new()
	_cancel_btn.text = "稍后再说"
	_cancel_btn.pressed.connect(hide)
	buttons.add_child(_cancel_btn)

	_update_btn = Button.new()
	_update_btn.text = "立即更新"
	_update_btn.pressed.connect(_on_update_pressed)
	buttons.add_child(_update_btn)


func show_update(version: String, changelog: String) -> void:
	_version_lbl.text = "%s  →  %s" % [GameManager.VERSION, version]
	_changelog_lbl.text = changelog if changelog != "" else "暂无更新说明"
	_progress_bar.visible = false
	_status_lbl.visible = false
	_update_btn.disabled = false
	_update_btn.text = "立即更新"
	_cancel_btn.disabled = false
	show()


func _on_update_pressed() -> void:
	_update_btn.disabled = true
	_cancel_btn.disabled = true
	var platform := OS.get_name()
	if platform == "Windows":
		_progress_bar.value = 0
		_progress_bar.visible = true
		_status_lbl.text = "正在下载..."
		_status_lbl.visible = true
	else:
		_status_lbl.text = "正在跳转到下载页面..."
		_status_lbl.visible = true
	UpdateSystem.apply_update()


func _on_progress(downloaded: int, total: int) -> void:
	if total > 0:
		_progress_bar.value = float(downloaded) / float(total) * 100.0
		_status_lbl.text = "正在下载... %d / %d MB" % [downloaded / 1048576, total / 1048576]
	else:
		_status_lbl.text = "正在下载... %d MB" % [downloaded / 1048576]


func _on_complete() -> void:
	_progress_bar.value = 100
	_status_lbl.text = "下载完成，正在重启..."


func _on_error(msg: String) -> void:
	_status_lbl.text = "错误：" + msg
	_status_lbl.modulate = Color(1.0, 0.4, 0.4)
	_update_btn.disabled = false
	_update_btn.text = "重试"
	_cancel_btn.disabled = false
