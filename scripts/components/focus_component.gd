class_name FocusComponent
extends Node

# FP（Focus / 体力）：轻量休闲风格 — 不阻断玩法。
# 攻击 / 技能消耗 → 数值反馈，FP 为 0 时玩家可以继续打但 HUD 显示空槽。
# 站着自然恢复，比 MP 快。

signal focus_changed(current: float, maximum: float)

@export var max_focus: float = 100.0
@export var regen_per_sec: float = 4.0

var current_focus: float

func _ready() -> void:
	current_focus = max_focus
	set_process(true)

func _process(delta: float) -> void:
	if current_focus >= max_focus:
		return
	current_focus = minf(max_focus, current_focus + regen_per_sec * delta)
	focus_changed.emit(current_focus, max_focus)

func consume(amount: float) -> void:
	if amount <= 0.0:
		return
	current_focus = maxf(0.0, current_focus - amount)
	focus_changed.emit(current_focus, max_focus)

func restore(amount: float) -> void:
	current_focus = minf(max_focus, current_focus + amount)
	focus_changed.emit(current_focus, max_focus)
