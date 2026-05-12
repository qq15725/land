# 美术：环境物件

透明背景，PNG 导出，pivot 在底边中心。可采集/可破坏物件使用 **1 列 × 3 行精灵表**（正常 / 受击 / 破坏）；装饰物件使用单帧静态图。
**游戏内**：Sprite2D `scale = Vector2(0.25, 0.25)`，渲染为原尺寸 ÷ 4 的世界坐标大小，屏幕显示为世界坐标 × 4（Camera zoom=4.0）。

## 代码接入说明

- `ResourceNode`（`scenes/world/resource.gd`）按 `ResourceNodeData.frame_height` 切割 sprite。
- 表高度 ≥ 3×frame_height 时，自动切换三帧；否则单帧 + 用 modulate 模拟受击/破坏闪光。
- 占位时由 `_make_fallback_texture` 生成 3 帧色块（正常 / 偏亮 / 偏暗 + 裂纹），保证视觉反馈正常。
- 采集流程：`interact()` → 闪受击帧 80ms → 切到破坏帧 → tween modulate 透明 → 等待 respawn → 重置回正常帧。

**典型比例参考（对齐星露谷物语）：**
- 树（128×192 源）→ 32×48 世界 → 128×192 屏幕 = 2 格宽 × 3 格高 ✓
- 石头（128×96 源）→ 32×24 世界 → 128×96 屏幕 = 2 格宽 × 1.5 格高 ✓

## 提示词模板（可破坏物件，3 帧精灵表）

```
Minecraft-inspired pixel art sprite sheet, transparent background,
2.5D top-down orthographic view, blocky cubic style,
all shapes made of square/rectangular pixel blocks, flat 2-3 tone shading,
hard square edges, no curves, no smooth outlines.

Sprite sheet layout: 1 column × 3 rows, each cell {单帧宽度}x{单帧高度} pixels.
Total canvas height = {单帧高度} × 3 pixels.
Strict vertical grid layout, no padding between cells, no spacing between cells.

Row 0 (top): normal intact state, full silhouette.
Row 1 (middle): damaged state — cracks drawn as dark pixel lines, small chunks missing,
  slightly askew blocks, 1-2 broken fragments around the base.
Row 2 (bottom): nearly destroyed — only a stump or a few loose blocks remain,
  fragments scattered, mostly empty space but base remains.

All rows same canvas width, object base aligned to bottom center in every row,
horizontal silhouette consistent (no row drifts left/right).

Subject: {在此填写物件描述，尺寸，如 "oak log block with green leaf cube on top, single-frame 128x192, total sheet 128x576"}

Minecraft pixel art, game asset, transparent background
```

## 提示词模板（静态装饰物件）

```
Minecraft-inspired pixel art sprite, transparent background,
2.5D top-down orthographic view, blocky cubic style,
shapes made entirely of square pixel blocks, flat color fills, hard edges.
Single static game asset, {宽度}x{高度} pixels.
Object centered on canvas, base aligned to bottom center.

Subject: {在此填写物件描述}

Minecraft pixel art, game asset, transparent background
```

## 当前资产列表

> 可破坏物件精灵表：1 列 × 3 行，行 0=正常 / 行 1=受击 / 行 2=破坏。
> 占位时 fallback texture 已经生成 3 帧色块，无需手动美术也能跑通。

| id | 描述 | 单帧源尺寸 | 完整表尺寸 | 世界渲染 | 文件路径 | 状态 |
|----|------|-----------|------------|---------|----------|------|
| `tree` | oak log block trunk topped with square green leaf cube | 128×192 | 128×576（3 帧） | 32×48 | `assets/resources/tree.png` | ⏳ 待生成 3 帧版 |
| `stone` | grey stone block cluster with pixel crack lines | 128×96 | 128×288（3 帧） | 32×24 | `assets/resources/stone.png` | ⏳ 待生成 3 帧版 |
| `iron_ore` | dark grey stone block with iron-colored pixel veins | 128×96 | 128×288（3 帧） | 32×24 | `assets/resources/iron_ore.png` | ⏳ 待生成 |
| `berry_bush` | small green block bush with red square berry pixels | 128×128 | 128×384（3 帧） | 32×32 | `assets/resources/berry_bush.png` | ⏳ 待生成 3 帧版 |
| `mushroom` | red square cap block on short white stem block | 64×96 | 64×288（3 帧） | 16×24 | `assets/resources/mushroom.png` | ⏳ 待生成 3 帧版 |

> 旧版 `assets/sprites/environment/grass.png` / `dead_tree.png` 是装饰物件（无 3 帧），保留备用。
