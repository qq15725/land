# 美术：物品图标

物品图标统一打包成一张 sprite sheet，按 **8 列 × 4 行** grid 排列。Godot 自动按 `icons.png.width / 8` 推断单格尺寸，所以**占位与正式版尺寸可以不同**，只要保持 8×4 网格即可：

- 占位（已存在）：`256×128 px` → 单格 `32×32 px`
- 正式版：`512×256 px` → 单格 `64×64 px`

每个物品在 `data/items.json` 中通过 `icon_grid: [col, row]` 指定自己在网格中的坐标。

代码切割位置：`scripts/systems/item_database.gd` `get_item_icon(item)`。

## 提示词模板

```
Minecraft-style pixel art icon sheet, transparent background, flat front view,
blocky item icons, hard square pixel edges, flat 2-3 tone color fills, no gradients.
Grid layout, 8 columns × 4 rows. Canvas size {W}x{H} pixels, each cell {S}x{S} pixels.
Strict grid layout, no padding between cells, no spacing between cells.
Each icon is a simple recognizable block or item, Minecraft inventory icon style.

Icons (left to right, top to bottom):
{逐个列出图标描述}

Minecraft pixel art, game asset icons, clean grid, transparent background
```

## 当前图标分布（8 列 × 4 行）

`assets/sprites/items/icons.png` 中每个物品的网格坐标如下（与 `data/items.json` 一致）：

| (col, row) | id | 描述 |
|------------|----|------|
| (0, 0) | `wood` | 棕色橡木原木块，纹理像素线 |
| (1, 0) | `stone` | 灰色石块，2-3 条裂纹像素线 |
| (2, 0) | `wooden_plank` | 浅棕色木板，2 道横向接缝像素线 |
| (3, 0) | `iron_ore` | 灰褐色矿石块，铁色斑点像素 |
| (4, 0) | `iron_bar` | 灰白金属锭，方正几何，1-2 像素高光 |
| (5, 0) | `rope` | 卷起的麻绳圈，浅棕色编织像素 |
| (6, 0) | `hay` | 金黄色干草捆，竖直草秆像素 |
| (7, 0) | `carrot` | 橙色胡萝卜，绿色叶片像素 |
| (0, 1) | `carrot_seed` | 小袋装橙色种子，棕色袋身 |
| (1, 1) | `wheat` | 金黄小麦捆，麦穗像素 |
| (2, 1) | `wheat_seed` | 小袋装黄色种子 |
| (3, 1) | `potato` | 米黄色土豆，斑点像素 |
| (4, 1) | `potato_seed` | 小袋装米色种子 |
| (5, 1) | `tomato` | 红色番茄，绿色蒂叶像素 |
| (6, 1) | `tomato_seed` | 小袋装红色种子 |
| (7, 1) | `berry` | 紫红色浆果一簇 |
| (0, 2) | `mushroom` | 红盖白杆蘑菇 |
| (1, 2) | `chicken_egg` | 白色椭圆鸡蛋 |
| (2, 2) | `milk` | 玻璃瓶装白色牛奶 |
| (3, 2) | `animal_feed` | 棕色饲料桶/袋 |
| (4, 2) | `cooked_carrot` | 橙红色烤胡萝卜在木盘上 |
| (5, 2) | `cooked_mushroom` | 深棕色烤蘑菇 |
| (6, 2) | `berry_jam` | 紫红色果酱玻璃罐 |
| (7, 2) | `rare_seed` | 紫色发光稀有种子，星点像素 |
| (0, 3) | `blueprint` | 卷起的米色羊皮纸蓝图 |

> 剩下 (1, 3) 到 (7, 3) 共 7 格留空，方便未来加新物品。

## 替换流程

1. 在 AI 中用上方提示词生成，确保 8×4 网格、无 padding、透明背景。
2. 直接覆盖 `assets/sprites/items/icons.png`。
3. 不需要改代码（自动识别尺寸）。如果加新物品，在 `data/items.json` 给它分配一个空格 `icon_grid`。
