# 美术：环境物件

透明背景，PNG 导出，pivot 在底边中心。可采集/可破坏物件使用 1列 × 3行精灵表；装饰物件使用单帧静态图。
**游戏内**：Sprite2D `scale = Vector2(0.25, 0.25)`，渲染为原尺寸 ÷ 4 的世界坐标大小，屏幕显示为世界坐标 × 4（Camera zoom=4.0）。

**典型比例参考（对齐星露谷物语）：**
- 树（128×192 源）→ 32×48 世界 → 128×192 屏幕 = 2格宽 × 3格高 ✓
- 石头（128×96 源）→ 32×24 世界 → 128×96 屏幕 = 2格宽 × 1.5格高 ✓

## 提示词模板（可破坏物件）

```
Minecraft-inspired pixel art sprite sheet, transparent background,
2.5D top-down orthographic view, blocky cubic style,
all shapes made of square/rectangular pixel blocks, flat 2-3 tone shading,
hard square edges, no curves, no smooth outlines.

Sprite sheet layout: 1 column × 3 rows, each cell {单帧宽度}x{单帧高度} pixels.
Strict vertical grid layout, no padding between cells, no spacing between cells.
Row 0: normal intact block state.
Row 1: damaged state (cracks drawn as dark pixel lines, chunks missing, slightly askew blocks).
Row 2: nearly destroyed (only a few loose blocks remain, fragments scattered).
All rows same canvas size, object base aligned to bottom center in every row.

Subject: {在此填写物件描述，尺寸，如 "oak log block with green leaf cube on top (128x192)"}

Minecraft pixel art, game asset, transparent background
```

## 提示词模板（静态装饰物件）

```
Minecraft-inspired pixel art sprite, transparent background,
2.5D top-down orthographic view, blocky cubic style,
shapes made entirely of square pixel blocks, flat color fills, hard edges.
Single static game asset, {宽度}x{高度} pixels.
Object centered on canvas, base aligned to bottom center.

Subject: {在此填写物件描述，尺寸，如 "small square grass block patch (64x64)"}

Minecraft pixel art, game asset, transparent background
```

## 当前资产列表

> 可破坏物件精灵表：1列 × 3行，行0=完好，行1=受损，行2=枯竭。代码目前只显示行0，枯竭状态用灰色 modulate 表示。

| id | 描述 | 单帧源尺寸 | 世界渲染 | 文件路径 | 状态 |
|----|------|-----------|---------|----------|------|
| `tree` | oak log block trunk topped with square green leaf cube | 128×192 | 32×48 | `assets/sprites/environment/tree.png` | ✅ 已接入 |
| `stone` | grey stone block cluster with pixel crack lines | 128×96 | 32×24 | `assets/sprites/environment/stone.png` | ✅ 已接入 |
| `grass` | flat green grass block patch（静态装饰物件） | 64×64 | 16×16 | `assets/sprites/environment/grass.png` | ⏳ 待接入 |
| `berry_bush` | small green block bush with red square berry pixels | 128×128 | 32×32 | `assets/sprites/environment/berry_bush.png` | ⏳ 待接入 |
| `dead_tree` | bare grey log block, thin rectangular branch sticks（静态装饰物件） | 96×192 | 24×48 | `assets/sprites/environment/dead_tree.png` | ⏳ 待接入 |
| `mushroom` | red square cap block on short white stem block（静态装饰物件） | 64×96 | 16×24 | `assets/sprites/environment/mushroom.png` | ⏳ 待接入 |
