class_name ActiveSkillData
extends Resource

# 主动技能数据。所有战斗动作都走这套数据（包括基础挥砍）。
# 新技能：增 JSON 一条 → 不改任何代码。
# 4 种形状原型覆盖 95% 情况：fan / circle / rect / projectile。

# ─── 标识 ──────────────────────────────────────────────────────────────
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_grid: Vector2i = Vector2i.ZERO  # 复用 items icons.png 格子

# ─── 学习与职业 ────────────────────────────────────────────────────────
@export var class_id: String = ""              # "" = 通用；"warrior"/"mage" 等
@export var unlock_level: int = 1              # 总等级阈值
@export var parent_skill_id: String = ""       # 技能树前置节点（"" = 根）
@export var max_level: int = 1                 # 技能多级时该值 > 1
@export var sp_cost: int = 1                   # 每级消耗的技能点

# ─── 释放消耗 ──────────────────────────────────────────────────────────
@export var mp_cost: float = 0.0
@export var cooldown: float = 0.0

# ─── 形状与判定 ────────────────────────────────────────────────────────
# shape:
#   "fan"        — 朝施法方向的扇形（近战挥砍）。shape_size = 半径，shape_angle = 张角（度）
#   "circle"     — 以施法者为中心的圆（自身 AOE）。shape_size = 半径
#   "rect"       — 朝施法方向的矩形（突刺）。shape_size = 长度，shape_angle = 宽度
#   "projectile" — 直线弹道场景。shape_size = 最大飞行距离
@export var shape: String = "fan"
@export var shape_size: float = 40.0
@export var shape_angle: float = 90.0
@export var projectile_scene: String = ""

# ─── 多段命中（核心爽感） ─────────────────────────────────────────────
# hit_ticks 长度 = hit_damage_ratios 长度。
# 单段技能：hit_ticks = [0.0], hit_damage_ratios = [1.0]
@export var base_damage: float = 15.0
@export var hit_ticks: Array = [0.0]            # 每段命中时间点（秒）
@export var hit_damage_ratios: Array = [1.0]    # 每段伤害占 base_damage 的比例

# ─── 视觉与手感 ────────────────────────────────────────────────────────
# vfx_id 对应 scenes/vfx/{vfx_id}.tscn。空 = 不出释放特效（弹道场景自带视觉）。
# 命中飘字/火花共用全局 hit_vfx_id 由 SkillExecutor 控制。
@export var vfx_id: String = ""
@export var vfx_color: Color = Color(1, 1, 1, 0.7)
@export var screen_shake: float = 2.0
@export var hit_stop_ms: int = 50
@export var knockback: float = 200.0

# 玩家动画状态机切换（PlayerAnimState）
# cast_fan / cast_circle / cast_rect / cast_projectile / "" = 不切
@export var anim_state: String = ""
@export var anim_duration: float = 0.3
