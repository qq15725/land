class_name PickupFloat
extends Node2D

# 拾取飘字：捡到物品时在玩家头顶飘出「物品图标 + N」并上漂淡出。
# 与战斗 DamageNumber 对称，补齐采集/拾取的反馈手感（juice）。
# 纯客户端表现层，由 VFXEventRouter 监听 EventBus.item_picked_up 触发。

const RISE := 28.0
const DURATION := 0.9

static func spawn(parent: Node, pos: Vector2, item: ItemData, amount: int) -> void:
	if item == null or parent == null:
		return
	var n := PickupFloat.new()
	parent.add_child(n)
	n.global_position = pos + Vector2(randf_range(-5, 5), 0)
	n._setup(item, amount)

func _setup(item: ItemData, amount: int) -> void:
	z_index = ZLayer.DAMAGE_TEXT

	var icon := Sprite2D.new()
	icon.texture = ItemDatabase.get_item_icon(item)
	if icon.texture != null:
		var s := 11.0 / maxf(float(ItemDatabase.get_icon_size()), 1.0)
		icon.scale = Vector2(s, s)
		icon.position = Vector2(-9, 0)
		add_child(icon)

	var lbl := Label.new()
	lbl.text = "+%d" % amount
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.6))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.2, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.position = Vector2(0, -10)
	add_child(lbl)

	scale = Vector2(0.5, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1, 1), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - RISE, DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tw.chain().tween_callback(queue_free)
