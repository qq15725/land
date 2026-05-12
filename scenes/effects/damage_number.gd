class_name DamageNumber
extends Node2D

# 伤害飘字。命中时在伤害位置生成，向上漂移 + 淡出。
# 大伤害字号更大，暴击用橙色（is_crit）。

const RISE := 36.0
const DURATION := 0.8

var _label: Label

func _ready() -> void:
	z_index = 100  # 盖在所有实体上

# damage: 显示的伤害数字；color: 字色（默认白）；is_crit: 暴击用更大更红
static func spawn(parent: Node, pos: Vector2, damage: float, is_crit: bool = false, color: Color = Color.WHITE) -> void:
	var n := DamageNumber.new()
	parent.add_child(n)
	n.global_position = pos + Vector2(randf_range(-6, 6), -8)
	n._setup(damage, is_crit, color)

func _setup(damage: float, is_crit: bool, color: Color) -> void:
	_label = Label.new()
	_label.text = str(int(damage))
	var font_size := 16 if not is_crit else 22
	_label.add_theme_font_size_override("font_size", font_size)
	if is_crit:
		_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	else:
		_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	# 居中：让锚点偏移到文字宽度的一半
	_label.position = Vector2(-20, -16)
	_label.size = Vector2(40, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	scale = Vector2(0.5, 0.5)
	# 出场弹跳 + 上漂 + 淡出
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - RISE, DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.5)
	tw.chain().tween_callback(queue_free)
