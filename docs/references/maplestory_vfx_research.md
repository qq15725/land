# MapleStory VFX 视觉规律调研

> 用途：为 Land 项目升级技能打击特效（从 Polygon2D 占位 → 冒险岛"汁水感"打击）提供可直接照抄的颜色、粒子、毫秒数。
> 来源：maplestory.fandom.com 各技能页 + 玩家社区视频/截图描述 + 论坛讨论。**部分参数为视频截图反推+主观估算**，已在条目中标注。

## 0. TL;DR 核心结论

冒险岛特效的"汁水感"不是来自单一技巧，而是 5 件事叠加：

1. **三层色（核心-中层-外圈）的色板高对比** — 内核近白，外圈深色透明，中层是元素主色。
2. **闪白预警帧 + 命中冻屏** — 打击瞬间 1-2 帧把目标贴图替换为纯白剪影，再冻 50-80ms。
3. **粒子飞溅 = 大量小颗粒 + 短拖尾 + 重力衰减** — 不是一个大爆炸，而是 20-40 个小光点。
4. **飘字大、字距密、有外描边** — 暴击 = 红+黄渐变+稍大；普通 = 纯白；MISS = 灰白小字。
5. **屏幕震动微弱但持续** — 大招才用力度大的屏震，普通技能只有 2-3px 抖动。

---

## 1. 元素分类视觉规律（含 HEX）

> HEX 值取自 fandom 技能页截图与 YouTube 演示视频反推。**冒险岛官方没有公开色板文档**，下表为视觉采样估算。

### 1.1 火元素（Fire Arrow / Meteor Shower / Flame Gear）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FFF4CC` | 高亮光斑，几乎纯白带黄 |
| 中层 | `#FF8A1F` | 火焰主体橙红 |
| 外圈 | `#B22A05` | 深红边缘 |
| 烟尘 | `#3B1A0A66` | 末段灰黑烟（带透明）|

视觉特征：上升火星 + 重力下落火花 + 命中地面留 0.3s 灼烧贴图（脉冲黄红）。陨石技拖尾 = 白心橙边的长椭圆。

### 1.2 冰元素（Ice Strike / Cold Beam / Blizzard）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FFFFFF` | 纯白冰晶高光 |
| 中层 | `#9BE7FF` | 浅蓝主色 |
| 外圈 | `#2D6FB8` | 蓝紫深边 |
| 雪粉 | `#E6F8FFCC` | 雪花/雾气 |

视觉特征：菱形/六边形冰晶贴图 + 缓慢飘落的雪粉 + 命中后目标贴半透明蓝色"冻结"覆盖层。Blizzard 大招会先落下一根深蓝色冰柱，落地碎裂成 12-18 个白色冰片。

### 1.3 雷电（Thunder Bolt / Chain Lightning）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FFFFFF` | 闪电主线，几乎过曝白 |
| 中层 | `#FFF66D` | 黄色光晕 |
| 外圈 | `#7C4DFF` | 紫色辉光（标志色）|
| 残光 | `#B388FF66` | 紫色残辉 |

视觉特征：之字形折线贴图，每帧 jitter 顶点 ±4px。Chain Lightning 命中后会有 0.1s 全屏轻微紫色色温偏移。

### 1.4 毒（Poison Mist / Poison Brace）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#D9FF73` | 黄绿亮心 |
| 中层 | `#5BB31E` | 主体绿 |
| 外圈 | `#1F4D14` | 暗绿边缘 |
| 紫晕 | `#7A1FA2` | 个别毒系（如 Paralyze）带紫调 |

视觉特征：低速上升的气泡 + 大块半透明云贴图。Poison Mist 是一片缓慢翻涌的绿雾，不是闪光型粒子。气泡破裂时短暂放亮。

### 1.5 暗影（Dark Sight / Shadow Partner / Assassinate）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FF1744` | 血红高光（关键标识色）|
| 中层 | `#1A001A` | 近黑紫 |
| 外圈 | `#000000CC` | 纯黑半透明 |
| 残影 | `#33001A99` | 暗紫残影 |

视觉特征：黑色烟雾爆开 + 红色十字/星形光点。Assassinate 命中目标会闪过血红色"X"印记。Shadow Partner 影子是半透明黑色叠加，并非新角色贴图。社区反馈新版"红黑"过于刺眼，证实主色就是红黑双色。

