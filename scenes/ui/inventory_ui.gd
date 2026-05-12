extends DraggablePanel

const EQUIP_SLOTS: Array[Dictionary] = [
	{"type": "weapon",    "label": "武器"},
	{"type": "armor",     "label": "护甲"},
	{"type": "accessory", "label": "饰品"},
]

var _inventory: InventoryComponent
var _grid: GridContainer
var _equip_row: HBoxContainer

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(320, 420)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -160
	offset_right = 160
	offset_top = -210
	offset_bottom = 210
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
	vbox.add_theme_constant_override("separation", 8)
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

	# 装备槽行
	var equip_label := Label.new()
	equip_label.text = "装备"
	equip_label.add_theme_font_size_override("font_size", 11)
	equip_label.modulate = Color(0.78, 0.78, 0.78)
	vbox.add_child(equip_label)

	_equip_row = HBoxContainer.new()
	_equip_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_equip_row)

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
	_inventory.equipment_changed.connect(func(_t): _refresh())
	_refresh()

func _refresh() -> void:
	_refresh_equip_row()
	_refresh_grid()

func _refresh_equip_row() -> void:
	for child in _equip_row.get_children():
		child.queue_free()
	for slot_def in EQUIP_SLOTS:
		_equip_row.add_child(_make_equip_slot(slot_def["type"], slot_def["label"]))

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for i in _inventory.slots.size():
		_grid.add_child(_make_slot(i))

func _make_equip_slot(slot_type: String, label: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.modulate = Color(0.75, 0.75, 0.75)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	var icon := ItemIcon.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var equipped := _inventory.get_equipped(slot_type)
	if equipped:
		icon.show_item(equipped, 1)
	btn.add_child(icon)

	btn.pressed.connect(func(): _inventory.unequip(slot_type))
	box.add_child(btn)
	return box

func _make_slot(index: int) -> Control:
	var slot: Dictionary = _inventory.slots[index]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	var icon := ItemIcon.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_selected(index == _inventory.selected_slot)
	if slot.item != null:
		icon.show_item(slot.item, slot.amount)
	btn.add_child(icon)

	btn.pressed.connect(func(): _on_slot_clicked(index))
	return btn

# 点击背包格：装备物品直接装备，非装备物品做选中
func _on_slot_clicked(index: int) -> void:
	var item: ItemData = _inventory.slots[index].item
	if item and not item.equip_slot.is_empty():
		_inventory.equip_from_slot(index)
	else:
		_inventory.select_slot(index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = not visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
