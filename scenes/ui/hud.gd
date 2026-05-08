extends Control

var _health_bar: ProgressBar
var _mode_label: Label
var _selected_label: Label
var _time_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 0)
	margin.add_child(vbox)

	var hp_row := HBoxContainer.new()
	vbox.add_child(hp_row)

	var hp_icon := Label.new()
	hp_icon.text = "HP "
	hp_row.add_child(hp_icon)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(140, 16)
	_health_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.15, 0.15)
	_health_bar.add_theme_stylebox_override("fill", fill)
	hp_row.add_child(_health_bar)

	_time_label = Label.new()
	_time_label.text = "第1天  白天"
	_time_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_time_label)

	_selected_label = Label.new()
	_selected_label.text = ""
	_selected_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_selected_label)

	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_mode_label)

func _process(_delta: float) -> void:
	var phase_text := "夜晚" if TimeSystem.is_night() else "白天"
	_time_label.text = "第%d天  %s" % [TimeSystem.current_day, phase_text]

func setup(health: HealthComponent, inventory: InventoryComponent) -> void:
	_health_bar.max_value = health.max_health
	_health_bar.value = health.current_health
	health.health_changed.connect(func(cur, _m): _health_bar.value = cur)
	BuildingSystem.build_mode_entered.connect(func(_b): _mode_label.text = "[建造模式]  左键放置  右键/ESC取消")
	BuildingSystem.build_mode_exited.connect(func(): _mode_label.text = "")
	inventory.selection_changed.connect(func(_i): _on_selection_changed(inventory))

func _on_selection_changed(inventory: InventoryComponent) -> void:
	var item := inventory.get_selected_item()
	_selected_label.text = "[%s]" % item.display_name if item else ""