### 1.6 圣光（Heal / Bless / Holy Charge）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FFFFFF` | 纯白光斑 |
| 中层 | `#FFE57F` | 暖金黄 |
| 外圈 | `#FFB300` | 橙金边缘 |
| 光柱 | `#FFF8E1AA` | 半透明垂直光柱 |

视觉特征：从地面/角色头顶向上的垂直光柱 + 缓慢上升的羽毛/十字小粒子 + 范围内角色头顶冒一圈圆形光圈。Bless 会有持续 1.5s 的金色脉冲圈。

### 1.7 物理近战（Power Strike / Slash Blast）

| 层级 | HEX | 用途 |
|---|---|---|
| 内核 | `#FFFFFF` | 弧光主体 |
| 中层 | `#E0E0E0` | 银灰光带 |
| 外圈 | `#9E9E9E` | 灰边 |
| 命中爆点 | `#FFD740` | 黄色火花（碰撞瞬间）|

视觉特征：白色月牙形弧光 + 命中点撒 5-8 个黄色火花 + 短促径向冲击波（白心黑边的圆）。Slash Blast 比 Power Strike 弧光更长更宽。

---

## 2. 通用视觉规律（8 条工程化要点）

### 2.1 闪白预警帧（"hit flash"）
- 命中瞬间，把目标 sprite shader 整体替换为纯白 `#FFFFFF`，持续 **2 帧（约 33ms @60fps）**，再恢复。
- 这是冒险岛"打到了"最核心的视觉反馈。**Godot 实现**：给 Sprite2D 加 shader，开启 `flash_amount` uniform，命中时 tween 0→1→0。

### 2.2 hit-stop（命中冻屏）
- 普通技能：**40-60ms** 全游戏时间暂停（玩家、怪物、特效一起停）。
- 暴击：**80-120ms**。
- 大招命中：**150-200ms**。
- 估算（无官方数据）：观察 YouTube 高帧率视频反推。冒险岛实际更倾向短冻屏 + 长 hit flash 组合。

### 2.3 屏震幅度
- 普通近战：**2-3px**，持续 80ms，频率约 30Hz。
- 火/雷/冰大招：**5-7px**，持续 150ms。
- Boss 终结大招（Meteor / Blizzard）：**8-12px**，持续 250ms + 后续 0.5s 的低频残震。
- 估算：玩家论坛多次反馈"屏震太强导致头晕"，可印证大招屏震幅度不低。

### 2.4 残影 / 拖尾
- 角色动作残影：**3-5 帧**之前的姿态半透明叠加（alpha 30% → 0%），淡出 100ms。
- 投射物拖尾（火球/冰锥/电球）：粒子拖尾发射 + 每 16ms 复制一份当前 sprite 做衰减。
- **不用 LineRenderer**，而是用"上一帧 sprite 残留"模拟。

### 2.5 飘字（Damage Number）
- 默认色板：
  - **普通命中**：橙黄 `#FFB300`，外描边深棕 `#5A2A00`，字号基准 24px。
  - **暴击**：纯红 `#FF1744` → 黄 `#FFEB3B` 垂直渐变，描边黑色，字号 **+30%**（约 31px），命中瞬间放大到 130% 再回弹到 100%（持续 80ms）。
  - **MISS**：灰白 `#E0E0E0`，字号 -20%（19px），无描边。
- 上升动画：从命中点上抛 18-24px，0.6s 内淡出，带 ±10px 横向随机偏移避免堆叠。
- 字距密集，字符之间几乎贴着（letter_spacing -1）。

### 2.6 "COMBO ×N" 飘字
- 屏幕中央偏上位置（约 30% 高度处）。
- 字号大（基准 36px），COMBO 文字白色 `#FFFFFF` + 数字金色 `#FFD740`。
- 每次连击数字弹跳放大（120% → 100%，80ms 弹性曲线）。
- 中断阈值：**1.5-2 秒**无命中即清零，清零时整串飘字向上飘出并淡出。

### 2.7 大招 vs 普通技能视觉差异
| 维度 | 普通技能 | 大招 |
|---|---|---|
| 粒子数量 | 8-16 | 40-80 |
| 持续时间 | 0.3-0.5s | 1.0-2.5s |
| 屏震 | 2-3px | 8-12px |
| hit-stop | 50ms | 200ms |
| 全屏色温 | 无 | 大招瞬间贴半透明色块（火=橙、冰=蓝、雷=紫），alpha 15-25%，持续 100ms |
| 镜头 | 不变 | zoom in 5%（80ms 内）再 zoom out |

