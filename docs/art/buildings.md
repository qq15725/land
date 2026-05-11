# 美术：建筑

2.5D 斜视角，pivot 在底边中心，透明背景，PNG 导出。所有建筑由方块堆叠构成，每个面用 2-3 色平涂区分亮面/暗面。
**游戏内**：Sprite2D `scale = Vector2(0.25, 0.25)`，渲染为原尺寸 ÷ 4 的世界坐标大小，屏幕显示为世界坐标 × 4（Camera zoom=4.0）。

| 类型 | 源文件尺寸 | 游戏内渲染 | 示例 |
|------|----------|-----------|------|
| 小型家具/设施 | 192×192 px | 48×48 px | 工作台、箱子、烹饪锅 |
| 中型建筑 | 256×256 px | 64×64 px | 贸易摊、围栏门、小棚屋 |
| 大型建筑 | 384×384 / 384×512 px | 96×96 / 96×128 px | 房屋、仓库、畜棚 |

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
| `workbench` | wooden crafting table block, oak plank texture on top, tool icons as pixel squares | 192×192 | `assets/sprites/buildings/workbench.png` | ✅ 已接入 |
| `storage_chest` | wooden chest block, brown oak planks, metal latch pixel line on front | 192×192 | `assets/sprites/buildings/storage_chest.png` | ✅ 已接入 |
| `cooking_pot` | stone block furnace with orange fire pixel glow on front face | 192×192 | `assets/sprites/buildings/cooking_pot.png` | ✅ 已接入 |
| `farm_plot` | flat farmland block, dark brown tilled soil with pixel row lines | 192×192 | `assets/sprites/buildings/farm_plot.png` | ✅ 已接入 |
| `trading_post` | wooden block booth, plank walls, colorful pixel banner squares on front | 256×256 | `assets/sprites/buildings/trading_post.png` | ✅ 已接入 |
