# 美术：环境物件

透明背景，PNG 导出，pivot 在底边中心。可采集/可破坏物件使用 **1 列 × 3 行精灵表**（正常 / 受击 / 破坏）；装饰物件使用单帧静态图。

**典型比例参考（对齐星露谷物语）：**
- 树（128×192 单帧）= 2 格宽 × 3 格高
- 石头（128×96 单帧）= 2 格宽 × 1.5 格高

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

| id | 描述 | 单帧源尺寸 | 完整表尺寸 | 文件路径 | 状态 |
|----|------|-----------|------------|----------|------|
| `tree` | oak log block trunk topped with square green leaf cube | 128×192 | 128×576（3 帧） | `assets/resources/tree.png` | ✅ |
| `stone` | grey stone block cluster with pixel crack lines | 128×96 | 128×288（3 帧） | `assets/resources/stone.png` | ✅ |
| `iron_ore` | dark grey stone block with iron-colored pixel veins | 128×96 | 128×288（3 帧） | `assets/resources/iron_ore.png` | ✅ |
| `berry_bush` | small green block bush with red square berry pixels | 128×128 | 128×384（3 帧） | `assets/resources/berry_bush.png` | ✅ |
| `mushroom` | red square cap block on short white stem block | 64×96 | 64×288（3 帧） | `assets/resources/mushroom.png` | ✅ |
| `pine_tree` | tall narrow conifer, dark green triangular layered canopy of stacked pixel cubes on a brown bark trunk, snow-flecked tip optional | 128×192 | 128×576（3 帧） | `assets/resources/pine_tree.png` | ⏳ |
| `dead_tree` | leafless skeletal tree, weather-bleached grey-white trunk with twisted bare branch blocks, no foliage, ominous silhouette | 128×192 | 128×576（3 帧） | `assets/sprites/environment/dead_tree.png` | ✅ |
| `bush` | knee-height round shrub, dense dark green foliage cube cluster, no berries, slight darker shade pixels at base | 96×96 | 96×288（3 帧） | `assets/resources/bush.png` | ⏳ |
| `red_flower` | single small red flower, four red square petals around yellow center pixel, short green stem with two leaf pixels | 64×64 | 64×192（3 帧） | `assets/resources/red_flower.png` | ⏳ |
| `yellow_flower` | single small yellow flower, four yellow square petals around orange center pixel, short green stem with two leaf pixels | 64×64 | 64×192（3 帧） | `assets/resources/yellow_flower.png` | ⏳ |
| `copper_ore` | grey stone block embedded with orange-red copper chunks, warm metallic speckle pixels and a small green oxidization spot | 128×96 | 128×288（3 帧） | `assets/resources/copper_ore.png` | ⏳ |
| `gold_ore` | grey stone block embedded with bright yellow gold nugget pixels, two-tone gold highlight, faint glow speckle | 128×96 | 128×288（3 帧） | `assets/resources/gold_ore.png` | ⏳ |
| `crystal` | jagged purple-blue crystal cluster of multi-faceted prism blocks, lighter cyan top highlight, small dark base rocks | 96×128 | 96×384（3 帧） | `assets/resources/crystal.png` | ⏳ |
| `clay_deposit` | low reddish-brown clay mound, wet glossy pixel highlights, small lumps stacked, darker shade at base | 96×64 | 96×192（3 帧） | `assets/resources/clay_deposit.png` | ⏳ |
| `sand_deposit` | small pale yellow sand dune pile, soft two-tone tan shading, a few darker grain pixels on top | 96×64 | 96×192（3 帧） | `assets/resources/sand_deposit.png` | ⏳ |
| `driftwood_pile` | stack of bleached grey-white weathered wood planks and logs, washed smooth, faint blue water-stain pixels at base | 128×96 | 128×288（3 帧） | `assets/resources/driftwood_pile.png` | ⏳ |
| `kelp_clump` | short cluster of dark green ribbon-like seaweed strands rising from sandy base, slight teal highlight, bottom-heavy silhouette | 96×96 | 96×288（3 帧） | `assets/resources/kelp_clump.png` | ⏳ |
| `coal_node` | grey stone block embedded with deep black coal chunks, glossy dark highlight pixels, soot speckle around base | 128×96 | 128×288（3 帧） | `assets/resources/coal_node.png` | ⏳ |
| `meteorite` | dark cosmic boulder block half-buried in scorched dirt, deep purple-grey rock with glowing magenta-red crystal cracks across the surface, embers / ember pixels around the crater rim | 128×96 | 128×288（3 帧） | `assets/resources/meteorite.png` | ⏳ |

> 旧版 `assets/sprites/environment/grass.png` / `dead_tree.png` 是装饰物件（无 3 帧），保留备用。