### 2.8 命中收尾"火花"
不管什么元素，命中点都会有一组"白色/元素主色火花"小颗粒（4-8 个）以径向散开，速度 100-150px/s，生命周期 200ms，从 size 4 → 0。**这是统一的"打到了"反馈层**，叠在元素特效之上。

---

## 3. 粒子配方（Godot 4 CPUParticles2D）

> 单位说明：速度 px/s，生命 s，角度 °。`color_ramp` 三色按时间均分。

### Fire（火球命中爆炸 / Fire Arrow）
```
amount: 28
lifetime: 0.55
explosiveness: 0.85
initial_velocity_min: 80
initial_velocity_max: 160
direction: Vector2(0, -1)    # 主要向上
spread: 75
gravity: Vector2(0, 220)      # 火星掉落
color_ramp: #FFF4CC → #FF8A1F → #B22A0500
scale_curve: 1.0 → 1.2 → 0.0
scale_amount: 5
angular_velocity_min: -180
angular_velocity_max: 180
emission_shape: SPHERE radius 4
# glow: 开启 CanvasItem material 的 add 混合模式
```

### Ice（冰锥命中 / Cold Beam）
```
amount: 22
lifetime: 0.7
explosiveness: 0.7
initial_velocity_min: 50
initial_velocity_max: 120
direction: Vector2(0, -1)
spread: 90
gravity: Vector2(0, 60)       # 雪粉缓降
color_ramp: #FFFFFF → #9BE7FF → #2D6FB800
scale_curve: 0.4 → 1.0 → 0.0
scale_amount: 6
angular_velocity_min: -90
angular_velocity_max: 90
emission_shape: SPHERE radius 6
# 建议同时叠一层"冻结"贴图：目标身上覆盖 #9BE7FFAA 半透明色，持续 0.8s
```

### Lightning（雷击命中）
```
amount: 18
lifetime: 0.35
explosiveness: 1.0           # 一次性爆发
initial_velocity_min: 140
initial_velocity_max: 240
direction: Vector2(0, 0)      # 全向
spread: 180
gravity: Vector2.ZERO
color_ramp: #FFFFFF → #FFF66D → #7C4DFF00
scale_curve: 1.0 → 0.6 → 0.0
scale_amount: 4
angular_velocity_min: -360
angular_velocity_max: 360
# 主体闪电用 Line2D 折线，每 16ms 重新生成顶点；粒子只是辉光
# 全屏色温：100ms 内叠 #7C4DFF 半透明 alpha 0.15
```

### Poison（毒雾）
```
amount: 14
lifetime: 1.4
explosiveness: 0.1            # 持续吐
initial_velocity_min: 20
initial_velocity_max: 50
direction: Vector2(0, -1)
spread: 40
gravity: Vector2(0, -10)      # 缓慢上升
color_ramp: #D9FF7333 → #5BB31E66 → #1F4D1400
scale_curve: 0.6 → 1.4 → 1.0
scale_amount: 14              # 颗粒大
angular_velocity_min: -30
angular_velocity_max: 30
# 不要叠加发光，毒雾是雾不是火
```

### Shadow（暗影爆击 / Assassinate）
```
amount: 32
lifetime: 0.5
explosiveness: 0.95
initial_velocity_min: 100
initial_velocity_max: 200
direction: Vector2(0, 0)
spread: 180
gravity: Vector2(0, 80)
color_ramp: #FF1744 → #1A001A → #00000000
scale_curve: 1.2 → 0.8 → 0.0
scale_amount: 5
angular_velocity_min: -270
angular_velocity_max: 270
# 命中后额外叠一个红色"X"或十字光斑贴图，持续 150ms
```

### Holy（圣光治疗 / Bless）
```
amount: 20
lifetime: 1.0
explosiveness: 0.3
initial_velocity_min: 30
initial_velocity_max: 70
direction: Vector2(0, -1)
spread: 25
gravity: Vector2(0, -20)      # 向上飘
color_ramp: #FFFFFF → #FFE57F → #FFB30000
scale_curve: 0.4 → 1.0 → 0.0
scale_amount: 6
angular_velocity_min: -45
angular_velocity_max: 45
emission_shape: SPHERE radius 16   # 范围光环
# 同时叠一根垂直光柱 sprite：#FFF8E1, alpha 0.6, 0.8s fade
# glow: add 混合 + 加 light2d 短脉冲（150ms）
```

