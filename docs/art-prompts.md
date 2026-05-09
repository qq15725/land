# 美术提示词

## 整体风格基调

Minecraft 风格像素方块世界：所有物体由方块/像素格组成，硬边缘无平滑曲线，角色和物件都是方形/矩形拼接的块状造型。配色明亮，每个方块面用 2-3 个色阶平涂，风格简洁有力。避免圆角、渐变、柔和轮廓。

### 通用约束（追加到每条提示词末尾）

```
Minecraft-style pixel art, transparent background, hard square pixel edges,
flat block faces with 2-3 tone shading, no smooth curves, no rounded shapes,
no anti-aliasing, no gradients, no realistic rendering, no 3D render,
no background scene, no text, no watermark, no logo,
no extra objects, no cropped sprite, no inconsistent frame sizes
```

---

## 精灵表格式约定

> 所有尺寸为**源文件尺寸**（4 倍高清），Godot 场景缩放参考下表。**Camera2D zoom = 4.0**，格子 = 64×64 屏幕像素，对齐星露谷物语比例。

| 类型 | 单帧源尺寸 | 场景 scale | 游戏世界渲染尺寸 | 屏幕像素（zoom×4） | 精灵表布局 | 动画说明 |
|------|-----------|-----------|----------------|------------------|-----------|----------|
| 角色 / 怪物 | 128×256 px | 0.125 | 16×32 px（1×2 格） | 64×128 px | 4列 × 4行 | 每行一个方向：下/上/左/右，每行4帧 |
| 可破坏环境物件 | 视物件而定 | 0.25 | 原尺寸 ÷ 4 | 原尺寸 | 1列 × 3行 | 行0正常，行1受损，行2枯竭 |
| 静态环境物件 | 视物件而定 | 0.25 | 原尺寸 ÷ 4 | 原尺寸 | 单帧静态 | 无动画 |
| 建筑 | 192×192 / 256×256 等 | 0.25 | 48×48 / 64×64 px | 192×192 / 256×256 px | 单帧静态 | 无动画 |
| 物品图标 | 64×64 px | — | 16×16 px（UI） | — | grid 排列 | 无动画 |

**文件命名规范**（与 JSON 中 `sprite` 字段对应）：
```
assets/sprites/characters/{id}.png     # 角色/怪物
assets/sprites/environment/{id}.png    # 环境物件
assets/sprites/buildings/{id}.png      # 建筑
assets/sprites/items/{id}.png          # 物品图标（整张图标表）
```

---

## 角色与生物（帧动画精灵表）

**源文件**：单帧 128×256 px，精灵表 **512×1024 px**（4列 × 4行），透明背景，PNG 导出。
**游戏内**：AnimatedSprite2D `scale = Vector2(0.125, 0.125)`，渲染为 **16×32 px 世界坐标**（1格宽×2格高），屏幕显示 64×128 px（Camera zoom=4.0）。

### 行走动画布局

```
行0（walk_down）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝下行走
行1（walk_up）：    [帧0] [帧1] [帧2] [帧3]   ← 面朝上行走
行2（walk_left）：  [帧0] [帧1] [帧2] [帧3]   ← 面朝左行走
行3（walk_right）： [帧0] [帧1] [帧2] [帧3]   ← 面朝右行走
```

> 若生成工具难以区分左右，可只生成左向，右向在 Godot 中水平翻转（`flip_h = true`）。

### 提示词模板（角色/NPC）

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

### 提示词模板（怪物）

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

### 当前需要的角色列表

| id | 描述 | 源文件尺寸 | 文件路径 | 状态 |
|----|------|-----------|----------|------|
| `player` | blocky farmer, square head, blue overall pants, brown shirt, simple pixel face | 512×1024 | `assets/sprites/characters/player.png` | ✅ 已接入 |
| `merchant` | blocky traveling merchant, wide flat hat, long coat, rectangular backpack | 512×1024 | `assets/sprites/characters/merchant.png` | ✅ 已接入 |
| `slime` | green cube slime, square body, pixel dot eyes, bouncy block movement | 512×1024 | `assets/sprites/characters/slime.png` | ✅ 已接入 |
| `skeleton` | white rectangular skeleton, block skull head, stick-like limbs made of thin rectangles | 512×1024 | `assets/sprites/characters/skeleton.png` | ✅ 已接入 |
| `chicken` | small white blocky chicken, square body, rectangular beak, stubby block legs | 512×1024 | `assets/sprites/characters/chicken.png` | ✅ 已接入 |

