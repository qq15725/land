# 美术：角色与生物

**源文件**：单帧 128×256 px，精灵表 **512×1024 px**（4 列 × 4 行），透明背景，PNG 导出。

## 行走动画布局

```
行 0（walk_down）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝下行走
行 1（walk_up）：    [帧0] [帧1] [帧2] [帧3]   ← 面朝上行走
行 2（walk_left）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝左行走
行 3（walk_right）： [帧0] [帧1] [帧2] [帧3]   ← 面朝右行走
```

> 若生成工具难以区分左右，可只生成左向，右向水平翻转复用。

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
| `slime` | green cube slime, square body, pixel dot eyes, bouncy block movement | 512×1024 | `assets/sprites/characters/slime.png` | ✅ |
| `skeleton` | white rectangular skeleton, block skull head, stick-like limbs made of thin rectangles | 512×1024 | `assets/sprites/characters/skeleton.png` | ✅ |
| `chicken` | small white blocky chicken, square body, rectangular beak, stubby block legs | 512×1024 | `assets/sprites/characters/chicken.png` | ✅ |
| `cow` | blocky cow, white body with brown pixel patches, pink square nose, stubby block legs | 512×1024 | `assets/animals/cow.png` | ⏳ |
| `pig` | blocky pink pig, round-ish square body, pixel snout, four stubby block legs | 512×1024 | `assets/animals/pig.png` | ⏳ |
| `sheep` | blocky white woolly sheep, fluffy square block body, small head, four block legs | 512×1024 | `assets/animals/sheep.png` | ⏳ |
| `wolf` | blocky grey wolf, lean rectangular body, pixel teeth, sharp triangular ears made of squares | 512×1024 | `assets/creatures/wolf.png` | ⏳ |
| `zombie` | green-skinned blocky humanoid zombie, torn shirt, dragging walk pose | 512×1024 | `assets/creatures/zombie.png` | ⏳ |
| `bat` | small black bat with pixel wings, glowing red dot eyes, hovering in place | 512×1024 | `assets/creatures/bat.png` | ⏳ |