### Physical Melee（Power Strike / Slash Blast）
```
amount: 10
lifetime: 0.25
explosiveness: 1.0
initial_velocity_min: 120
initial_velocity_max: 200
direction: 攻击方向（动态）
spread: 35                   # 窄锥
gravity: Vector2(0, 200)
color_ramp: #FFFFFF → #FFD740 → #9E9E9E00
scale_curve: 1.0 → 0.5 → 0.0
scale_amount: 4
# 主特效是一张白色月牙刀光 sprite，0.18s 内 alpha 1→0，旋转 ±15°
# 命中点叠 1 张径向冲击波 sprite（白心黑边的圆环），scale 0.3→1.5，alpha 1→0，120ms
```

---

## 4. 实施优先级建议（针对 Land 项目）

1. **先做通用层**：hit flash（白色 shader）+ hit-stop（Engine.time_scale 临时改 0）+ 飘字（红/黄/白三色）。这三件是 80% 的"汁水感"。
2. **再做粒子层**：按上面 7 个元素配方建 CPUParticles2D 预制体，挂到 `scenes/effects/`，按技能 element 字段动态实例化。
3. **最后做高级层**：屏震（Camera2D shake）、镜头 zoom、全屏色温（CanvasModulate 短暂染色）、COMBO 飘字。
4. **不建议照搬**的部分：冒险岛的 Luminous 大量闪烁动画引发玩家投诉过，2D 飘字也常被批太密，做 Land 时建议把闪频降低 30%，降低视觉疲劳。

---

## 5. 数据置信度

| 数据项 | 置信度 | 说明 |
|---|---|---|
| 各元素三层 HEX | 中 | 视频/截图采样反推，非官方色卡 |
| hit-stop 毫秒 | 低 | 无公开数据，YouTube 帧分析估算 |
| 屏震幅度 | 低 | 论坛玩家描述反推 |
| 飘字色（橙/红/白） | 高 | 官方确认默认色 |
| 暴击 vs 普通区分 | 高 | 官方文档：暴击红、普通橙 |
| MISS 显示 | 高 | 官方：默认皮肤无 MISS，自定义皮肤才显示 |
| 粒子数量/速度 | 低 | 视觉经验估算，需在 Godot 中迭代调参 |
| Shadow 红黑色 | 中 | 玩家论坛"red and black"描述印证 |
| Poison 绿色（非紫）| 高 | 官方/玩家共识 Poison Mist 为绿，Paralyze 才偏紫 |

---

## 6. 参考来源

- [Meteor Shower | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Meteor_Shower)
- [Cold Beam | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Cold_Beam)
- [Chain Lightning | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Chain_Lightning)
- [Poison Mist | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Poison_Mist)
- [Shadow Partner | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Shadow_Partner)
- [Bishop/Skills | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Bishop/Skills)
- [Damage Skin | MapleWiki | Fandom](https://maplestory.fandom.com/wiki/Damage_Skin)
- [Shadow Partner Effect | Orange Mushroom's Blog](https://orangemushroom.net/2022/01/06/kmst-ver-1-2-134-adventure-remaster/shadow-partner-effect/)
- [Thoughts on Maple's Combat? | Official Forums](https://forums.maplestory.nexon.net/discussion/24327/thoughts-on-maples-combat)
- [Luminous Annoying Flashing Animation | Official Forums](https://forums.maplestory.nexon.net/discussion/1117/luminous-annoying-flashing-animation-since-177-1)
- [Default damage skin lacks "MISS" | Official Forums](https://forums.maplestory.nexon.net/discussion/4450/default-damage-skin-lacks-miss)
- [Suggestions on shadower（dark sight）feel | MapleRoyals](https://mapleroyals.com/forum/threads/suggestions-on-shadower%EF%BC%88dark-sight%EF%BC%89feel.184123/)
- [Some MapleStory damage skins! | Ecency](https://ecency.com/hive-140217/@lilacse/some-maplestory-damage-skins)
- [Make Paralyze purple | Dream Forum](https://forum.dream.ms/threads/make-paralyze-purple.7476/)
- [List of MapleStory's Damage Skins | luciasdeco](https://luciasdeco.wordpress.com/2020/09/07/misc-list-of-maplestorys-damage-skins-until-v216/)
