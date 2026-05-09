extends Control

signal resumed
signal saved_and_quit

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_layout()

func _build_layout() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.theme = UIStyle.theme
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(220, 0)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "暂停"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var resume_btn := Button.new()
	resume_btn.text = "继续游戏"
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	var save_btn := Button.new()
	save_btn.text = "保存游戏"
	save_btn.pressed.connect(_on_save)
	vbox.add_child(save_btn)

	var quit_btn := Button.new()
	quit_btn.text = "保存并退出"
	quit_btn.pressed.connect(_on_save_quit)
	vbox.add_child(quit_btn)

func open() -> void:
	visible = true
	get_tree().paused = true

func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()

func _on_save() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world:
		SaveSystem.save(GameManager.current_save_slot, world)

func _on_save_quit() -> void:
	var world := get_tree().get_first_node_in_group("world")
	if world:
		SaveSystem.save(GameManager.current_save_slot, world)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_resume()
		get_viewport().set_input_as_handled()