---

## 地砖（TileMap Atlas）

TileMap 的地面贴图，**无透明背景**，纯色填满每格。所有瓦片必须可无缝平铺（seamless tile）。
**文件**：`assets/sprites/environment/ground_tiles.png`，一张横向 atlas，每格 **16×16 px**，游戏内 1 格 = 16×16 px 世界坐标（不缩放）。

### Atlas 布局

| 列 | Atlas 坐标 | id | 描述 |
|----|-----------|-----|------|
| 0 | (0, 0) | `grass` | 草地，中绿底色，随机深浅噪点，偶有亮绿草叶像素 |
| 1 | (1, 0) | `path` | 小路，沙棕底色，散落深色小石子像素 |
| 2 | (2, 0) | `farmland` | 耕地，深棕底色，水平垄沟纹路（每 4 行交替深浅） |
| 3 | (3, 0) | `stone_ground` | 石地，中灰底色，浅灰/深灰噪点，点缀裂缝像素线 |

总尺寸：**64×16 px**（4 列 × 1 行）

> 如需扩展（沙地、雪地、沼泽等），在 atlas 右侧追加列，并在 `world_generator.gd` 中添加对应 `ATLAS_*` 常量与 `create_tile()` 调用。

### 提示词模板

```
Minecraft-style pixel art tile sheet, NO transparent background, opaque fill,
seamlessly tileable texture, top-down flat view, hard square pixel edges,
flat 2-3 tone color fills, no gradients, no outlines, no borders between tiles.

Canvas size: 64x16 pixels. 4 tiles in a single horizontal row, each tile 16x16 pixels.
Strict grid layout, no padding, no spacing between tiles.

Tile 0 (x0–15):   grass ground — medium green base, darker/lighter green pixel noise variation,
                  occasional bright green single-pixel grass blade details.
Tile 1 (x16–31):  dirt path — sandy tan base, scattered 1–2px dark pebble pixels,
                  slight warm variation noise.
Tile 2 (x32–47):  farmland / tilled soil — dark brown base, subtle horizontal pixel furrow lines
                  every 3–4 rows alternating darker/slightly lighter.
Tile 3 (x48–63):  stone ground — mid grey base, lighter and darker grey pixel noise,
                  thin 1px dark crack pixel lines scattered.

Minecraft pixel art, seamless game tile atlas, flat ground texture, no background scenery
```

### 当前状态

| 文件 | 尺寸 | 状态 |
|------|------|------|
| `assets/sprites/environment/ground_tiles.png` | 64×16 | 🔧 程序化占位（Python 生成，需替换真实美术） |

---

## 环境物件

透明背景，PNG 导出，pivot 在底边中心。可采集/可破坏物件使用 1列 × 3行精灵表；装饰物件使用单帧静态图。
**游戏内**：Sprite2D `scale = Vector2(0.25, 0.25)`，渲染为原尺寸 ÷ 4 的世界坐标大小，屏幕显示为世界坐标 × 4（Camera zoom=4.0）。

**典型比例参考（对齐星露谷物语）：**
- 树（128×192 源）→ 32×48 世界 → 128×192 屏幕 = 2格宽 × 3格高 ✓
- 石头（128×96 源）→ 32×24 世界 → 128×96 屏幕 = 2格宽 × 1.5格高 ✓

### 提示词模板（可破坏物件）

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

### 提示词模板（静态装饰物件）

```
Minecraft-inspired pixel art sprite, transparent background,
2.5D top-down orthographic view, blocky cubic style,
shapes made entirely of square pixel blocks, flat color fills, hard edges.
Single static game asset, {宽度}x{高度} pixels.
Object centered on canvas, base aligned to bottom center.

Subject: {在此填写物件描述，尺寸，如 "small square grass block patch (64x64)"}

Minecraft pixel art, game asset, transparent background
```

