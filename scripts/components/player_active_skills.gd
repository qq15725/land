class_name PlayerActiveSkills
extends Node

# 玩家主动技能组件。每个玩家各自一份：
#   - 冷却计时
#   - 已学技能列表（learned，技能树）
#   - 职业 class_id
#   - 可分配的技能点 skill_points
#
# 设计：basic_swing 与所有 sp_cost=0 的技能（如基础挥砍）出生自动学会。
# 其他技能须 try_learn 学习，消耗 sp_cost 技能点。max_level > 1 的技能可多次学习升级。
# 升级被动等级（PlayerSkills 加任意 xp 等级）→ 自动 +1 SP（由 EventBus 监听）。

signal cooldown_started(skill_id: String, cooldown: float)

var _cd: Dictionary = {}        # skill_id → 剩余秒数
var learned: Dictionary = {}    # skill_id → level（0 = 未学，1+ 已学）
var class_id: String = ""       # "" = 通用
var skill_points: int = 0

func _ready() -> void:
	# 默认学会所有 sp_cost = 0 的技能（基础挥砍等）
	for s in ItemDatabase.get_all_active_skills():
		var sd := s as ActiveSkillData
		if sd.sp_cost <= 0:
			learned[sd.id] = 1
	# 本地 PlayerSkills 升级 → +1 SP（用 player 本地 signal 避免多玩家串扰）
	call_deferred("_hook_local_skills")

func _hook_local_skills() -> void:
	var p := get_parent()
	if p == null:
		return
	var ps: PlayerSkills = p.get("skills") if p.get("skills") else null
	if ps != null and not ps.leveled_up.is_connected(_on_passive_leveled_up):
		ps.leveled_up.connect(_on_passive_leveled_up)

func _process(delta: float) -> void:
	for sid in _cd.keys():
		_cd[sid] = maxf(0.0, _cd[sid] - delta)

# 玩家总等级 = 4 个被动技能等级之和
func total_level() -> int:
	var p := get_parent()
	if p == null:
		return 0
	var ps: PlayerSkills = p.get("skills") if p.get("skills") else null
	if ps == null:
		return 0
	var total := 0
	for sd in SkillSystem.get_all_skills():
		total += ps.get_level(sd.id)
	return total

# ─── 查询 ────────────────────────────────────────────────────────────────

func is_unlocked(skill: ActiveSkillData) -> bool:
	return skill != null and total_level() + 1 >= skill.unlock_level

func is_learned(skill_id: String) -> bool:
	return int(learned.get(skill_id, 0)) > 0

func get_skill_level(skill_id: String) -> int:
	return int(learned.get(skill_id, 0))

func can_use_class(skill: ActiveSkillData) -> bool:
	return skill.class_id.is_empty() or skill.class_id == class_id

func cooldown_remaining(skill_id: String) -> float:
	return float(_cd.get(skill_id, 0.0))

# 是否可以学这个技能（含升级到下一级）
func can_learn(skill: ActiveSkillData) -> bool:
	if skill == null:
		return false
	if not can_use_class(skill):
		return false
	if not is_unlocked(skill):
		return false
	if not skill.parent_skill_id.is_empty() and not is_learned(skill.parent_skill_id):
		return false
	var cur := get_skill_level(skill.id)
	if cur >= skill.max_level:
		return false
	return skill_points >= skill.sp_cost

# ─── 修改 ────────────────────────────────────────────────────────────────

func try_learn(skill: ActiveSkillData) -> bool:
	if not can_learn(skill):
		return false
	skill_points -= skill.sp_cost
	var new_level: int = get_skill_level(skill.id) + 1
	learned[skill.id] = new_level
	var pid := _player_id()
	EventBus.active_skill_learned.emit(pid, skill.id, new_level)
	EventBus.skill_points_changed.emit(pid, skill_points)
	return true

func set_class(new_class_id: String) -> void:
	class_id = new_class_id
	# 应用职业 stat bonus
	var cls: ClassData = ItemDatabase.get_class_data(new_class_id)
	var pl := get_parent()
	if cls != null and pl is Player:
		var hp: HealthComponent = (pl as Player).health
		var mp: ManaComponent = (pl as Player).mana
		if hp:
			hp.max_health = 100.0 + cls.hp_bonus
			hp.current_health = minf(hp.current_health, hp.max_health)
			hp.health_changed.emit(hp.current_health, hp.max_health)
		if mp:
			mp.max_mana = 100.0 + cls.mp_bonus
			mp.regen_per_sec = 0.5 + cls.mp_regen_bonus
			mp.current_mana = minf(mp.current_mana, mp.max_mana)
			mp.mana_changed.emit(mp.current_mana, mp.max_mana)
	EventBus.player_class_changed.emit(_player_id(), new_class_id)

func add_skill_points(n: int) -> void:
	if n <= 0:
		return
	skill_points += n
	EventBus.skill_points_changed.emit(_player_id(), skill_points)

# 释放：检查冷却 + MP + 解锁 + 学习状态 + 职业
func try_cast(skill: ActiveSkillData, mana: ManaComponent) -> bool:
	if skill == null:
		return false
	if not can_use_class(skill):
		return false
	if not is_learned(skill.id):
		return false
	if not is_unlocked(skill):
		return false
	if cooldown_remaining(skill.id) > 0.0:
		return false
	if skill.mp_cost > 0.0:
		if not mana.consume(skill.mp_cost):
			return false
	_cd[skill.id] = skill.cooldown
	cooldown_started.emit(skill.id, skill.cooldown)
	return true

# ─── 事件 ────────────────────────────────────────────────────────────────

func _on_passive_leveled_up(_skill_id: String, _new_level: int) -> void:
	# 同 player 的 PlayerSkills 升级 → +1 SP
	add_skill_points(1)

func _player_id() -> int:
	var p := get_parent()
	if p == null:
		return 0
	return NetworkRegistry.get_id(p)

# ─── 存档 ────────────────────────────────────────────────────────────────

func export_state() -> Dictionary:
	return {
		"learned": learned.duplicate(),
		"class_id": class_id,
		"skill_points": skill_points,
	}

func import_state(data: Dictionary) -> void:
	learned = (data.get("learned", {}) as Dictionary).duplicate()
	class_id = data.get("class_id", "")
	skill_points = int(data.get("skill_points", 0))
