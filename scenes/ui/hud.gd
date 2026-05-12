extends Control

var _health_bar: ProgressBar
var _mode_label: Label
var _time_label: Label
var _phase_icon: Label  # 占位：未接入图标前用 emoji 字符
var _selected_icon: ItemIcon
var _inventory: InventoryComponent

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIStyle.theme

	_build_top_left()
	_build_bottom_right()
	_build_center_top()

func _build_top_left() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.custom_minimum_size = Vector2(220, 0)
	margin.add_child(vbox)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	vbox.add_child(hp_row)

	var hp_label := Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_row.add_child(hp_label)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(180, 20)
	_health_bar.show_percentage = false
	hp_row.add_child(_health_bar)

	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 6)
	vbox.add_child(time_row)

	_phase_icon = Label.new()
	_phase_icon.text = "☀"
	_phase_icon.add_theme_font_size_override("font_size", 14)
	time_row.add_child(_phase_icon)

	_time_label = Label.new()
	_time_label.text = "第1天  白天"
	_time_label.add_theme_font_size_override("font_size", 12)
	time_row.add_child(_time_label)

func _build_center_top() -> void:
	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_font_size_override("font_size", 13)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_mode_label.offset_top = 12
	add_child(_mode_label)

func _build_bottom_right() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	_selected_icon = ItemIcon.new()
	_selected_icon.custom_minimum_size = Vector2(64, 64)
	margin.add_child(_selected_icon)

func _process(_delta: float) -> void:
	var is_night := TimeSystem.is_night()
	_phase_icon.text = "☾" if is_night else "☀"
	_time_label.text = "第%d天 %s %s" % [
		TimeSystem.current_day,
		TimeSystem.current_season_label(),
		"夜晚" if is_night else "白天",
	]

func setup(health: HealthComponent, inventory: InventoryComponent) -> void:
	_inventory = inventory
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current_health
	health.health_changed.connect(func(cur, _m): _health_bar.value = cur)
	BuildingSystem.build_mode_entered.connect(func(_b): _mode_label.text = "[建造模式]  左键放置  右键/ESC取消")
	BuildingSystem.build_mode_exited.connect(func(): _mode_label.text = "")
	inventory.selection_changed.connect(func(_i): _refresh_selected())
	inventory.changed.connect(_refresh_selected)
	_refresh_selected()

func _refresh_selected() -> void:
	if not _selected_icon or not _inventory:
		return
	var item := _inventory.get_selected_item()
	if item:
		var slot: Dictionary = _inventory.slots[_inventory.selected_slot]
		_selected_icon.show_item(item, slot.amount)
	else:
		_selected_icon.clear()