### 当前需要的环境物件列表

> 可破坏物件精灵表：1列 × 3行，行0=完好，行1=受损，行2=枯竭。代码目前只显示行0，枯竭状态用灰色 modulate 表示。

| id | 描述 | 单帧源尺寸 | 世界渲染 | 文件路径 | 状态 |
|----|------|-----------|---------|----------|------|
| `tree` | oak log block trunk topped with square green leaf cube | 128×192 | 32×48 | `assets/sprites/environment/tree.png` | ✅ 已接入 |
| `stone` | grey stone block cluster with pixel crack lines | 128×96 | 32×24 | `assets/sprites/environment/stone.png` | ✅ 已接入 |
| `grass` | flat green grass block patch（静态装饰物件） | 64×64 | 16×16 | `assets/sprites/environment/grass.png` | ⏳ 待接入 |
| `berry_bush` | small green block bush with red square berry pixels | 128×128 | 32×32 | `assets/sprites/environment/berry_bush.png` | ⏳ 待接入 |
| `dead_tree` | bare grey log block, thin rectangular branch sticks（静态装饰物件） | 96×192 | 24×48 | `assets/sprites/environment/dead_tree.png` | ⏳ 待接入 |
| `mushroom` | red square cap block on short white stem block（静态装饰物件） | 64×96 | 16×24 | `assets/sprites/environment/mushroom.png` | ⏳ 待接入 |

---

## 建筑（静态精灵）

2.5D 斜视角，pivot 在底边中心，透明背景，PNG 导出。所有建筑由方块堆叠构成，每个面用 2-3 色平涂区分亮面/暗面。
**游戏内**：Sprite2D `scale = Vector2(0.25, 0.25)`，渲染为原尺寸 ÷ 4 的世界坐标大小，屏幕显示为世界坐标 × 4（Camera zoom=4.0）。

| 类型 | 源文件尺寸 | 游戏内渲染 | 示例 |
|------|----------|-----------|------|
| 小型家具/设施 | 192×192 px | 48×48 px | 工作台、箱子、烹饪锅 |
| 中型建筑 | 256×256 px | 64×64 px | 贸易摊、围栏门、小棚屋 |
| 大型建筑 | 384×384 / 384×512 px | 96×96 / 96×128 px | 房屋、仓库、畜棚 |

### 提示词模板

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

### 当前需要的建筑列表

| id | 描述 | 源文件尺寸 | 文件路径 | 状态 |
|----|------|----------|----------|------|
| `workbench` | wooden crafting table block, oak plank texture on top, tool icons as pixel squares | 192×192 | `assets/sprites/buildings/workbench.png` | ✅ 已接入 |
| `storage_chest` | wooden chest block, brown oak planks, metal latch pixel line on front | 192×192 | `assets/sprites/buildings/storage_chest.png` | ✅ 已接入 |
| `cooking_pot` | stone block furnace with orange fire pixel glow on front face | 192×192 | `assets/sprites/buildings/cooking_pot.png` | ✅ 已接入 |
| `farm_plot` | flat farmland block, dark brown tilled soil with pixel row lines | 192×192 | `assets/sprites/buildings/farm_plot.png` | ✅ 已接入 |
| `trading_post` | wooden block booth, plank walls, colorful pixel banner squares on front | 256×256 | `assets/sprites/buildings/trading_post.png` | ✅ 已接入 |

---

## 物品图标（图标表）

每格 **64×64 px**，按 grid 排列在一张图上，正面平视，透明背景，PNG 导出。
在 Godot 中按坐标切割单个图标（每格 64×64 → 显示为 16×16 px UI）。
图标采用 Minecraft 物品栏风格：方块/物品正面视图，硬边缘，2-3 色平涂。

### 提示词模板

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

### 当前图标表（4列 × 2行，共8个）

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

文件路径：`assets/sprites/items/icons.png`

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

---

## UI 元素

风格：Minecraft 方块 UI 风格，深灰色石头质感背景，方形描边，无圆角，像素格子感。在 Godot 中通过 `StyleBoxTexture`（9-patch）或 `Theme` 全局应用。

### 格式约定

