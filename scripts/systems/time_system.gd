extends Node

signal day_started(day: int)
signal night_started(day: int)
signal hour_changed(hour: int)
signal season_changed(season: String)

const DAY_DURATION := 120.0     # 白天秒数（现实时间）
const NIGHT_DURATION := 60.0    # 夜晚秒数
const DAYS_PER_SEASON := 7      # 一季的天数

enum Phase { DAY, NIGHT }

const SEASONS: Array[String] = ["spring", "summer", "autumn", "winter"]
const SEASON_LABELS: Dictionary = {
	"spring": "春",
	"summer": "夏",
	"autumn": "秋",
	"winter": "冬",
}

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
		var prev_season := current_season()
		current_phase = Phase.DAY
		_phase_duration = DAY_DURATION
		current_day += 1
		day_started.emit(current_day)
		var new_season := current_season()
		if new_season != prev_season:
			season_changed.emit(new_season)

func is_night() -> bool:
	return current_phase == Phase.NIGHT

func get_phase_ratio() -> float:
	return phase_elapsed / _phase_duration

# ─── 季节 ────────────────────────────────────────────────────────────────────

func current_season() -> String:
	var idx := ((current_day - 1) / DAYS_PER_SEASON) % SEASONS.size()
	return SEASONS[idx]

func current_season_label() -> String:
	return SEASON_LABELS[current_season()]

func day_in_season() -> int:
	return ((current_day - 1) % DAYS_PER_SEASON) + 1

func is_season_allowed(seasons: Array) -> bool:
	if seasons.is_empty():
		return true
	return current_season() in seasons
