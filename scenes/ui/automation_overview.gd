class_name AutomationOverview
extends DraggablePanel

# 生产线总览（F9）：U 键开关，显示自动化节点统计与传送带物品数。

var _label: Label
const TYPE_NAMES := {
	"Conveyor": "传送带", "Extractor": "抽取器", "Inserter": "放入器",
	"AutoCrafter": "合成机", "Splitter": "分流器", "FilterConveyor": "过滤带",
}

func _ready() -> void:
	super._ready()
	center_with_size(Vector2(240, 220))
	visible = false
	_build()

func _build() -> void:
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 12)
	add_child(m)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	m.add_child(vbox)
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "⚙ 生产线总览"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(make_close_button())
	vbox.add_child(HSeparator.new())
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_label)
	var hint := Label.new()
	hint.text = "（U 键开关）"
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_U:
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	var s := AutomationSystem.get_stats()
	var lines := ["节点总数：%d" % int(s.total), "传送带上物品：%d" % int(s.items_on_belts), "—— 各类型 ——"]
	var by_type: Dictionary = s.by_type
	for t in by_type:
		lines.append("%s × %d" % [TYPE_NAMES.get(t, t), int(by_type[t])])
	_label.text = "\n".join(lines)
