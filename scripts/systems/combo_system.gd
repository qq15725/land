extends Node

# 连击系统（冒险岛风格 COMBO ×N）。
# - SkillExecutor 每次命中调用 register_hit() → 计数 +1，重置 1.5s 计时
# - 超时 → 计数归 0
# - HUD 监听 combo_changed，count >= MIN_DISPLAY 时显示飘字
# - count 越高字号越大、颜色越鲜艳（梯度）

const RESET_TIME := 1.5     # 多久内连续命中算 combo
const MIN_DISPLAY := 3      # 命中数 >= N 才显示飘字

signal combo_changed(count: int)
signal combo_ended

var _count: int = 0
var _timer: float = 0.0


func register_hit() -> void:
	_count += 1
	_timer = RESET_TIME
	combo_changed.emit(_count)


func _process(delta: float) -> void:
	if _count <= 0:
		return
	_timer -= delta
	if _timer <= 0.0:
		var ended_count := _count
		_count = 0
		combo_ended.emit()
		combo_changed.emit(0)
		# 防止编译警告
		var _unused := ended_count


func get_count() -> int:
	return _count


func reset() -> void:
	_count = 0
	_timer = 0.0
	combo_changed.emit(0)
