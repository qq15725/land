# 美术提示词 · 建筑与物品图标

推荐工具：Leonardo.AI（Pixel Art 模型）或 Scenario.gg

## 目标尺寸

- 建筑：48×48 px，2.5D 斜视角，pivot 在底边中心
- 物品图标：16×16 px，正面平视，用于背包格子显示

## 提示词

```
pixel art sprite sheet, white background, Don't Starve style,
thick black outlines, two sections:

TOP ROW - buildings (48x48 each), 2.5D isometric view:
1. wooden workbench with tools on top
2. wooden storage chest, closed
3. stone cooking pot with fire
4. tilled farm plot (soil rows)
5. wooden trading post booth with sign

BOTTOM ROW - item icons (16x16 each), flat view:
wood log, grey stone, orange carrot, yellow wheat stalk,
white egg, cooked food, glowing blue seed, rolled paper scroll

pixel art, game asset, transparent background
```

## 对应游戏实体

### 建筑

| 序号 | 建筑 | 游戏文件 |
|------|------|----------|
| 1 | 工作台 | `scenes/buildings/workbench.tscn` |
| 2 | 储物箱 | `scenes/buildings/storage_chest.tscn` |
| 3 | 烹饪锅 | `scenes/buildings/cooking_pot.tscn` |
| 4 | 农田 | `scenes/farm/farm_plot.tscn` |
| 5 | 贸易站 | `scenes/buildings/trading_post.tscn` |

### 物品图标

| 图标 | 游戏文件 |
|------|----------|
| 木材 | `resources/items/wood.tres` |
| 石头 | `resources/items/stone.tres` |
| 胡萝卜 | `resources/items/carrot.tres` |
| 小麦 | `resources/items/wheat.tres` |
| 鸡蛋 | `resources/items/egg.tres` |
| 烤胡萝卜 | `resources/items/cooked_carrot.tres` |
| 稀有种子 | `resources/items/rare_seed.tres` |
| 配方图纸 | `resources/items/blueprint.tres` |
