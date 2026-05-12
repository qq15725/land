extends DraggablePanel

enum Tab { TRADE, SELL }

var _player_inventory: InventoryComponent
var _merchant_data: MerchantData
var _content_list: VBoxContainer
var _title_label: Label
var _gold_label: Label
var _trade_btn: Button
var _sell_btn: Button
var _current_tab: int = Tab.TRADE

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(420, 460)
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

	_gold_label = Label.new()
	_gold_label.text = "0 G"
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	header.add_child(_gold_label)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_row)

	_trade_btn = Button.new()
	_trade_btn.text = "交易"
	_trade_btn.toggle_mode = true
	_trade_btn.button_pressed = true
	_trade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trade_btn.pressed.connect(func(): _switch_tab(Tab.TRADE))
	tab_row.add_child(_trade_btn)

	_sell_btn = Button.new()
	_sell_btn.text = "出售"
	_sell_btn.toggle_mode = true
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.pressed.connect(func(): _switch_tab(Tab.SELL))
	tab_row.add_child(_sell_btn)

	var hint := Label.new()
	hint.text = "出售：把背包里有售价的物品卖给商人"
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(scroll)

	_content_list = VBoxContainer.new()
	_content_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content_list)

func setup(_player_inv: InventoryComponent) -> void:
	_player_inventory = _player_inv

func _on_open_trade(merchant: MerchantData, player_id: int) -> void:
	var player := NetworkRegistry.get_node_by_id(player_id) as Player
	if player == null:
		return
	var player_inv: InventoryComponent = player.inventory
	if _player_inventory != player_inv:
		if _player_inventory:
			if _player_inventory.gold_changed.is_connected(_on_gold_changed):
				_player_inventory.gold_changed.disconnect(_on_gold_changed)
			if _player_inventory.changed.is_connected(_on_inventory_changed):
				_player_inventory.changed.disconnect(_on_inventory_changed)
		_player_inventory = player_inv
		_player_inventory.gold_changed.connect(_on_gold_changed)
		_player_inventory.changed.connect(_on_inventory_changed)
	_merchant_data = merchant
	_title_label.text = merchant.display_name
	_update_gold_label()
	_switch_tab(Tab.TRADE)
	show()

func _on_gold_changed(_amount: int) -> void:
	_update_gold_label()

func _on_inventory_changed() -> void:
	if visible:
		_refresh()

func _update_gold_label() -> void:
	if _player_inventory:
		_gold_label.text = "%d G" % _player_inventory.gold

func _switch_tab(tab: int) -> void:
	_current_tab = tab
	_trade_btn.button_pressed = tab == Tab.TRADE
	_sell_btn.button_pressed = tab == Tab.SELL
	_refresh()

func _refresh() -> void:
	for child in _content_list.get_children():
		child.queue_free()
	if not _merchant_data or not _player_inventory:
		return
	if _current_tab == Tab.TRADE:
		_refresh_trade()
	else:
		_refresh_sell()

func _refresh_trade() -> void:
	for entry in _merchant_data.trades:
		_content_list.add_child(_make_trade_row(entry))
		_content_list.add_child(HSeparator.new())

func _refresh_sell() -> void:
	var aggregated: Dictionary = {}  # ItemData → total amount
	for slot in _player_inventory.slots:
		var item: ItemData = slot.item
		if item == null or item.sell_price <= 0:
			continue
		aggregated[item] = aggregated.get(item, 0) + slot.amount
	if aggregated.is_empty():
		var empty := Label.new()
		empty.text = "没有可出售的物品"
		empty.modulate = Color(0.7, 0.7, 0.7)
		_content_list.add_child(empty)
		return
	for item in aggregated:
		_content_list.add_child(_make_sell_row(item, aggregated[item]))
		_content_list.add_child(HSeparator.new())

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

func _make_sell_row(item: ItemData, owned: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	row.add_child(_make_chip(item, owned))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	info.add_child(name_lbl)

	var price_lbl := Label.new()
	price_lbl.text = "%d G / 个" % item.sell_price
	price_lbl.add_theme_font_size_override("font_size", 11)
	price_lbl.modulate = Color(1.0, 0.85, 0.3)
	info.add_child(price_lbl)

	var sell_one := Button.new()
	sell_one.text = "卖 1"
	sell_one.pressed.connect(func(): _do_sell(item, 1))
	row.add_child(sell_one)

	var sell_all := Button.new()
	sell_all.text = "卖全部 (%d)" % owned
	sell_all.pressed.connect(func(): _do_sell(item, owned))
	row.add_child(sell_all)

	return row

func _make_chip(item: ItemData, amount: int) -> Control:
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.show_item(item, amount)
	return icon

func _do_trade(entry: Dictionary) -> void:
	if not _merchant_data:
		return
	var idx: int = _merchant_data.trades.find(entry)
	if idx < 0:
		return
	PlayerActions.request_trade(_merchant_data.id, idx)
	# 实际背包变化触发 inventory.changed → _on_inventory_changed → _refresh

func _do_sell(item: ItemData, amount: int) -> void:
	PlayerActions.request_sell(item.id, amount)
	# 同上，刷新由 inventory.changed 触发

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
