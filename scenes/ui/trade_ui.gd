extends DraggablePanel

var _player_inventory: InventoryComponent
var _merchant_data: MerchantData
var _trade_list: VBoxContainer
var _title_label: Label

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(360, 420)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	EventBus.open_trade.connect(_on_open_trade)

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

	_title_label = Label.new()
	_title_label.text = "商人"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var hint := Label.new()
	hint.text = "点击交易（需持有所需物品）"
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 280)
	vbox.add_child(scroll)

	_trade_list = VBoxContainer.new()
	_trade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_trade_list)

func setup(_player_inv: InventoryComponent) -> void:
	_player_inventory = _player_inv

func _on_open_trade(merchant: MerchantData, player_inv: InventoryComponent) -> void:
	_merchant_data = merchant
	_player_inventory = player_inv
	_title_label.text = merchant.display_name
	_refresh()
	show()

func _refresh() -> void:
	for child in _trade_list.get_children():
		child.queue_free()
	if not _merchant_data:
		return
	for entry in _merchant_data.trades:
		_trade_list.add_child(_make_trade_row(entry))
		_trade_list.add_child(HSeparator.new())

func _make_trade_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var can_afford := _player_inventory.has_item(entry["give_item"], entry["give_amount"])

	row.add_child(_make_chip(entry["give_item"], entry["give_amount"]))

	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 18)
	row.add_child(arrow)

	row.add_child(_make_chip(entry["receive_item"], entry["receive_amount"]))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var btn := Button.new()
	btn.text = "交换"
	btn.disabled = not can_afford
	btn.pressed.connect(func(): _do_trade(entry))
	row.add_child(btn)

	if not can_afford:
		row.modulate = Color(0.5, 0.5, 0.5)

	return row

func _make_chip(item: ItemData, amount: int) -> Control:
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.show_item(item, amount)
	return icon

func _do_trade(entry: Dictionary) -> void:
	if not _player_inventory.has_item(entry["give_item"], entry["give_amount"]):
		return
	var leftover := _player_inventory.add_item(entry["receive_item"], entry["receive_amount"])
	if leftover > 0:
		return
	_player_inventory.remove_item(entry["give_item"], entry["give_amount"])
	EventBus.trade_completed.emit(entry["give_item"], entry["receive_item"])
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
