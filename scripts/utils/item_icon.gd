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
		tooltip_text = _item.display_name
	else:
		_icon.texture = null
		_count_label.text = ""
		tooltip_text = ""
