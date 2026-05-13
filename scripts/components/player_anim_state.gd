class_name PlayerAnimState
extends Node

# 玩家动画状态机（轻量）。
#
# 现有 AnimatedSprite2D 只有 walk_4方向；新动画通过 Tween 在 visual.scale /
# visual.modulate 上模拟，等正式美术帧出来再换 sprite_frames。
#
# 状态：
#   idle / walk_xxx  — 由 Player._update_animation 控制
#   cast_fan         — 近战挥砍，scale 抖动
#   cast_circle      — 自身 AOE，scale 微缩 + 蓝光
#   cast_rect        — 突刺，前冲微位移
#   cast_projectile  — 远程施法，蓝光闪
#   hit              — 受击，红闪
#   die              — 死亡，灰化淡出
#
# 锁定机制：cast / hit / die 进入后，walk/idle 不能覆盖，直到 _locked_until 到期。

var _locked_until: float = 0.0
var current_state: String = "idle"

func is_locked() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _locked_until

# 由 Player.do_cast_skill / on damage / on died 调用
func play_state(state_name: String, duration: float = 0.3) -> void:
	if state_name.is_empty():
		return
	current_state = state_name
	_locked_until = (Time.get_ticks_msec() / 1000.0) + duration
	_trigger_visual(state_name, duration)

func _trigger_visual(state_name: String, duration: float) -> void:
	var pl := get_parent()
	if pl == null:
		return
	var v: AnimatedSprite2D = pl.get("visual")
	if v == null:
		return
	var base_scale: Vector2 = pl.get_meta("_base_visual_scale", v.scale)
	if not pl.has_meta("_base_visual_scale"):
		pl.set_meta("_base_visual_scale", v.scale)
		base_scale = v.scale
	match state_name:
		"cast_fan", "cast_rect":
			# 挥砍：横向拉伸 + 回弹
			var tw := v.create_tween()
			tw.tween_property(v, "scale", base_scale * Vector2(1.15, 0.9), duration * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(v, "scale", base_scale, duration * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"cast_circle":
			# 自身 AOE：身体微微下蹲再弹起，加蓝色光晕 modulate
			var tw := v.create_tween().set_parallel(true)
			tw.tween_property(v, "scale", base_scale * Vector2(0.9, 1.15), duration * 0.3).set_trans(Tween.TRANS_BACK)
			tw.tween_property(v, "modulate", Color(0.8, 0.95, 1.4), duration * 0.3)
			tw.chain().set_parallel(true)
			tw.tween_property(v, "scale", base_scale, duration * 0.5).set_trans(Tween.TRANS_BACK)
			tw.tween_property(v, "modulate", Color.WHITE, duration * 0.5)
		"cast_projectile":
			# 远程：蓝闪
			var tw := v.create_tween()
			tw.tween_property(v, "modulate", Color(0.9, 1.0, 1.5), duration * 0.2)
			tw.tween_property(v, "modulate", Color.WHITE, duration * 0.6)
		"hit":
			var tw := v.create_tween()
			tw.tween_property(v, "modulate", Color(2.0, 0.4, 0.4), duration * 0.2)
			tw.tween_property(v, "modulate", Color.WHITE, duration * 0.6)
		"die":
			v.modulate = Color(0.4, 0.4, 0.4, 0.3)
