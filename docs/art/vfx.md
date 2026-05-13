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
