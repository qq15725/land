## 美术：VFX 战斗特效

战斗系统由 `VFXLibrary` autoload 统一分发，所有特效场景放在 **`scenes/vfx/{vfx_id}.tscn`** 路径下，按 `vfx_id` 查询加载。

**当前状态**：所有 VFX 用 `vfx_geom.gd` 通用脚本以 `Polygon2D + Tween` 代码生成几何形状作为**占位**，方便迭代。需要正式美术时按本文档替换。

---

## 接入约定（强制）

每个 VFX 场景必须满足：

| 要求 | 说明 |
|------|------|
| 根节点类型 | `Node2D`（或子类） |
| 路径 | `scenes/vfx/{vfx_id}.tscn`，文件名即 vfx_id |
| 实现方法 | `setup(color: Color, scale_v: Vector2) -> void`（可选，用于运行时调色/缩放） |
| 自销毁 | `_ready()` 内启动 Tween / Timer，结束后 `queue_free()` |
| z_index | 用 `ZLayer` 常量；不要写 magic number |
| 鼠标穿透 | 任何子节点不要拦截 input |

**美术替换流程**：

1. 出 spritesheet 或粒子参数
2. 新建 `.tscn`，挂自定义脚本（继承 Node2D，覆盖 `setup`）
3. 不改任何调用方代码 —— `VFXLibrary.spawn(vfx_id, ...)` 自动加载新场景

---

## 当前 VFX 清单

| vfx_id | 用途 | 占位实现 | 调用方 |
|--------|------|---------|--------|
| `melee_fan` | 近战扇形挥砍 | `vfx_geom` shape=fan, 44 半径, 90° | basic_swing / triple_slash |
| `aoe_circle` | 自身周围 AOE 圆形冲击 | `vfx_geom` shape=circle, 64 半径 | whirlwind |
| `melee_rect` | 突刺 / 长矛矩形冲击 | `vfx_geom` shape=rect, 60×24 | 待用 |
| `hit_spark` | 命中火花（小爆点） | `vfx_geom` shape=spark, 18 半径 | SkillExecutor 命中时 + Fireball 爆炸时 |
| `projectile_trail` | 弹道尾迹 | `vfx_geom` shape=trail, 8 半径 | 待用 |
| `levelup_burst` | 技能升级（金色光环） | `vfx_geom` shape=circle, 80 半径 / 0.55s / scale 1.8 | `VFXEventRouter._on_leveled_up` |
| `equip_glow` | 装备变更（金白火花） | `vfx_geom` shape=spark, 24 半径 / 0.3s | `Player._on_equipment_changed` |
| `harvest_pop` | 收获作物（绿色弹跳） | `vfx_geom` shape=spark, 16 半径 / 0.25s | `VFXEventRouter._on_crop_harvested` |
| `place_dust` | 建造放置（棕灰尘环） | `vfx_geom` shape=circle, 36 半径 / 0.4s / scale 1.6 | `VFXEventRouter._on_building_placed` |
| `projectile_fire` | 火球 / 火属性弹道 | `vfx_geom` shape=trail / 橙红核心 + ember 粒子 + flash 0.5 | 火系技能（fireball / fire_arrow / meteor_strike） |
| `projectile_arrow` | 箭矢 / 弓系弹道 | `vfx_geom` shape=trail / 白银锋利 + 短尾迹 + flash 0.25 | 弓系技能（arrow_blow / piercing_arrow / gatling_burst） |
| `lightning` | 雷电命中 | `vfx_geom` shape=spark / 白核 + 紫色辉光粒子 + flash 1.0 | chain_lightning / thunder |
| `ice` | 冰冻光环 | `vfx_geom` shape=circle / 浅蓝半透明 + 冰晶粒子 + flash 0.7 | ice_storm / blizzard / time_stop |
| `poison` | 毒雾扩散 | `vfx_geom` shape=circle / 黄绿亮心 + 缓动气泡 + flash 0.35 | poison_blade / venom |
| `shadow` | 暗影爆击 | `vfx_geom` shape=circle / 黑紫核心 + 血红粒子 + flash 0.5 | assassinate / shadow_clone / dark_sight |
| `fire_blast` | 大型爆发 | `vfx_geom` shape=circle / 橙红核心 + 全向 ember 飞溅 + flash 0.95 | berserk / battleship_call / war_cry / ground_slash |

---

## 美术资产规格（替换占位时使用）