| 元素 | 源文件尺寸 | Godot 用途 |
|------|-----------|-----------|
| 面板背景（9-patch） | 128×128 px，角 32px | `PanelContainer` / `StyleBoxTexture` |
| 按钮（3 状态竖排） | 192×64 px × 3（共 192×192） | `Button` normal / hover / pressed |
| 物品格子 | 80×80 px | 背包 / 储物箱格子背景 |
| 血量条背景 | 384×48 px | `ProgressBar` under texture |
| 血量条填充 | 384×48 px | `ProgressBar` fill texture |
| 分隔线 | 64×16 px（可横向拉伸） | `HSeparator` |
| 标题栏背景 | 128×64 px（可横向拉伸） | 面板顶部拖拽区域 |
| 时间 / 昼夜图标 | 64×64 px × 2（太阳 + 月亮） | HUD 昼夜状态 |
| 当前物品框 | 208×208 px | HUD 选中物品显示框 |

文件路径：`assets/sprites/ui/ui_sheet.png`（统一一张图，各元素按行排列）

### 提示词（UI 精灵表）

```
Minecraft-style pixel art UI sprite sheet, transparent background,
blocky square UI elements, dark stone/grey panel texture, hard pixel edges,
flat color fills, no gradients, no rounded corners, no soft outlines.

Canvas size: 512×832 pixels.
All elements aligned to the top-left, pixel-perfect, clean hard edges.
No labels, no text, no icons except the requested sun and moon.
Each element on a separate row, 8px gap between rows:

ROW 0 — Panel 9-patch (128x128 px):
  dark grey stone block texture fill, slightly lighter grey square border 32px thick,
  flat pixel grid texture, Minecraft inventory GUI style. Suitable for 9-slice scaling.

ROW 1 — Button (3 states, each 192x64 px, stacked vertically, total 192x192):
  state 1 normal: medium grey stone slab, flat 2-tone shading, square border;
  state 2 hover: slightly lighter grey, subtle bright pixel outline;
  state 3 pressed: darker grey, inset 4px pixel shadow on top and left.

ROW 2 — Item slot (80x80 px):
  dark grey square slot, 4px lighter grey inner border, recessed look,
  Minecraft inventory slot style.

ROW 3 — Health bar background (384x48 px):
  flat dark grey rectangle, square ends, 4px border.
  Health bar fill (384x48 px, placed directly below):
  bright red pixel fill, square ends, 4px lighter red highlight on top row of pixels.

ROW 4 — Horizontal separator (64x16 px):
  dark grey pixel line with 4px lighter grey highlight, clean square ends.

ROW 5 — Title bar background (128x64 px, horizontally tileable):
  slightly darker grey stone than panel, square pixel texture, tileable horizontally.

ROW 6 — HUD icons (64x64 px each, side by side, total 128x64):
  sun icon: blocky bright yellow square sun, pixel rays as short lines, Minecraft style;
  moon icon: white crescent made of pixel squares, dark grey background.

ROW 7 — Current item frame (208x208 px):
  dark grey square frame with lighter grey border, inner darker slot area,
  Minecraft hotbar selected slot style.

Minecraft pixel art UI, clean edges, consistent dark grey palette, transparent background
```

### 应用方式（Godot）

| 元素 | 应用节点 | 方式 |
|------|----------|------|
| 面板背景 | `PanelContainer` | `StyleBoxTexture`，9-patch 边距 32px |
| 按钮 | `Button` | `StyleBoxTexture`，分别对应 normal/hover/pressed（每段 192×64 区域） |
| 物品格子 | 背包 `Button` | `StyleBoxTexture`，`add_theme_stylebox_override` |
| 血量条 | `ProgressBar` | `under` / `fill` 纹理属性 |
| 分隔线 | `HSeparator` | `StyleBoxTexture` |
| 标题栏 | `DraggablePanel` 标题行背景 | `StyleBoxTexture`，`h_axis_stretch_mode = TILE` |
| 昼夜图标 | HUD `TextureRect` | 根据 `TimeSystem` 切换 sun / moon 帧 |
| 当前物品框 | HUD 选中格 | `TextureRect` 叠在格子背景上 |
