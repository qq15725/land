class_name ItemIcon
extends Control

# 通用物品图标控件：背景槽 + 图标 + 数量角标 + 选中态。
# 在 UI 网格、HUD 当前物品框、合成/交易行预览等位置统一使用。

const DEFAULT_SLOT_SIZE := Vector2(52, 52)

var _bg: Panel
var _icon: TextureRect
var _count_label: Label

var _item: ItemData = null
var _amount: int = 0
var _selected: bool = false
var _show_slot_bg: bool = true


func _init(show_slot_bg: bool = true) -> void:
	_show_slot_bg = show_slot_bg
	custom_minimum_size = DEFAULT_SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	if _show_slot_bg:
		_bg = Panel.new()
		_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_bg.add_theme_stylebox_override("panel", UIStyle.make_slot_style(_selected))
		_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bg)

	_icon = TextureRect.new()
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _show_slot_bg:
		_icon.offset_left = 8
		_icon.offset_right = -8
		_icon.offset_top = 8
		_icon.offset_bottom = -8
	add_child(_icon)

	_count_label = Label.new()
	_count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_count_label.offset_left = -28
	_count_label.offset_top = -18
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_count_label.add_theme_constant_override("shadow_offset_x", 1)
	_count_label.add_theme_constant_override("shadow_offset_y", 1)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)

	_apply()


func show_item(item: ItemData, amount: int = 1) -> void:
	_item = item
	_amount = amount
	if is_inside_tree():
		_apply()


func set_selected(value: bool) -> void:
	_selected = value
	if is_inside_tree() and _bg:
		_bg.add_theme_stylebox_override("panel", UIStyle.make_slot_style(_selected))


func clear() -> void:
	_item = null
	_amount = 0
	if is_inside_tree():
		_apply()


func _apply() -> void:
	if _item:
		_icon.texture = ItemDatabase.get_item_icon(_item)
		_icon.modulate = Color.WHITE
		_count_label.text = "x%d" % _amount if _amount > 1 else ""
		# 设非空 tooltip_text 让 Godot 触发 hover；实际样式走 _make_custom_tooltip
		tooltip_text = _item.display_name
	else:
		_icon.texture = null
		_count_label.text = ""
		tooltip_text = ""


# 自定义 tooltip：标题 + 描述 + 食物/工具效果 chip
func _make_custom_tooltip(_for_text: String) -> Object:
	if _item == null:
		return null
	var panel := PanelContainer.new()
	panel.theme = UIStyle.theme
	panel.custom_minimum_size = Vector2(220, 0)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = _item.display_name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	vbox.add_child(title)

	# 效果 chip
	var chips: PackedStringArray = []
	if _item.heal_amount > 0.0:
		chips.append("回血 +%d" % int(_item.heal_amount))
	if not _item.tool_type.is_empty():
		chips.append("工具：" + _tool_type_label(_item.tool_type))
	if _item.damage > 0.0:
		chips.append("伤害 +%d" % int(_item.damage))
	if _item.defense > 0.0:
		chips.append("防御 +%d" % int(_item.defense))
	if _item.ranged:
		chips.append("远程")
	if _item.attack_speed > 0.0:
		chips.append("攻速 +%d%%" % int(_item.attack_speed * 100.0))
	if not _item.equip_slot.is_empty():
		chips.append(_equip_slot_label(_item.equip_slot))
	if _item.sell_price > 0:
		chips.append("售价 %d 金" % _item.sell_price)
	if _item.max_stack > 1:
		chips.append("堆叠 %d" % _item.max_stack)
	if not chips.is_empty():
		var chip_lbl := Label.new()
		chip_lbl.text = "  ·  ".join(chips)
		chip_lbl.add_theme_font_size_override("font_size", 11)
		chip_lbl.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
		vbox.add_child(chip_lbl)

	if not _item.description.is_empty():
		var desc := Label.new()
		desc.text = _item.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
		desc.custom_minimum_size = Vector2(200, 0)
		vbox.add_child(desc)

	return panel


func _tool_type_label(t: String) -> String:
	match t:
		"axe": return "斧子"
		"pickaxe": return "镐子"
		_: return t

func _equip_slot_label(s: String) -> String:
	match s:
		"weapon": return "武器槽"
		"armor": return "护甲槽"
		"accessory": return "饰品槽"
		_: return s
