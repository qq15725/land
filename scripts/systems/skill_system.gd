extends Node

# 技能配置注册表（G4 拆分后）。
#
# 只保留：
# - skill 定义（base_xp / growth / max_level 等），从 data/skills.json 加载
# - 升级公式 xp_to_reach()
#
# 实际数据（_xp 字典 / 等级 / 进度）下沉到 PlayerSkills 组件，挂在每个 Player
# 节点上，多人下每个玩家独立。

const CONFIG_PATH := "res://data/skills.json"

# 资源 id → 技能 id 映射（PlayerSkills 通过本字典反查"砍这个资源给哪个技能加 xp"）
const RESOURCE_TO_SKILL: Dictionary = {
	"tree": "woodcutting",
	"stone": "mining",
	"iron_ore": "mining",
	"berry_bush": "farming",
	"mushroom": "farming",
}

var _defs: Dictionary = {}    # id → SkillData

func _ready() -> void:
	_load_config()

# ─── 查询 ────────────────────────────────────────────────────────────────

func get_skill(id: String) -> SkillData:
	return _defs.get(id)

func get_all_skills() -> Array:
	return _defs.values()

func has_skill(id: String) -> bool:
	return _defs.has(id)

func xp_to_reach(skill_id: String, target_level: int) -> int:
	var def: SkillData = _defs.get(skill_id)
	if def == null or target_level <= 0:
		return 0
	# 累积公式：sum_{i=1..target} base_xp * i^growth
	var total := 0.0
	for i in range(1, target_level + 1):
		total += float(def.base_xp) * pow(float(i), def.growth)
	return int(total)

# ─── 数据加载 ────────────────────────────────────────────────────────────

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
