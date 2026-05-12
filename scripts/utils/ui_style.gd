extends Node

const SHEET_PATH := "res://assets/sprites/ui/ui_sheet.png"
const FONT_PATH := "res://assets/fonts/pixel.ttf"  # 用户自行放置即可启用
const DEFAULT_FONT_SIZE := 13

# 对外暴露的全局 Theme。所有 UI 通过 `theme = UIStyle.theme` 接入。
var theme := Theme.new()
# 格子美术，单独暴露供背包/储物箱槽位复用
var _slot_base: StyleBoxTexture = null

func _ready() -> void:
	_load_sheet()
	_load_font()

func _load_sheet() -> void:
	var sheet := Image.load_from_file(SHEET_PATH)
	if not sheet:
		return

	var panel_s  := _crop(sheet, Rect2i(0,   0,  128, 128), 32, 32, 32, 32)
	var btn_n    := _crop(sheet, Rect2i(0, 136,  192,  64),  8,  8,  8,  8)
	var btn_h    := _crop(sheet, Rect2i(0, 200,  192,  64),  8,  8,  8,  8)
	var btn_p    := _crop(sheet, Rect2i(0, 264,  192,  64),  8,  8,  8,  8)
	_slot_base   = _crop(sheet, Rect2i(0, 336,   80,  80),   6,  6,  6,  6)
	var hp_bg    := _crop(sheet, Rect2i(0, 424,  384,  48),  4,  4,  4,  4)
	var hp_fill  := _crop(sheet, Rect2i(0, 472,  384,  48),  4,  4,  4,  4)
	var sep_s    := _crop(sheet, Rect2i(0, 528,   64,  12),  0,  0,  0,  0)

	theme.set_stylebox("panel",      "PanelContainer", panel_s)
	theme.set_stylebox("panel",      "Panel",          _slot_base.duplicate())
	theme.set_stylebox("normal",     "Button",         btn_n)
	theme.set_stylebox("hover",      "Button",         btn_h)
	theme.set_stylebox("pressed",    "Button",         btn_p)
	theme.set_stylebox("disabled",   "Button",         btn_n)
	theme.set_stylebox("focus",      "Button",         StyleBoxEmpty.new())
	theme.set_stylebox("separator",  "HSeparator",     sep_s)
	theme.set_constant("separation", "HSeparator", 12)
	theme.set_stylebox("background", "ProgressBar",    hp_bg)
	theme.set_stylebox("fill",       "ProgressBar",    hp_fill)

func _load_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font := load(FONT_PATH) as Font
	if font == null:
		return
	theme.default_font = font
	theme.default_font_size = DEFAULT_FONT_SIZE


func make_slot_style(selected: bool) -> StyleBox:
	if not _slot_base:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(3)
		s.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		if selected:
			s.border_color = Color.WHITE
			s.set_border_width_all(2)
		return s
	var s := _slot_base.duplicate() as StyleBoxTexture
	if selected:
		s.modulate_color = Color(1.4, 1.2, 0.45)
	return s


func _crop(img: Image, region: Rect2i, ml: int, mr: int, mt: int, mb: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(img.get_region(region))
	s.texture_margin_left   = ml
	s.texture_margin_right  = mr
	s.texture_margin_top    = mt
	s.texture_margin_bottom = mb
	return s