> 所有 VFX 都需要支持代码 `modulate` 染色。**原图主体必须是中性白/灰**，技能颜色由调用方传入。

### `melee_fan.png` — 近战挥砍轨迹

| 项 | 值 |
|---|---|
| 源单帧 | 128×128 px |
| 帧数 | 6 |
| 总尺寸 | 768×128 px（横排） |
| 锚点 | 单帧左中（0, 64），代码自动旋转到玩家朝向 |
| 设计 | 扇形挥砍 trail，从厚到淡，最后一帧近全透明 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 6 frames in a horizontal strip, each frame 128x128 pixels,
total 768x128 pixels. Strict grid, no padding.
Subject: a fan-shaped slash trail sweeping in an arc, anchored at the left-center
of each frame, expanding outward to the right. Frame 0: thin initial slash.
Frame 1-3: full thick crescent slash with motion blur lines.
Frame 4-5: fading dissipating slash with thin trailing lines.
Pure white/light grey color so it can be tinted in-engine.
Transparent background, hard pixel edges, no smooth gradients, no anti-aliasing,
no realistic rendering, no scene, no text.
```

### `aoe_circle.png` — 圆形冲击波

| 项 | 值 |
|---|---|
| 源单帧 | 192×192 px |
| 帧数 | 6 |
| 总尺寸 | 1152×192 px |
| 锚点 | 单帧中心 |
| 设计 | 圆环从中心扩散，第 1-2 帧实心圆，第 3-5 帧空心圆环扩大变薄 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 6 frames in a horizontal strip, each frame 192x192 pixels,
total 1152x192 pixels. Strict grid, no padding.
Subject: a circular shockwave expanding from center. Frame 0: small filled circle.
Frame 1-2: expanding ring becoming hollow. Frame 3-5: hollow ring expanding outward
becoming thinner and fading. Pure white/light grey for in-engine tinting.
Transparent background, hard pixel edges, no anti-aliasing, no realistic rendering,
no scene, no text.
```

### `melee_rect.png` — 突刺矩形冲击

| 项 | 值 |
|---|---|
| 源单帧 | 192×64 px |
| 帧数 | 5 |
| 总尺寸 | 960×64 px |
| 锚点 | 单帧左中（0, 32） |
| 设计 | 沿 X 轴前冲的矩形 trail，前缘最亮，尾部淡出 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 5 frames in a horizontal strip, each frame 192x64 pixels,
total 960x64 pixels. Strict grid, no padding.
Subject: a forward thrust trail extending from left to right within each frame.
Anchored at the left-center. Bright leading edge with fading tail.
Frame 0: short stab beginning at left. Frame 1-2: full-length thrust streak.
Frame 3-4: dissipating tail. Pure white/light grey for in-engine tinting.
Transparent background, hard pixel edges, no anti-aliasing, no scene, no text.
```

### `hit_spark.png` — 命中火花

| 项 | 值 |
|---|---|
| 源单帧 | 64×64 px |
| 帧数 | 4 |
| 总尺寸 | 256×64 px |
| 锚点 | 单帧中心 |
| 设计 | 短促的放射火花，4-6 条短线段从中心向外，闪烁后消失 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 4 frames in a horizontal strip, each frame 64x64 pixels,
total 256x64 pixels. Strict grid, no padding.
Subject: a small impact spark burst, 4-6 short lines radiating from the center.
Frame 0: small bright point. Frame 1: full radial burst. Frame 2: lines extending
outward. Frame 3: faint fading remnants. Pure white/light grey for in-engine tinting.
Transparent background, hard pixel edges, no anti-aliasing, no scene, no text.
```

### `projectile_trail.png` — 弹道尾迹（可选）

| 项 | 值 |
|---|---|
| 源单帧 | 32×32 px |
| 帧数 | 4 |
| 总尺寸 | 128×32 px |
| 锚点 | 单帧中心 |
| 设计 | 小光团逐帧缩小，用于弹道飞行时拖尾 |

---

### `levelup_burst.png` — 升级光环（C6）

