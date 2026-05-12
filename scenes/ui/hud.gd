extends Control

const HOTBAR_SIZE := 9

var _health_bar: ProgressBar
var _mode_label: Label
var _time_label: Label
var _phase_icon: Label  # 占位：未接入图标前用 emoji 字符
var _toast_label: Label
var _toast_timer: float = 0.0
var _hotbar_row: HBoxContainer
var _hotbar_icons: Array[ItemIcon] = []
var _inventory: InventoryComponent

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIStyle.theme

	_build_top_left()
	_build_center_top()
	_build_bottom_center()

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
	var top_box := VBoxContainer.new()
	top_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_box.offset_top = 12
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.add_theme_constant_override("separation", 4)
	add_child(top_box)

	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_font_size_override("font_size", 13)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(_mode_label)

	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.add_theme_font_size_override("font_size", 12)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.modulate = Color(1.0, 0.95, 0.7, 0.0)
	top_box.add_child(_toast_label)

func _build_bottom_center() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)

	_hotbar_row = HBoxContainer.new()
	_hotbar_row.add_theme_constant_override("separation", 4)
	center.add_child(_hotbar_row)

	for i in HOTBAR_SIZE:
		var slot_box := VBoxContainer.new()
		slot_box.add_theme_constant_override("separation", 1)

		var key_lbl := Label.new()
		key_lbl.text = str(i + 1)
		key_lbl.add_theme_font_size_override("font_size", 9)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_box.add_child(key_lbl)

		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(48, 48)
		_hotbar_icons.append(icon)
		slot_box.add_child(icon)

		_hotbar_row.add_child(slot_box)

func _process(delta: float) -> void:
	var is_night := TimeSystem.is_night()
	_phase_icon.text = "☾" if is_night else "☀"
	_time_label.text = "第%d天 %s %s" % [
		TimeSystem.current_day,
		TimeSystem.current_season_label(),
		"夜晚" if is_night else "白天",
	]
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast_label.modulate.a = clampf(_toast_timer, 0.0, 1.0)
		if _toast_timer <= 0.0:
			_toast_label.text = ""

func setup(health: HealthComponent, inventory: InventoryComponent) -> void:
	_inventory = inventory
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current_health
	health.health_changed.connect(func(cur, _m): _health_bar.value = cur)
	BuildingSystem.build_mode_entered.connect(func(_b): _mode_label.text = "[建造模式]  左键放置  右键/ESC取消")
	BuildingSystem.build_mode_exited.connect(func(): _mode_label.text = "")
	inventory.selection_changed.connect(func(_i): _refresh_hotbar())
	inventory.changed.connect(_refresh_hotbar)
	_refresh_hotbar()

func _refresh_hotbar() -> void:
	if not _inventory:
		return
	for i in HOTBAR_SIZE:
		var icon: ItemIcon = _hotbar_icons[i]
		if i >= _inventory.slots.size():
			icon.clear()
			icon.set_selected(false)
			continue
		var slot: Dictionary = _inventory.slots[i]
		if slot.item:
			icon.show_item(slot.item, slot.amount)
		else:
			icon.clear()
		icon.set_selected(i == _inventory.selected_slot)

func show_toast(text: String, duration: float = 2.0) -> void:
	_toast_label.text = text
	_toast_timer = duration
	_toast_label.modulate = Color(1.0, 0.95, 0.7, 1.0)
