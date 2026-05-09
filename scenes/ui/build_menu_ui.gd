extends DraggablePanel

var _inventory: InventoryComponent
var _list: VBoxContainer

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(280, 360)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "建造"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func setup(inventory: InventoryComponent) -> void:
	_inventory = inventory
	_inventory.changed.connect(func(): if visible: _refresh())

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	for building in BuildingSystem.get_all_buildings():
		_add_building_entry(building)

func _add_building_entry(building: BuildingData) -> void:
	var can_afford := BuildingSystem.can_afford(building, _inventory)

	var row := HBoxContainer.new()
	row.modulate = Color.WHITE if can_afford else Color(0.6, 0.6, 0.6)
	_list.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = building.display_name
	info.add_child(name_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = _format_cost(building.cost)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "放置"
	btn.disabled = not can_afford
	btn.pressed.connect(func(): _on_place(building))
	row.add_child(btn)

	_list.add_child(HSeparator.new())

func _format_cost(cost: Array) -> String:
	var parts: PackedStringArray = []
	for c in cost:
		parts.append("%s ×%d" % [c["item"].display_name, c["amount"]])
	return "消耗：" + ", ".join(parts)

func _on_place(building: BuildingData) -> void:
	hide()
	BuildingSystem.enter_build_mode(building)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		if visible:
			hide()
		else:
			_refresh()
			show()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