| 项 | 值 |
|---|---|
| 源单帧 | 192×192 px |
| 帧数 | 6 |
| 总尺寸 | 1152×192 px |
| 锚点 | 单帧中心，特效会被代码定位到玩家头顶上方 16px |
| 设计 | 一道升级金环从玩家中心扩散，同时若干短光柱向上喷出。Frame 0：中心亮点，准备启动；Frame 1-2：底部出现实心圆 + 放射状光柱向上喷射；Frame 3-4：圆环扩散变薄 + 光柱继续上升变长；Frame 5：仅剩稀疏星粒淡出 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 6 frames in a horizontal strip, each frame 192x192 pixels,
total 1152x192 pixels. Strict grid, no padding.
Subject: a level-up burst effect. Frame 0: a small bright dot at center.
Frame 1-2: a solid circle at the bottom of the cell with 4-6 short vertical
light beams shooting upward from the circle. Frame 3-4: the circle expands into
a hollow ring becoming thinner, and the light beams stretch longer reaching the
top of the cell. Frame 5: only faint sparkles remain, mostly fading out.
Pure white/light grey color so it can be tinted gold in-engine.
Transparent background, hard pixel edges, no anti-aliasing, no realistic rendering,
no scene, no text.
```

---

### `equip_glow.png` — 装备光晕（C6）

| 项 | 值 |
|---|---|
| 源单帧 | 64×64 px |
| 帧数 | 4 |
| 总尺寸 | 256×64 px |
| 锚点 | 单帧中心，代码定位到玩家身体中点 |
| 设计 | 装备瞬间的短促闪光。Frame 0：中心实心亮点；Frame 1：4-6 道短光线放射；Frame 2：环形涟漪扩散一圈；Frame 3：淡出 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 4 frames in a horizontal strip, each frame 64x64 pixels,
total 256x64 pixels. Strict grid, no padding.
Subject: a quick equip-item glow. Frame 0: a solid bright dot at center.
Frame 1: 4-6 short light lines radiating outward in a star pattern.
Frame 2: a thin expanding ring (ripple) replacing the lines.
Frame 3: ring is largest and faintest, almost gone.
Pure white/light grey color for in-engine tinting (will be tinted gold-white).
Transparent background, hard pixel edges, no anti-aliasing, no scene, no text.
```

---

### `harvest_pop.png` — 收获弹跳（C6）

