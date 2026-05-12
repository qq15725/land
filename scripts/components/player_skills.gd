class_name PlayerSkills
extends Node

# 玩家技能组件（G4）。
#
# 数据从 SkillSystem autoload 下沉到这个组件，挂在每个 Player 节点上。
# 多人模式下每个玩家有自己的 _xp / 等级。SkillSystem autoload 只保留配置
# （base_xp / growth / max_level）和升级公式。

var _xp: Dictionary = {}   # skill_id → int

func _ready() -> void:
	for sd in SkillSystem.get_all_skills():
		_xp[sd.id] = 0
	# 只监听 server，client 端不重复加 xp（server 同步状态过来即可）
	if Network.is_server():
		EventBus.resource_depleted.connect(_on_resource_depleted)
		EventBus.crop_harvested.connect(_on_crop_harvested)
		EventBus.creature_killed.connect(_on_creature_killed)

# ─── 加分 ────────────────────────────────────────────────────────────────

func add_xp(skill_id: String, amount: int) -> void:
	if amount <= 0 or not SkillSystem.has_skill(skill_id):
		return
	var before := get_level(skill_id)
	_xp[skill_id] = int(_xp.get(skill_id, 0)) + amount
	var after := get_level(skill_id)
	if after > before:
		EventBus.skill_leveled_up.emit(skill_id, after)

func _on_resource_depleted(resource_id: int, player_id: int) -> void:
	if player_id != NetworkRegistry.get_id(get_parent()):
		return
	var node := NetworkRegistry.get_node_by_id(resource_id)
	if node == null:
		return
	var rid: String = node.get("resource_id") if node else ""
	var sid: String = SkillSystem.RESOURCE_TO_SKILL.get(rid, "")
	if sid.is_empty():
		return
	add_xp(sid, 10)

func _on_crop_harvested(_crop: CropData, player_id: int) -> void:
	if player_id != NetworkRegistry.get_id(get_parent()):
		return
	add_xp("farming", 25)

func _on_creature_killed(creature: CreatureData, player_id: int) -> void:
	if creature == null or player_id != NetworkRegistry.get_id(get_parent()):
		return
	var amount := int(creature.max_health * 0.5)
	add_xp("combat", maxi(5, amount))

# ─── 查询 ────────────────────────────────────────────────────────────────

func get_xp(skill_id: String) -> int:
	return int(_xp.get(skill_id, 0))

func get_level(skill_id: String) -> int:
	var def: SkillData = SkillSystem.get_skill(skill_id)
	if def == null:
		return 0
	var xp := get_xp(skill_id)
	var lvl := 0
	while lvl < def.max_level and xp >= SkillSystem.xp_to_reach(skill_id, lvl + 1):
		lvl += 1
	return lvl

func get_progress(skill_id: String) -> Dictionary:
	var def: SkillData = SkillSystem.get_skill(skill_id)
	if def == null:
		return {}
	var xp := get_xp(skill_id)
	var lvl := get_level(skill_id)
	var current_floor := SkillSystem.xp_to_reach(skill_id, lvl)
	var next_required := SkillSystem.xp_to_reach(skill_id, lvl + 1) if lvl < def.max_level else current_floor
	var into := xp - current_floor
	var span := maxi(1, next_required - current_floor)
	return {
		"xp": xp,
		"level": lvl,
		"into_level": into,
		"span": span,
		"ratio": float(into) / float(span),
		"max_level": lvl >= def.max_level,
	}

# 等级带来的额外掉落概率（每级 +1.5%）
func bonus_drop_chance(skill_id: String) -> float:
	return get_level(skill_id) * 0.015

# ─── 存档 ────────────────────────────────────────────────────────────────

func export_state() -> Dictionary:
	return _xp.duplicate()

func import_state(data: Dictionary) -> void:
	for sd in SkillSystem.get_all_skills():
		_xp[sd.id] = int(data.get(sd.id, 0))

func reset() -> void:
	for sd in SkillSystem.get_all_skills():
		_xp[sd.id] = 0
