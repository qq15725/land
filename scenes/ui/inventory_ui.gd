extends DraggablePanel

var _inventory: InventoryComponent
var _grid: GridContainer

func _ready() -> void:
	custom_minimum_size = Vector2(290, 340)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -145
	offset_right = 145
	offset_top = -170
	offset_bottom = 170
	visible = false
	_build_layout()

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "背包"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)

func setup(inventory: InventoryComponent) -> void:
	_inventory = inventory
	_inventory.changed.connect(_refresh)
	_inventory.selection_changed.connect(func(_i): _refresh())
	_refresh()

func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for i in _inventory.slots.size():
		_grid.add_child(_make_slot(i))

func _make_slot(index: int) -> Control:
	var slot: Dictionary = _inventory.slots[index]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(48, 48)
	btn.flat = true

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	if slot.item != null:
		style.bg_color = slot.item.color
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	if index == _inventory.selected_slot:
		style.border_color = Color.WHITE
		style.set_border_width_all(2)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	if slot.item != null:
		var lbl := Label.new()
		lbl.text = "x%d" % slot.amount if slot.amount > 1 else ""
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

	btn.pressed.connect(func(): _inventory.select_slot(index))
	return btn

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = not visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
