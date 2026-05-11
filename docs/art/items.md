# 美术：物品图标

每格 **64×64 px**，按 grid 排列在一张图上，正面平视，透明背景，PNG 导出。
在 Godot 中按坐标切割单个图标（每格 64×64 → 显示为 16×16 px UI）。
图标采用 Minecraft 物品栏风格：方块/物品正面视图，硬边缘，2-3 色平涂。

## 提示词模板

```
Minecraft-style pixel art icon sheet, transparent background, flat front view,
blocky item icons, hard square pixel edges, flat 2-3 tone color fills, no gradients.
Grid layout, each icon 64x64 pixels, {N} columns × {M} rows.
Strict grid layout, no padding between cells, no spacing between cells.
Each icon is a simple recognizable block or item, Minecraft inventory icon style.

Icons (left to right, top to bottom):
{逐个列出图标描述}

Minecraft pixel art, game asset icons, clean grid, no background
```

## 当前图标表（4列 × 2行，共8个）

文件路径：`assets/sprites/items/icons.png`

```
Minecraft-style pixel art icon sheet, transparent background, flat front view,
blocky item icons, hard square pixel edges, flat 2-3 tone color fills, no gradients.
Grid layout, each icon 64x64 pixels, 4 columns × 2 rows.
Canvas size 256x128 pixels. Strict grid layout, no padding, no spacing between cells.
Each icon simple and readable, Minecraft inventory icon style.

Icons (left to right, top to bottom):
1. brown wooden log block, oak wood grain pixel lines
2. grey stone block with pixel crack lines
3. orange carrot item, green pixel leaf top
4. golden yellow wheat bundle, pixel stalk lines
5. white egg, simple oval pixel shape
6. orange cooked carrot on flat pixel plate
7. bright blue glowing seed, pixel sparkle dots
8. cream scroll paper, rolled ends, pixel ribbon line

Minecraft pixel art, game asset icons, clean grid, transparent background
```

| 格坐标 | id | 描述 |
|--------|----|------|
| (0,0) | `wood` | 木材 |
| (1,0) | `stone` | 石头 |
| (2,0) | `carrot` | 胡萝卜 |
| (3,0) | `wheat` | 小麦 |
| (0,1) | `egg` | 鸡蛋 |
| (1,1) | `cooked_carrot` | 烤胡萝卜 |
| (2,1) | `rare_seed` | 稀有种子 |
| (3,1) | `blueprint` | 配方图纸 |
