extends Node

signal day_started(day: int)
signal night_started(day: int)
signal hour_changed(hour: int)

const DAY_DURATION := 120.0  # 白天秒数（现实时间）
const NIGHT_DURATION := 60.0  # 夜晚秒数

enum Phase { DAY, NIGHT }

var current_day: int = 1
var current_phase: Phase = Phase.DAY
var phase_elapsed: float = 0.0

var _phase_duration: float = DAY_DURATION

func _process(delta: float) -> void:
	phase_elapsed += delta
	if phase_elapsed >= _phase_duration:
		phase_elapsed = 0.0
		_advance_phase()

func _advance_phase() -> void:
	if current_phase == Phase.DAY:
		current_phase = Phase.NIGHT
		_phase_duration = NIGHT_DURATION
		night_started.emit(current_day)
	else:
		current_phase = Phase.DAY
		_phase_duration = DAY_DURATION
		current_day += 1
		day_started.emit(current_day)

func is_night() -> bool:
	return current_phase == Phase.NIGHT

func get_phase_ratio() -> float:
	return phase_elapsed / _phase_duration
