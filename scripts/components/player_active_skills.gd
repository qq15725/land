class_name PlayerActiveSkills
extends Node

# 玩家主动技能组件。每个玩家各自一份：
#   - 冷却计时
#   - 已学技能列表（learned，预留技能树）
#   - 职业 class_id（预留职业系统）
#
# MVP 阶段所有技能默认 learned[id] = 1，class_id = ""（通用）。
# 未来加技能树 / 职业 UI 时，只改 learned 写入逻辑与 class_id，无需动 try_cast。

signal cooldown_started(skill_id: String, cooldown: float)

var _cd: Dictionary = {}        # skill_id → 剩余秒数
var learned: Dictionary = {}    # skill_id → level（0 = 未学）
var class_id: String = ""       # "" = 通用职业

func _ready() -> void:
	# MVP：默认所有主动技能 level 1
	for s in ItemDatabase.get_all_active_skills():
		learned[(s as ActiveSkillData).id] = 1

func _process(delta: float) -> void:
	for sid in _cd.keys():
		_cd[sid] = maxf(0.0, _cd[sid] - delta)

# 玩家总等级（4 个被动技能之和）。MVP 阶段用这个判定 unlock_level。
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

func is_unlocked(skill: ActiveSkillData) -> bool:
	return skill != null and total_level() + 1 >= skill.unlock_level

func is_learned(skill_id: String) -> bool:
	return int(learned.get(skill_id, 0)) > 0

func get_skill_level(skill_id: String) -> int:
	return int(learned.get(skill_id, 0))

func can_use_class(skill: ActiveSkillData) -> bool:
	# 通用技能（class_id="" ）所有人都能用；带职业的只有匹配职业能用
	return skill.class_id.is_empty() or skill.class_id == class_id

func cooldown_remaining(skill_id: String) -> float:
	return float(_cd.get(skill_id, 0.0))

# 释放：检查冷却 + MP + 解锁 + 学习状态 + 职业。返回是否成功。
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
