# 美术：建筑

2.5D 斜视角，pivot 在底边中心，透明背景，PNG 导出。所有建筑由方块堆叠构成，每个面用 2-3 色平涂区分亮面/暗面。

| 类型 | 源文件尺寸 | 示例 |
|------|----------|------|
| 小型家具/设施 | 192×192 px | 工作台、箱子、烹饪锅 |
| 中型建筑 | 256×256 px | 贸易摊、信箱、筒仓 |
| 大型建筑 | 384×384 / 384×512 px | 房屋、仓库、畜棚 |

## 提示词模板

```
Minecraft-inspired pixel art sprite, transparent background,
2.5D top-down orthographic view, blocky cubic building made of stacked square blocks,
flat block-face shading (top face lighter, front face mid-tone, side face darker),
hard square pixel edges, no curves, no rounded corners.
Single static building asset, {宽度}x{高度} pixels.
Building centered on canvas, base aligned to bottom center, readable block silhouette.

Subject: {在此填写建筑描述和尺寸，如 "wooden crafting table block, oak plank texture top, 192x192"}

Minecraft pixel art, game asset, no background
```

## 当前资产列表

| id | 描述 | 源文件尺寸 | 文件路径 | 状态 |
|----|------|----------|----------|------|
| `workbench` | wooden crafting table block, oak plank texture on top, tool icons as pixel squares | 192×192 | `assets/sprites/buildings/workbench.png` | ✅ |
| `storage_chest` | wooden chest block, brown oak planks, metal latch pixel line on front | 192×192 | `assets/sprites/buildings/storage_chest.png` | ✅ |
| `cooking_pot` | stone block furnace with orange fire pixel glow on front face | 192×192 | `assets/sprites/buildings/cooking_pot.png` | ✅ |
| `farm_plot` | flat farmland block, dark brown tilled soil with pixel row lines | 192×192 | `assets/sprites/buildings/farm_plot.png` | ✅ |
| `trading_post` | wooden block booth, plank walls, colorful pixel banner squares on front | 256×256 | `assets/sprites/buildings/trading_post.png` | ✅ |
| `barn` | large red wood barn block, white pixel trim, hay door on front face | 384×384 | `assets/sprites/buildings/barn.png` | ⏳ |
| `silo` | tall cylindrical silo made of grey metal block panels, conical top, square pixel rivets | 256×384 | `assets/sprites/buildings/silo.png` | ⏳ |
| `mailbox` | small wooden mailbox block on a thin post, red pixel flag on side | 192×192 | `assets/sprites/buildings/mailbox.png` | ⏳ |
| `animal_pen` | small wooden fenced pen with hay floor square inside, oak fence post blocks | 256×256 | `assets/sprites/buildings/animal_pen.png` | ⏳ |
| `bed` | low wooden bed block, white pillow on top, red blanket pixel | 192×128 | `assets/sprites/buildings/bed.png` | ⏳ |

> 围栏类（`wood_fence` / `iron_fence` / `wood_fence_gate`）无需独立 sprite，运行时按拼接结构自动绘制。
