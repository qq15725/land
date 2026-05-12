extends Node

# 技能系统：4 个技能（farming / mining / woodcutting / combat）
# 监听 EventBus 信号自动加 xp；玩家可通过 K 键查看面板。
# 升级公式：xp_to_next(level) = base_xp * (level + 1) ^ growth

const CONFIG_PATH := "res://data/skills.json"

# 资源 id → 技能 id 映射（决定采集树/石/矿等的 xp 归属）
const RESOURCE_TO_SKILL: Dictionary = {
	"tree": "woodcutting",
	"stone": "mining",
	"iron_ore": "mining",
	"berry_bush": "farming",
	"mushroom": "farming",
}

var _defs: Dictionary = {}    # id → SkillData
var _xp: Dictionary = {}      # id → int（累计 xp）

func _ready() -> void:
	_load_config()
	for id in _defs:
		_xp[id] = 0

	EventBus.resource_depleted.connect(_on_resource_depleted)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.creature_killed.connect(_on_creature_killed)

# ─── 加分 ────────────────────────────────────────────────────────────────────

func add_xp(skill_id: String, amount: int) -> void:
	if not _defs.has(skill_id) or amount <= 0:
		return
	var before := get_level(skill_id)
	_xp[skill_id] = int(_xp.get(skill_id, 0)) + amount
	var after := get_level(skill_id)
	if after > before:
		EventBus.skill_leveled_up.emit(skill_id, after)

func _on_resource_depleted(node: Node) -> void:
	if node == null:
		return
	var rid: String = node.get("resource_id") if node else ""
	var skill_id: String = RESOURCE_TO_SKILL.get(rid, "")
	if skill_id.is_empty():
		return
	add_xp(skill_id, 10)

func _on_crop_harvested(_crop: CropData) -> void:
	add_xp("farming", 25)

func _on_creature_killed(creature: CreatureData) -> void:
	if creature == null:
		return
	# 怪物 xp 与怪物血量挂钩，强敌给得多
	var amount := int(creature.max_health * 0.5)
	add_xp("combat", maxi(5, amount))

# ─── 查询 ────────────────────────────────────────────────────────────────────

func get_xp(skill_id: String) -> int:
	return int(_xp.get(skill_id, 0))

func get_level(skill_id: String) -> int:
	var def: SkillData = _defs.get(skill_id)
	if def == null:
		return 0
	var xp := get_xp(skill_id)
	var lvl := 0
	while lvl < def.max_level and xp >= xp_to_reach(skill_id, lvl + 1):
		lvl += 1
	return lvl

func xp_to_reach(skill_id: String, target_level: int) -> int:
	var def: SkillData = _defs.get(skill_id)
	if def == null or target_level <= 0:
		return 0
	# 累积公式：sum_{i=1..target} base_xp * i^growth
	var total := 0.0
	for i in range(1, target_level + 1):
		total += float(def.base_xp) * pow(float(i), def.growth)
	return int(total)

func get_progress(skill_id: String) -> Dictionary:
	var def: SkillData = _defs.get(skill_id)
	if def == null:
		return {}
	var xp := get_xp(skill_id)
	var lvl := get_level(skill_id)
	var current_floor := xp_to_reach(skill_id, lvl)
	var next_required := xp_to_reach(skill_id, lvl + 1) if lvl < def.max_level else current_floor
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

func get_all_skills() -> Array:
	return _defs.values()

func get_skill(id: String) -> SkillData:
	return _defs.get(id)

# 等级带来的额外掉落概率（粗暴：每级 +1.5%）
func bonus_drop_chance(skill_id: String) -> float:
	return get_level(skill_id) * 0.015

# ─── 数据 ────────────────────────────────────────────────────────────────────

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var result: Variant = JSON.parse_string(file.get_as_text())
	if result == null:
		return
	for d in (result as Array):
		var sd := SkillData.new()
		sd.id = d.get("id", "")
		sd.display_name = d.get("display_name", "")
		var g: Array = d.get("icon_grid", [0, 0])
		sd.icon_grid = Vector2i(int(g[0]), int(g[1]))
		sd.base_xp = int(d.get("base_xp", 100))
		sd.growth = float(d.get("growth", 1.5))
		sd.max_level = int(d.get("max_level", 20))
		_defs[sd.id] = sd

# ─── 存档 ────────────────────────────────────────────────────────────────────

func export_state() -> Dictionary:
	return _xp.duplicate()

func import_state(data: Dictionary) -> void:
	for id in _defs:
		_xp[id] = int(data.get(id, 0))

func reset() -> void:
	for id in _defs:
		_xp[id] = 0
