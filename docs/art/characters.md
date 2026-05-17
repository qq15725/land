# 美术：角色与生物

**源文件**：单帧 128×256 px，精灵表 **512×1024 px**（4 列 × 4 行），透明背景，PNG 导出。

## 行走动画布局（MVP 版，所有角色当前用 4 行）

```
行 0（walk_down）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝下行走
行 1（walk_up）：    [帧0] [帧1] [帧2] [帧3]   ← 面朝上行走
行 2（walk_left）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝左行走
行 3（walk_right）： [帧0] [帧1] [帧2] [帧3]   ← 面朝右行走
```

> 若生成工具难以区分左右，可只生成左向，右向水平翻转复用。

## 玩家施法 / 受击 / 死亡动画扩展（未来美术）

代码层 `PlayerAnimState` 组件已经准备好状态切换接口，但当前用 Tween 模拟（scale 抖动 / modulate 闪光），**没有真正的施法帧**。等正式动画美术出来后，将精灵表从 4 行扩展到 8 行：

| 行 | 名称 | 帧数 | 用途 | 触发 |
|---|---|---|---|---|
| 0-3 | `walk_down/up/left/right` | 4 | 行走（已实现） | 移动 |
| 4 | `cast_fan` | 4 | 近战挥砍 | basic_swing / triple_slash 等 fan 形状技能 |
| 5 | `cast_circle` | 4 | 自身周围 AOE | whirlwind 等 circle 形状技能 |
| 6 | `cast_projectile` | 4 | 远程施法手势 | fireball 等 projectile 形状技能 |
| 7 | `hit` | 2-3 | 受击 | health.damaged 触发 |

**扩展后精灵表尺寸**：`512×2048 px`（4 列 × 8 行）。当前 `player.png` 还是 `512×1024`，扩展时一次性重出。

### 提示词增量（追加在角色提示词末尾）

```
Sprite sheet layout: 4 columns × 8 rows, each cell 128x256 pixels, total 512x2048.
Row 4 (cast_fan): 4 frames of melee sword swing — wind-up, mid-swing, follow-through,
  recover. Front-facing pose.
Row 5 (cast_circle): 4 frames of whirling self-buff — crouch, spinning rise,
  arms outstretched, settle.
Row 6 (cast_projectile): 4 frames of ranged casting — pull-back arm,
  forward throw motion, arm extended, recover.
Row 7 (hit): 3 frames of damage reaction — knock-back lean, mid-stagger, recover.
  Last cell of the row can be empty/duplicate.
All cast/hit poses face downward (the camera). All frames same scale and baseline.
```

### 死亡动画（占位策略）

代码层目前用 `visible = false` 瞬间隐藏 + 2s 后复活。如需死亡淡出动画，加：

| 行 | 名称 | 帧数 | 用途 |
|---|---|---|---|
| 8 | `die` | 3-4 | 倒地 + 淡出 |

`PlayerAnimState.play_state("die", duration)` 已经预留接口。

## 提示词模板（角色 / NPC）

```
Minecraft-inspired pixel art sprite sheet, transparent background,
2.5D top-down orthographic view, blocky cubic character design,
rectangular body parts, flat block-face shading, bold hard pixel edges,
bright cheerful colors, simple flat tones with 2-3 shades per area, no curves.

Sprite sheet layout: 4 columns × 4 rows, each cell 128x256 pixels, total 512x1024.
Strict grid layout, no padding between cells, no spacing between cells.
Row 0: walk down (4 frames), Row 1: walk up (4 frames),
Row 2: walk left (4 frames), Row 3: walk right (4 frames).
Walk cycle: legs alternate left-right as rectangular blocks swinging,
arms swing in opposite rhythm. All body parts rectangular/square, no rounded limbs.
Each frame centered in its cell, feet aligned to same baseline, same scale in every frame.

Subject: {在此填写角色描述，如 "farmer with blocky square head, blue overall pants, brown shirt"}

Minecraft pixel art, game asset, no background, clean sprite sheet grid
```

## 提示词模板（怪物）

```
Minecraft-inspired pixel art sprite sheet, transparent background,
2.5D top-down orthographic view, blocky cubic creature design,
all body parts are rectangular or square blocks, flat color fills,
2-3 tone shading per block face, hard pixel edges, no curves, no smooth shapes.

Sprite sheet layout: 4 columns × 4 rows, each cell 128x256 pixels, total 512x1024.
Strict grid layout, no padding between cells, no spacing between cells.
Row 0: walk/move down (4 frames), Row 1: walk/move up (4 frames),
Row 2: walk/move left (4 frames), Row 3: walk/move right (4 frames).
Movement cycle uses simple rectangular block limb swinging or body bouncing.
Each frame centered in its cell, body base aligned to same baseline, same scale in every frame.

Subject: {在此填写怪物描述，如 "green blocky slime cube with pixel eyes, bouncing movement"}

Minecraft pixel art, game asset, no background, clean sprite sheet grid
```

