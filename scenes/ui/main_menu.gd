extends Control

const WorldScene := preload("res://scenes/world/world.tscn")

var _update_dialog: Control = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_check_update()

func _check_update() -> void:
	UpdateSystem.update_available.connect(_on_update_available)
	UpdateSystem.check()

func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.18, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Land"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "休闲生存经营"
	sub.add_theme_font_size_override("font_size", 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.8, 0.7)
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	for i in SaveSystem.MAX_SLOTS:
		var btn := _make_slot_button(i)
		vbox.add_child(btn)

	var quit_btn := Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(240, 40)
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)

func _make_slot_button(slot: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 44)
	if SaveSystem.slot_exists(slot):
		var info := SaveSystem.get_slot_info(slot)
		btn.text = "存档 %d  第%d天  %s\n%s" % [
			slot + 1,
			info.get("day", 1),
			"夜晚" if info.get("phase") == "night" else "白天",
			info.get("saved_at", ""),
		]
	else:
		btn.text = "存档 %d  （空）" % (slot + 1)
	btn.pressed.connect(func(): _start_game(slot))
	return btn

func _on_update_available(version: String, changelog: String) -> void:
	if _update_dialog == null:
		_update_dialog = load("res://scenes/ui/update_dialog.gd").new()
		add_child(_update_dialog)
	_update_dialog.show_update(version, changelog)

func _start_game(slot: int) -> void:
	GameManager.current_save_slot = slot
	get_tree().change_scene_to_packed(WorldScene)
