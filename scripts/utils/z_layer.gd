class_name ZLayer
extends RefCounted

# 全局 z_index 常量表，避免 magic number 散落各处。
# Y-sort 节点本身按 y 排序，z_index 用于覆盖 / 强制层级。
#
# 数值越小越靠后，越大越靠前。常用规则：
#   - 阴影：要在角色脚下 → -1
#   - 世界默认：0（地砖、实体）
#   - 地面 VFX（光圈、范围圈）：5
#   - 飞行 VFX（弹道、施法光球）：10
#   - 受击粒子 / 命中闪光：12
#   - 伤害飘字：50（高于实体，低于 UI 弹窗）
#   - UI 弹窗（升级 / 通知）：100

const SHADOW: int = -1
const WORLD: int = 0
const VFX_GROUND: int = 5
const VFX_AIR: int = 10
const VFX_HIT: int = 12
const DAMAGE_TEXT: int = 50
const UI_DIALOG: int = 100
