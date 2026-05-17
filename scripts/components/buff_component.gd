class_name BuffComponent
extends Node

# Per-player buff 管理。
# Buff 数据来自 BuffSystem.get_buff(id)，组件只维护当前剩余时间。
# 内部状态：active[id] = remaining_time（float 秒）

signal buffs_changed(active: Dictionary)

var active: Dictionary = {}    # id → remaining_time
var _heal_accum: float = 0.0

func _process(delta: float) -> void:
	var changed := false
	var to_remove: Array = []
	for id in active.keys():
		active[id] = float(active[id]) - delta
		if float(active[id]) <= 0.0:
			to_remove.append(id)
			changed = true
	for id in to_remove:
		active.erase(id)
	# 回血叠加
	var regen := regen_per_sec()
	if regen > 0.0:
		_heal_accum += regen * delta
		if _heal_accum >= 1.0:
			var pl := get_parent()
			if pl and pl.has_node("HealthComponent"):
				(pl.get_node("HealthComponent") as HealthComponent).heal(floor(_heal_accum))
			_heal_accum = fposmod(_heal_accum, 1.0)
	if changed:
		buffs_changed.emit(active)

func add_buff(id: String) -> void:
	var buff := BuffSystem.get_buff(id)
	if buff.is_empty():
		return
	# 重复加：刷新持续时间为 max
	var dur := float(buff.get("duration", 30.0))
	if active.has(id):
		active[id] = maxf(float(active[id]), dur)
	else:
		active[id] = dur
	buffs_changed.emit(active)

func remove_buff(id: String) -> void:
	if active.erase(id):
		buffs_changed.emit(active)

func damage_mul() -> float:
	var m := 1.0
	for id in active.keys():
		var b := BuffSystem.get_buff(id)
		m *= float(b.get("damage_mul", 1.0))
	return m

func defense_add() -> float:
	var v := 0.0
	for id in active.keys():
		var b := BuffSystem.get_buff(id)
		v += float(b.get("defense_add", 0.0))
	return v

func speed_mul() -> float:
	var m := 1.0
	for id in active.keys():
		var b := BuffSystem.get_buff(id)
		m *= float(b.get("speed_mul", 1.0))
	return m

func regen_per_sec() -> float:
	var v := 0.0
	for id in active.keys():
		var b := BuffSystem.get_buff(id)
		v += float(b.get("regen_per_sec", 0.0))
	return v