| 项 | 值 |
|---|---|
| 源单帧 | 64×64 px |
| 帧数 | 4 |
| 总尺寸 | 256×64 px |
| 锚点 | 单帧中心偏下（y=48），表现作物从土里被拔出 |
| 设计 | 收获作物时叶片与碎屑向上弹出。Frame 0：底部 1-2 片小叶子开始上跃；Frame 1：叶子上升+外散，加 2-3 颗圆形碎屑；Frame 2：叶子继续旋转上升，间距更大；Frame 3：碎屑稀疏淡出 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 4 frames in a horizontal strip, each frame 64x64 pixels,
total 256x64 pixels. Strict grid, no padding.
Subject: a crop harvest pop effect. Frame 0: 1-2 small leaf shapes at the bottom
center starting to jump up. Frame 1: leaves rising higher and spreading outward,
plus 2-3 small round particles (crop crumbs). Frame 2: leaves rotating, spreading
further, particles drifting up. Frame 3: only a few faint particles remain at the top.
Pure white/light grey color so it can be tinted green in-engine.
Transparent background, hard pixel edges, no anti-aliasing, no scene, no text.
```

---

### `place_dust.png` — 建造尘环（C6）

| 项 | 值 |
|---|---|
| 源单帧 | 192×64 px |
| 帧数 | 5 |
| 总尺寸 | 960×64 px |
| 锚点 | 单帧中心底部（y=56），表现建筑落地接触地面 |
| 设计 | 建筑放置后扬起的扁平尘环。Frame 0：地面一道短粗椭圆；Frame 1：椭圆开始向左右拉长 + 上方零星颗粒；Frame 2：椭圆尘环达到最大（扁平），颗粒上飘最高；Frame 3：尘环薄淡，仅剩颗粒；Frame 4：稀疏颗粒淡出 |

**AI 提示词模板**：

```
Game VFX sprite sheet, 5 frames in a horizontal strip, each frame 192x64 pixels,
total 960x64 pixels. Strict grid, no padding.
Subject: a building placement dust burst on flat ground. Frame 0: a short thick
horizontal ellipse on the ground at center. Frame 1: ellipse stretches wider
horizontally, a few small particles rising above it. Frame 2: ellipse at widest
(flat dust ring), particles floating highest. Frame 3: dust ring thin and fading,
particles still drifting. Frame 4: only sparse particles, mostly faded.
Pure white/light grey color so it can be tinted brown-grey in-engine.
Transparent background, hard pixel edges, no anti-aliasing, no scene, no text.
```

---

## 元素 VFX（冒险岛风格）

冒险岛特效的"汁水感"= **三层色板 + 闪白预警 + 元素粒子 + 飘字 + 微震** 五层叠加。下列 7 个元素 VFX 全部基于 `vfx_geom` 升级版（含 `flash_intensity` + `emit_particles` 粒子层），代码已就绪，下面是**正式美术替换时的提示词**。每个建议出 6 帧横排精灵表（128×128 单帧，总 768×128）。

调研依据：`docs/references/maplestory_vfx_research.md`

### `projectile_fire.png` — 火球弹道

| 项 | 值 |
|---|---|
| 源单帧 | 96×96 px |
| 帧数 | 6 |
| 总尺寸 | 576×96 px |
| 设计 | 横向飞行的火球带 ember 拖尾。frame 0 小火苗，frame 1-3 满状态橘红火球带 4-6 颗黄白火星向后散落，frame 4-5 火球消散仅余 ember |

```
Game VFX sprite sheet, 6 frames horizontal strip, each frame 96x96 pixels, total 576x96.
Subject: a flying fireball moving rightward, with ember particle trail behind.
Core palette: inner #FFF4CC bright yellow-white, mid #FF8A1F orange-red, outer #B22A05 deep red, smoke #3B1A0A.
Frame 0: tiny ignition spark. Frame 1: small fireball with 2 embers trailing.
Frame 2-3: full fireball with 4-6 ember particles streaking back, slight motion blur.
Frame 4: fireball fragmenting, fewer embers. Frame 5: dissipating embers, mostly smoke.
Pixel art, hard edges, transparent background, no scene, no text.
```

### `projectile_arrow.png` — 箭矢拖尾

| 项 | 值 |
|---|---|
| 源单帧 | 96×48 px |
| 帧数 | 4 |
| 总尺寸 | 384×48 px |
| 设计 | 锋利白银箭矢拖尾，速度感 |

```
Game VFX sprite sheet, 4 frames horizontal, each 96x48 pixels.
Subject: a sharp horizontal arrow with white-silver streak trail.
Palette: arrow head #FFFFFF, shaft #E0E0E0, trail #9E9E9EAA fading to transparent.
Frame 0: arrow with short trail. Frame 1: full speed, long thin streak.
Frame 2-3: arrow exits, trail fading rapidly. No scene, transparent, hard pixel edges.
```

### `lightning.png` — 雷击爆点

| 项 | 值 |
|---|---|
| 源单帧 | 128×128 px |
| 帧数 | 5 |
| 总尺寸 | 640×128 px |
| 设计 | 锯齿闪电分支 + 紫色辉光（冒险岛标志） |

```
Game VFX sprite sheet, 5 frames horizontal, each 128x128 pixels.
Subject: lightning strike impact with branching forks.
Palette: inner #FFFFFF over-bright white core, mid #FFF66D yellow halo,
outer #7C4DFF purple aura (MapleStory signature), residual glow #B388FF66.
Frame 0: vertical white lightning bolt with 2 branches. Frame 1: full multi-fork
explosion radiating outward with violet halo. Frame 2: dimmer with afterimage.
Frame 3-4: fading purple residue particles, mostly transparent. Pixel art, transparent bg.
```

### `ice.png` — 冰冻冲击

| 项 | 值 |
|---|---|
| 源单帧 | 128×128 px |
| 帧数 | 6 |
| 总尺寸 | 768×128 px |
| 设计 | 冰晶向外爆开 + 雪粉雾 |

```
Game VFX sprite sheet, 6 frames horizontal, each 128x128 pixels.
Subject: ice burst impact with crystallizing shards.
Palette: core #FFFFFF pure white, mid #9BE7FF pale cyan, outer #2D6FB8 deep blue,
mist #E6F8FFCC translucent snow particles.
Frame 0: small white flash. Frame 1-2: 6-8 jagged ice crystal shards radiating outward,
hexagonal facet shapes, ring of pale cyan mist. Frame 3-4: shards shattering,
snow powder spreading. Frame 5: dissipating mist with a few drifting snowflake pixels.
Pixel art, hard edges, transparent bg.
```

### `poison.png` — 毒雾扩散

| 项 | 值 |
|---|---|
| 源单帧 | 128×128 px |
| 帧数 | 6 |
| 总尺寸 | 768×128 px |
| 设计 | 缓慢上升的毒雾团 + 气泡 |

```
Game VFX sprite sheet, 6 frames horizontal, each 128x128 pixels.
Subject: rising toxic poison mist cloud with bubbles.
Palette: bright core #D9FF73 yellow-green highlight, mid #5BB31E body green,
outer #1F4D14 dark green edge, optional purple accent #7A1FA2 for paralyze.
Frame 0: small bubble cluster at bottom center. Frame 1-2: poison mist cloud
expanding upward with 4-6 bubble particles rising. Frame 3-4: cloud at widest,
sickly green, bubbles popping. Frame 5: cloud thinning, last bubbles drift up.
Pixel art, transparent bg, no realistic smoke.
```

### `shadow.png` — 暗影爆击

| 项 | 值 |
|---|---|
| 源单帧 | 128×128 px |
| 帧数 | 5 |
| 总尺寸 | 640×128 px |
| 设计 | 黑紫吞噬 + 血红高光（冒险岛刺客标志） |

```
Game VFX sprite sheet, 5 frames horizontal, each 128x128 pixels.
Subject: shadow strike impact, black void with blood-red highlight.
Palette: core #FF1744 blood-red highlight (KEY signature color),
mid #1A001A near-black purple, outer #000000CC pure black translucent,
residue #33001A99 dark purple afterimage.
Frame 0: small dark dot with red center spark. Frame 1-2: shadow erupts outward
in jagged tendrils, blood-red core flash, smoky purple edges.
Frame 3-4: tendrils retracting, dissipating into dark purple wisps. Pixel art, transparent bg.
```

### `fire_blast.png` — 大型爆炸（大招用）

| 项 | 值 |
|---|---|
| 源单帧 | 192×192 px |
| 帧数 | 7 |
| 总尺寸 | 1344×192 px |
| 设计 | 大型橙红爆炸 + 全向碎片 + shockwave |

```
Game VFX sprite sheet, 7 frames horizontal, each 192x192 pixels.
Subject: large explosion blast for ultimate skills (berserk / battleship_call / meteor strike).
Palette: core #FFF4CC bright white-yellow, mid #FF8A1F orange-red,
outer #B22A05 deep red, smoke #3B1A0A. Add bright #FFFFFF flash overlay on frame 1.
Frame 0: ignition flash, small intense white core. Frame 1: full white-hot flash overlay
covers most of frame (frame 1 is the brightest). Frame 2-3: full orange-red explosion
with 12+ debris ember particles flying outward, expanding shockwave ring.
Frame 4-5: explosion contracting, debris flying, smoke rising.
Frame 6: residual smoke and a few drifting embers.
Pixel art, hard edges, transparent bg, no scene.
```

### `hit_spark.png`（已有但建议升级为冒险岛风格）

冒险岛"打到了"通用收尾火花。现有 9 个 vfx 已可工作，建议升级正式美术时统一为：

```
Frame 0: white-yellow flash core 4-6 px radius.
Frame 1-2: 6-8 small star-shaped sparks radiating outward, 100-150 px/s speed,
sizes 4 → 2 → 0. Bright #FFD740 yellow when over physical hits,
recolored by engine to element color when over elemental hits.
Frame 3-4: trailing pixels fading. Total 200ms.
```

---

## 替换示例：melee_fan 接入正式美术

替换占位后的目标场景：

```
scenes/vfx/melee_fan.tscn
└── MeleeFan (Node2D, melee_fan_anim.gd)
    └── AnimatedSprite2D (sprite_frames 引用 melee_fan.png 6 帧)
```

`melee_fan_anim.gd`：

```gdscript
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	z_index = ZLayer.VFX_GROUND
	sprite.play("default")
	sprite.animation_finished.connect(queue_free)

func setup(color: Color, scale_v: Vector2) -> void:
	modulate = color
	scale = scale_v
```

调用方完全不变，`VFXLibrary.spawn("melee_fan", ...)` 自动 dispatch。

## 已生成清单 _(自动同步自 assets/ 目录)_

### VFX 美术（9 个）

目录：`assets/sprites/vfx/`

- `aoe_circle`, `equip_glow`, `harvest_pop`, `hit_spark`, `levelup_burst`
- `melee_fan`, `melee_rect`, `place_dust`, `projectile_trail`
