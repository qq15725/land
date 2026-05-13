class_name ClassData
extends Resource

# 玩家职业数据。决定可学习的技能集合 + 基础 stat 调整。
# class_id="" 视为通用职业（无加成，可学通用技能）。

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_grid: Vector2i = Vector2i.ZERO    # 复用 items icons.png 格子
@export var hp_bonus: float = 0.0                  # 加在 HealthComponent.max_health 上
@export var mp_bonus: float = 0.0                  # 加在 ManaComponent.max_mana 上
@export var mp_regen_bonus: float = 0.0            # 加在 ManaComponent.regen_per_sec 上
