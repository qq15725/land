class_name DamageNumber
extends Node2D

# 伤害飘字。冒险岛风格：
# - 普通命中：金黄 #FFB300 + 深棕描边，字号 16，BACK 弹跳上漂淡出
# - 暴击：血红 #FF1744 + 金黄 #FFEB3B 描边，字号 +30% (22)，弹跳更强，停顿后再上漂

const RISE := 36.0
const DURATION := 0.8
const RISE_CRIT := 48.0
const DURATION_CRIT := 1.1

const COLOR_NORMAL    := Color(1.0, 0.7, 0.0)        # #FFB300
const SHADOW_NORMAL   := Color(0.35, 0.16, 0.0, 0.95)  # #5A2A00
const COLOR_CRIT      := Color(1.0, 0.09, 0.27)      # #FF1744 血红
const SHADOW_CRIT     := Color(1.0, 0.92, 0.23)      # #FFEB3B 金边

var _label: Label

func _ready() -> void:
	z_index = ZLayer.DAMAGE_TEXT

# damage: 显示的伤害数字；color: 字色（默认按 is_crit 自动）；is_crit: 暴击差异化
static func spawn(parent: Node, pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color(0, 0, 0, 0)) -> void:
	var n := DamageNumber.new()
	parent.add_child(n)
	n.global_position = pos + Vector2(randf_range(-6, 6), -8)
	n._setup(damage, is_crit, color)

func _setup(damage: float, is_crit: bool, color: Color) -> void:
	_label = Label.new()
	# 暴击在数字前加 "!"，更易辨识
	_label.text = ("!" + str(int(damage))) if is_crit else str(int(damage))
	var font_size := 22 if is_crit else 16
	_label.add_theme_font_size_override("font_size", font_size)

	# 字色：调用方传了非零 alpha 就用调用方颜色，否则按是否暴击给默认
	var font_color: Color
	var shadow_color: Color
	if color.a > 0.01:
		font_color = color
		shadow_color = SHADOW_CRIT if is_crit else SHADOW_NORMAL
	else:
		font_color = COLOR_CRIT if is_crit else COLOR_NORMAL
		shadow_color = SHADOW_CRIT if is_crit else SHADOW_NORMAL

	_label.add_theme_color_override("font_color", font_color)
	_label.add_theme_color_override("font_shadow_color", shadow_color)
	# 暴击描边更粗（用更大 offset 模拟"加粗描边"）
	var shadow_off := 2 if is_crit else 1
	_label.add_theme_constant_override("shadow_offset_x", shadow_off)
	_label.add_theme_constant_override("shadow_offset_y", shadow_off)
	_label.position = Vector2(-24, -16)
	_label.size = Vector2(48, 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)

	var rise: float = RISE_CRIT if is_crit else RISE
	var duration: float = DURATION_CRIT if is_crit else DURATION
	scale = Vector2(0.4, 0.4)

	if is_crit:
		# 暴击：大幅 overshoot 弹跳 → 短暂停顿 → 慢速上漂淡出
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# 上漂分两段：前 0.2s 几乎不动（停顿强调），后段加速上飘
		tw.tween_property(self, "position:y", position.y - rise * 0.15, 0.2).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(self, "scale", Vector2(1.1, 1.1), 0.08).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "position:y", position.y - rise, duration - 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "modulate:a", 0.0, (duration - 0.28) * 0.8).set_delay((duration - 0.28) * 0.2)
		tw.chain().tween_callback(queue_free)
	else:
		# 普通：弹跳 + 上漂 + 淡出
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y - rise, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
		tw.chain().tween_callback(queue_free)
