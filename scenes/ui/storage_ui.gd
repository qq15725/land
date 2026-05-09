extends DraggablePanel

var _player_inventory: InventoryComponent
var _storage_inventory: InventoryComponent
var _storage_grid: GridContainer
var _player_grid: GridContainer

func _ready() -> void:
	custom_minimum_size = Vector2(320, 480)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	EventBus.open_storage.connect(_on_open_storage)

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
	title.text = "储物箱"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var chest_lbl := Label.new()
	chest_lbl.text = "箱子内容（点击取出）"
	chest_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(chest_lbl)

	_storage_grid = GridContainer.new()
	_storage_grid.columns = 5
	_storage_grid.add_theme_constant_override("h_separation", 4)
	_storage_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_storage_grid)

	vbox.add_child(HSeparator.new())

	var player_lbl := Label.new()
	player_lbl.text = "我的背包（点击存入）"
	player_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(player_lbl)

	_player_grid = GridContainer.new()
	_player_grid.columns = 5
	_player_grid.add_theme_constant_override("h_separation", 4)
	_player_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_player_grid)

func setup(player_inventory: InventoryComponent) -> void:
	_player_inventory = player_inventory

func _on_open_storage(storage: InventoryComponent) -> void:
	if _storage_inventory != null and _storage_inventory.changed.is_connected(_refresh):
		_storage_inventory.changed.disconnect(_refresh)
	_storage_inventory = storage
	_storage_inventory.changed.connect(_refresh)
	_refresh()
	show()

func _refresh() -> void:
	_fill_grid(_storage_grid, _storage_inventory, true)
	_fill_grid(_player_grid, _player_inventory, false)

func _fill_grid(grid: GridContainer, inventory: InventoryComponent, is_storage: bool) -> void:
	for child in grid.get_children():
		child.queue_free()
	for i in inventory.slots.size():
		var slot: Dictionary = inventory.slots[i]
		grid.add_child(_make_slot_btn(slot, inventory, is_storage))

func _make_slot_btn(slot: Dictionary, source: InventoryComponent, from_storage: bool) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(46, 46)
	btn.flat = true

	if slot.item != null:
		var style := StyleBoxFlat.new()
		style.bg_color = slot.item.color
		style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)

		var lbl := Label.new()
		lbl.text = "x%d" % slot.amount if slot.amount > 1 else ""
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

		var item: ItemResource = slot.item
		var amount: int = slot.amount
		if from_storage:
			btn.pressed.connect(func(): _transfer(item, amount, _storage_inventory, _player_inventory))
		else:
			btn.pressed.connect(func(): _transfer(item, amount, _player_inventory, _storage_inventory))
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", style)

	return btn

func _transfer(item: ItemResource, amount: int, from: InventoryComponent, to: InventoryComponent) -> void:
	var leftover := to.add_item(item, amount)
	var transferred := amount - leftover
	if transferred > 0:
		from.remove_item(item, transferred)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
