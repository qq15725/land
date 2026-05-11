extends Control

const WorldScene := preload("res://scenes/world/world.tscn")

const C_DELETE  := Color(0.65, 0.12, 0.10)
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
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/ui/main_menu_bg.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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

	# 标题图：384×128，以 3:1 比例缩放到合理大小
	var title := TextureRect.new()
	title.texture = load("res://assets/sprites/ui/title_land.png")
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.custom_minimum_size = Vector2(220, 74)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "休闲生存经营"
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = C_SUB
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)

	# menu_icons.png：128×32，4 个 32×32 图标（叶片/齿轮/箱子/垃圾桶）
	var icon_sheet := load("res://assets/sprites/ui/menu_icons.png") as Texture2D
	var feature_entries: Array = [
		[Rect2(0, 0, 32, 32),  "采集・建造・种菜"],
		[Rect2(64, 0, 32, 32), "养殖・交易・探索"],
	]
	for entry in feature_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var atlas := AtlasTexture.new()
		atlas.atlas = icon_sheet
		atlas.region = entry[0] as Rect2

		var icon := TextureRect.new()
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(22, 22)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = entry[1] as String
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

	# panel_wood.png：192×192，木框边约 18px
	var panel := PanelContainer.new()
	var ps := StyleBoxTexture.new()
	ps.texture = load("res://assets/sprites/ui/panel_wood.png")
	ps.texture_margin_left   = 18
	ps.texture_margin_right  = 18
	ps.texture_margin_top    = 18
	ps.texture_margin_bottom = 18
	ps.content_margin_left   = 20
	ps.content_margin_right  = 20
	ps.content_margin_top    = 14
	ps.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", ps)
	wrapper.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	# 顶部叶片装饰
	var header := CenterContainer.new()
	header.custom_minimum_size = Vector2(0, 4)
	inner.add_child(header)
	var emblem_atlas := AtlasTexture.new()
	emblem_atlas.atlas = load("res://assets/sprites/ui/menu_icons.png")
	emblem_atlas.region = Rect2(0, 0, 32, 32)
	var emblem := TextureRect.new()
	emblem.texture = emblem_atlas
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.custom_minimum_size = Vector2(24, 24)
	header.add_child(emblem)

	_slots_vbox = VBoxContainer.new()
	_slots_vbox.add_theme_constant_override("separation", 8)
	inner.add_child(_slots_vbox)
	_refresh_slots()

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	inner.add_child(sp)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	inner.add_child(btn_row)

	_update_btn = _make_action_btn("⚙  检查更新", "res://assets/sprites/ui/btn_green.png")
	_update_btn.pressed.connect(_on_check_update_pressed)
	btn_row.add_child(_update_btn)

	var quit_btn := _make_action_btn("⮐  退出游戏", "res://assets/sprites/ui/btn_brown.png")
	quit_btn.pressed.connect(func(): get_tree().quit())
	btn_row.add_child(quit_btn)

	return wrapper


# tex_path 指向 192×144 三状态竖排精灵表（normal/hover/pressed，各 48px 高）
func _make_action_btn(txt: String, tex_path: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(148, 42)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sheet := load(tex_path) as Texture2D
	var state_regions := {
		"normal":  Rect2(0, 0,  192, 48),
		"hover":   Rect2(0, 48, 192, 48),
		"pressed": Rect2(0, 96, 192, 48),
		"focus":   Rect2(0, 0,  192, 48),
	}
	for state in ["normal", "hover", "pressed", "focus"]:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = state_regions[state]
		var s := StyleBoxTexture.new()
		s.texture = atlas
		s.texture_margin_left   = 12
		s.texture_margin_right  = 12
		s.texture_margin_top    = 10
		s.texture_margin_bottom = 10
		s.content_margin_left   = 14
		s.content_margin_right  = 14
		s.content_margin_top    = 8
		s.content_margin_bottom = 8
		btn.add_theme_stylebox_override(state, s)
	return btn


func _refresh_slots() -> void:
	for child in _slots_vbox.get_children():
		child.queue_free()
	for i in SaveSystem.MAX_SLOTS:
		_slots_vbox.add_child(_make_slot_row(i))


# slot_frame.png：192×80，四周木框约 8px
func _make_slot_row(slot: int) -> Button:
	var frame := Button.new()
	frame.custom_minimum_size = Vector2(0, 76)
	frame.alignment = HORIZONTAL_ALIGNMENT_LEFT
	frame.focus_mode = Control.FOCUS_NONE

	var slot_tex := load("res://assets/sprites/ui/slot_frame.png") as Texture2D
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxTexture.new()
		s.texture = slot_tex
		s.texture_margin_left   = 8
		s.texture_margin_right  = 8
		s.texture_margin_top    = 8
		s.texture_margin_bottom = 8
		s.content_margin_left   = 10
		s.content_margin_right  = 10
		s.content_margin_top    = 8
		s.content_margin_bottom = 8
		if state in ["hover", "pressed"]:
			s.modulate_color = Color(1.12, 1.12, 1.12)
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

		var thumb := TextureRect.new()
		thumb.texture = load("res://assets/sprites/ui/save_thumb_farm.png")
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.custom_minimum_size = Vector2(96, 58)
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(thumb)

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

		var del_btn := Button.new()
		del_btn.icon = load("res://assets/sprites/ui/icon_trash.png")
		del_btn.custom_minimum_size = Vector2(36, 36)
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
		var thumb := TextureRect.new()
		thumb.texture = load("res://assets/sprites/ui/save_thumb_empty.png")
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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
		del_btn.icon = null
		del_btn.text = "?"
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(del_btn):
				del_btn.remove_meta("confirming")
				del_btn.icon = load("res://assets/sprites/ui/icon_trash.png")
				del_btn.text = ""
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
