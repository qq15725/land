class_name BounceMarker
extends Object

# 头顶跳动提示标记（作物成熟 ✦ / 动物可喂食 ! 等共用）。
# 创建一个上下循环跳动的 Label 挂到实体上方，返回引用供显隐控制。

static func create(parent: Node2D, text: String, color: Color, y: float, font_size: int = 14) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.3, 0.15, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.position = Vector2(-6, y)
	lbl.z_index = 40
	parent.add_child(lbl)
	var tw := parent.create_tween().set_loops()
	tw.tween_property(lbl, "position:y", y - 6.0, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lbl, "position:y", y, 0.5).set_trans(Tween.TRANS_SINE)
	return lbl