## 当前资产列表

| id | 描述 | 源文件尺寸 | 文件路径 | 状态 |
|----|------|-----------|----------|------|
| `player` | blocky farmer, square head, blue overall pants, brown shirt, simple pixel face | 512×1024 | `assets/sprites/characters/player.png` | ✅ |
| `merchant` | blocky traveling merchant, wide flat hat, long coat, rectangular backpack | 512×1024 | `assets/sprites/characters/merchant.png` | ✅ |
| `slime` | green cube slime, square body, pixel dot eyes, bouncy block movement | 512×1024 | `assets/creatures/slime.png` | ✅ |
| `skeleton` | white rectangular skeleton, block skull head, stick-like limbs made of thin rectangles | 512×1024 | `assets/creatures/skeleton.png` | ✅ |
| `chicken` | small white blocky chicken, square body, rectangular beak, stubby block legs | 512×1024 | `assets/animals/chicken.png` | ✅ |
| `cow` | blocky cow, white body with brown pixel patches, pink square nose, stubby block legs | 512×1024 | `assets/animals/cow.png` | ✅ |
| `pig` | blocky pink pig, round-ish square body, pixel snout, four stubby block legs | 512×1024 | `assets/animals/pig.png` | ✅ |
| `sheep` | blocky white woolly sheep, fluffy square block body, small head, four block legs | 512×1024 | `assets/animals/sheep.png` | ✅ |
| `wolf` | blocky grey wolf, lean rectangular body, pixel teeth, sharp triangular ears made of squares | 512×1024 | `assets/creatures/wolf.png` | ✅ |
| `zombie` | green-skinned blocky humanoid zombie, torn shirt, dragging walk pose | 512×1024 | `assets/creatures/zombie.png` | ✅ |
| `bat` | small black bat with pixel wings, glowing red dot eyes, hovering in place | 512×1024 | `assets/creatures/bat.png` | ✅ |
| `rabbit` | small blocky white rabbit, long pixel ears, pink pixel nose, hopping pose, fluffy square tail | 512×1024 | `assets/creatures/rabbit.png` | ✅ |
| `deer` | tall blocky deer, brown body with white belly pixels, branching antler blocks on head, four thin block legs | 512×1024 | `assets/creatures/deer.png` | ✅ |
| `season_bear` | huge boss-sized blocky brown bear, two pixel rows taller than player, dark brown fur with lighter belly, large square paws with white claw pixels, angry pixel eyes glowing red, intimidating wide stance | 512×1024 | `assets/creatures/season_bear.png` | ✅ |
| `stone_golem` | massive blocky grey stone humanoid, dice-cube torso made of stacked rock blocks, cubic boulder fists, glowing cyan crack pixels along seams, slow heavy stomp pose | 512×1024 | `assets/creatures/stone_golem.png` | ⏳ |
| `bat_king` | boss-sized deep purple-red bat, twice the size of a normal bat, large jagged block wings, glowing red pixel eyes, sharp white fang pixels, golden crown pixel on head | 512×1024 | `assets/creatures/bat_king.png` | ⏳ |
| `fire_elemental` | hovering blocky flame creature, layered orange-red fire cube body, brighter yellow core pixel, drifting ember speckles trailing, two pixel-dot eyes glowing white | 512×1024 | `assets/creatures/fire_elemental.png` | ⏳ |
| `ice_slime` | pale cyan-blue semi-transparent cube slime, frost crystal pixels embedded inside, two dark pixel eyes, faint white frost highlight on top face | 512×1024 | `assets/creatures/ice_slime.png` | ⏳ |
| `wisp` | small floating glowing orb creature, soft white-yellow core pixel surrounded by faint translucent aura blocks, two tiny dot eyes, no limbs, hovering pose | 512×1024 | `assets/creatures/wisp.png` | ⏳ |
| `venom_scorpion` | dark green blocky scorpion, segmented rectangular body, two large pixel claw pincers raised forward, curled pixel tail with purple venom drop at stinger tip, low scuttle pose | 512×1024 | `assets/creatures/venom_scorpion.png` | ⏳ |
| `duck` | small blocky white duck, square body, flat orange pixel beak, short stubby orange legs, two small wing block accents on sides, waddling pose | 512×1024 | `assets/animals/duck.png` | ⏳ |
| `goose` | tall blocky white goose, longer neck made of stacked white blocks, bright orange pixel beak with black mask pixels around eyes, hissing pose | 512×1024 | `assets/animals/goose.png` | ⏳ |
| `rabbit_farm` | domestic farm rabbit variant, blocky cream-white body with brown pixel patches, long pixel ears, pink pixel nose, calm sitting pose with fluffy block tail | 512×1024 | `assets/animals/rabbit_farm.png` | ⏳ |
| `angora_goat` | fluffy white angora goat, oversized woolly square block body, small pixel horns, four short block legs, dark pixel eyes and small black nose | 512×1024 | `assets/animals/angora_goat.png` | ⏳ |
