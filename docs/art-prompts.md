# 美术提示词

推荐工具：Leonardo.AI（Pixel Art 模型）或 Scenario.gg

## 整体风格基调

温暖乡村生活模拟 RPG 像素风：明亮温暖的配色，柔和的像素轮廓，阳光乡村氛围。可以参考经典农场经营游戏的舒适感，但避免直接复制具体游戏角色、建筑或 UI。

### 通用生成约束

所有提示词都建议追加以下约束，减少不能直接导入 Godot 的结果：

```
pixel-perfect sprite, transparent background, clean hard pixel edges,
orthographic game asset view, consistent scale, no anti-aliased blurry edges,
no realistic rendering, no 3D render, no painterly brush strokes,
no background scene, no cast shadow on background, no text, no watermark, no logo,
no extra objects, no cropped sprite, no inconsistent frame sizes
```

负面提示词：

```
dark fantasy, gothic, horror, gritty, realistic, cinematic lighting,
blur, soft focus, watercolor, oil painting, vector art, clay render,
text, letters, numbers, watermark, logo, background, scenery,
extra limbs, duplicate character, cropped body, inconsistent sprite size
```

---

## 精灵表格式约定

> 所有资源统一格式，方便 JSON 数据系统按路径加载并在 Godot `AnimatedSprite2D` 中切割。

| 类型 | 单帧尺寸 | 精灵表布局 | 动画说明 |
|------|----------|-----------|----------|
| 角色 / 怪物 | 32×64 px | 4列 × 4行 | 每行一个方向：下/上/左/右，每行4帧 |
| 可破坏环境物件 | 视物件而定 | 1列 × 3行 | 第1帧正常，第2帧受击，第3帧破坏消失 |
| 静态环境物件 | 视物件而定 | 单帧静态 | 无动画 |
| 建筑 | 48×48 / 64×64 / 96×96 等 | 单帧静态 | 无动画 |
| 物品图标 | 16×16 px | grid 排列 | 无动画 |

**文件命名规范**（与 JSON 中 `sprite` 字段对应）：
```
assets/sprites/characters/{id}.png     # 角色/怪物
assets/sprites/environment/{id}.png    # 环境物件
assets/sprites/buildings/{id}.png      # 建筑
assets/sprites/items/{id}.png          # 物品图标（整张图标表）
```

---

## 角色与生物（帧动画精灵表）

单帧 32×64 px，精灵表 128×256 px（4列 × 4行），透明背景，PNG 导出。

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
pixel art sprite sheet, transparent background, 2.5D top-down orthographic view,
cozy farming RPG pixel art style, soft outlines, warm sunny colors, cheerful rural aesthetic.

Sprite sheet layout: 4 columns × 4 rows, each cell 32x64 pixels, total 128x256.
Strict grid layout, no padding between cells, no spacing between cells.
Row 0: walk down (4 frames), Row 1: walk up (4 frames),
Row 2: walk left (4 frames), Row 3: walk right (4 frames).
Smooth walk cycle, feet alternating, consistent body proportions across frames.
Each frame centered in its cell, feet aligned to the same baseline, same character scale in every frame.

Subject: {在此填写角色描述，如 "farmer in cozy overalls, warm brown hair, friendly smile"}

Pixel art, game asset, no background, clean sprite sheet grid, pixel-perfect edges
```

### 提示词模板（怪物）

```
pixel art sprite sheet, transparent background, 2.5D top-down orthographic view,
cozy farming RPG pixel art style, soft outlines, warm colors, cute not scary aesthetic.

Sprite sheet layout: 4 columns × 4 rows, each cell 32x64 pixels, total 128x256.
Strict grid layout, no padding between cells, no spacing between cells.
Row 0: walk down (4 frames), Row 1: walk up (4 frames),
Row 2: walk left (4 frames), Row 3: walk right (4 frames).
Smooth readable walk or bounce cycle, consistent body proportions across frames.
Each frame centered in its cell, feet or body base aligned to the same baseline, same creature scale in every frame.

Subject: {在此填写怪物描述，如 "round chubby green slime with big cute eyes, bouncing walk"}

Pixel art, game asset, no background, clean sprite sheet grid, pixel-perfect edges
```

### 当前需要的角色列表

| id | 描述 | 文件路径 |
|----|------|----------|
| `player` | farmer in cozy overalls, warm brown hair, friendly smile | `assets/sprites/characters/player.png` |
| `merchant` | traveling merchant, wide straw hat, long coat, travel bag | `assets/sprites/characters/merchant.png` |
| `slime` | round chubby green slime with big cute eyes, bouncy | `assets/sprites/characters/slime.png` |
| `skeleton` | cartoonish skeleton, simple bone humanoid, not scary | `assets/sprites/characters/skeleton.png` |
| `chicken` | small fluffy white chicken, waddling walk | `assets/sprites/characters/chicken.png` |

---

## 环境物件

透明背景，PNG 导出，pivot 在底边中心。可采集/可破坏物件使用 1列 × 3行精灵表；装饰物件使用单帧静态图。

### 提示词模板（可破坏物件）

```
pixel art sprite sheet, transparent background, 2.5D top-down orthographic view,
cozy farming RPG pixel art style, soft outlines, bright natural colors, warm sunlit feel.

Sprite sheet layout: 1 column × 3 rows, each cell {单帧宽度}x{单帧高度} pixels.
Strict vertical grid layout, no padding between cells, no spacing between cells.
Row 0: normal healthy state.
Row 1: damaged state (cracks, missing pieces, slightly tilted).
Row 2: nearly destroyed state (broken, fragments, about to disappear).
All rows same canvas size, consistent silhouette, same object scale.
Object base aligned to the bottom center in every frame.

Subject: {在此填写物件描述，尺寸，如 "oak tree (32x48), lush bright green canopy, warm brown trunk"}

Pixel art, game asset, transparent background, pixel-perfect edges
```

### 提示词模板（静态装饰物件）

```
pixel art sprite, transparent background, 2.5D top-down orthographic view,
cozy farming RPG pixel art style, soft outlines, bright natural colors, warm sunlit feel.
Single static game asset, {宽度}x{高度} pixels.
Object centered on canvas, base aligned to bottom center.

Subject: {在此填写物件描述，尺寸，如 "bright fresh green grass tuft (16x16)"}

Pixel art, game asset, transparent background, pixel-perfect edges
```

### 当前需要的环境物件列表

| id | 描述 | 单帧尺寸 | 文件路径 |
|----|------|----------|----------|
| `tree` | oak tree, lush bright green canopy, warm brown trunk | 32×48 | `assets/sprites/environment/tree.png` |
| `stone` | rounded light grey rock cluster | 32×24 | `assets/sprites/environment/stone.png` |
| `grass` | bright fresh green grass tuft（静态装饰物件） | 16×16 | `assets/sprites/environment/grass.png` |
| `berry_bush` | leafy green bush with vibrant red berries | 32×32 | `assets/sprites/environment/berry_bush.png` |
| `dead_tree` | pale bare branches, gentle look（静态装饰物件） | 24×48 | `assets/sprites/environment/dead_tree.png` |
| `mushroom` | cheerful red cap with white spots（静态装饰物件） | 16×24 | `assets/sprites/environment/mushroom.png` |

---

## 建筑（静态精灵）

2.5D 斜视角，pivot 在底边中心，透明背景，PNG 导出。尺寸按占地规模选择，避免大型建筑挤在 48×48 中导致细节不可读。

| 类型 | 建议尺寸 | 示例 |
|------|----------|------|
| 小型家具/设施 | 48×48 px | 工作台、箱子、烹饪锅 |
| 中型建筑 | 64×64 px | 贸易摊、围栏门、小棚屋 |
| 大型建筑 | 96×96 px 或 96×128 px | 房屋、仓库、畜棚 |

### 提示词模板

```
pixel art sprite, transparent background, 2.5D top-down orthographic view,
cozy farming RPG pixel art style, soft outlines, warm cozy colors, sunny rural village aesthetic.
Single static building game asset, {宽度}x{高度} pixels.
Building centered on canvas, base aligned to bottom center, readable silhouette.

Subject: {在此填写建筑描述和尺寸，如 "wooden workbench with tools on top, warm wood tones, 48x48"}

Pixel art, game asset, no background, pixel-perfect edges
```

### 当前需要的建筑列表

| id | 描述 | 尺寸 | 文件路径 |
|----|------|------|----------|
| `workbench` | wooden workbench with tools on top, warm wood tones | 48×48 | `assets/sprites/buildings/workbench.png` |
| `storage_chest` | wooden storage chest, closed, light brown with metal clasp | 48×48 | `assets/sprites/buildings/storage_chest.png` |
| `cooking_pot` | stone cooking pot over small orange fire, cozy feel | 48×48 | `assets/sprites/buildings/cooking_pot.png` |
| `farm_plot` | tilled farm plot with moist dark soil rows | 48×48 | `assets/sprites/buildings/farm_plot.png` |
| `trading_post` | wooden trading post booth with colorful sign, inviting look | 64×64 | `assets/sprites/buildings/trading_post.png` |

---

## 物品图标（图标表）

每格 16×16 px，按 grid 排列在一张图上，正面平视，透明背景，PNG 导出。在 Godot 中按坐标切割单个图标。

### 提示词模板

```
pixel art icon sheet, transparent background, flat front view,
cozy farming RPG pixel art style, soft outlines, warm bright colors.
Grid layout, each icon 16x16 pixels, {N} columns × {M} rows.
Strict grid layout, no padding between cells, no spacing between cells.
One simple readable object per cell, high contrast at 16x16 size, no tiny details.

Icons (left to right, top to bottom):
{逐个列出图标描述}

Pixel art, game asset icons, clean grid, no background, pixel-perfect edges
```

### 当前图标表（4列 × 2行，共8个）

```
pixel art icon sheet, transparent background, flat front view,
cozy farming RPG pixel art style, soft outlines, warm bright colors.
Grid layout, each icon 16x16 pixels, 4 columns × 2 rows.
Canvas size 64x32 pixels. Strict grid layout, no padding between cells, no spacing between cells.
One simple readable object per cell, high contrast at 16x16 size, no tiny details.

Icons (left to right, top to bottom):
1. warm brown wood log
2. light grey rounded stone
3. bright orange carrot
4. golden wheat stalk
5. white egg
6. golden cooked carrot on plate
7. glowing sky-blue magical seed
8. cream rolled paper scroll with ribbon

Pixel art, game asset icons, clean grid, transparent background, pixel-perfect edges
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

风格：温暖农场经营 RPG 的木质 + 羊皮纸质感，圆角描边，奶油米色底，棕色边框。在 Godot 中通过 `StyleBoxTexture`（9-patch）或 `Theme` 全局应用。

### 格式约定

| 元素 | 尺寸 | Godot 用途 |
|------|------|-----------|
| 面板背景（9-patch） | 32×32 px，角 8px | `PanelContainer` / `StyleBoxTexture` |
| 按钮（3 状态横排） | 48×16 px × 3 | `Button` normal / hover / pressed |
| 物品格子 | 20×20 px | 背包 / 储物箱格子背景 |
| 血量条背景 | 96×12 px | `ProgressBar` under texture |
| 血量条填充 | 96×12 px | `ProgressBar` fill texture |
| 分隔线 | 16×4 px（可横向拉伸） | `HSeparator` |
| 标题栏背景 | 32×16 px（可横向拉伸） | 面板顶部拖拽区域 |
| 时间 / 昼夜图标 | 16×16 px × 2（太阳 + 月亮） | HUD 昼夜状态 |
| 当前物品框 | 52×52 px | HUD 选中物品显示框 |

文件路径：`assets/sprites/ui/ui_sheet.png`（统一一张图，各元素按行排列）

### 提示词（UI 精灵表）

```
pixel art UI sprite sheet, transparent background,
cozy farming RPG pixel art style, warm rustic aesthetic, cozy wood and parchment textures,
soft outlines, warm earthy palette.

Canvas size: 128x208 pixels.
All elements aligned to the top-left, pixel-perfect, clean hard edges.
No labels, no text, no icons except the requested sun and moon, no decorative objects outside the requested rows.
Each element on a separate row, 2px gap between rows:

ROW 0 — Panel 9-patch (32x32 px):
  warm parchment/cream fill, rounded brown wooden border 8px thick on all sides,
  slightly worn texture, cozy feel. Suitable for 9-slice scaling in game engine.

ROW 1 — Button (3 states, each 48x16 px, placed side by side):
  state 1 normal: light warm wood plaque, subtle border;
  state 2 hover: slightly brighter, soft glow edge;
  state 3 pressed: slightly darker, inset shadow effect.

ROW 2 — Item slot (20x20 px):
  dark brown square, inset inner border, subtle worn look, slightly recessed.

ROW 3 — Health bar background (96x12 px):
  rounded ends, dark brown border, dark inner background.
  Health bar fill (96x12 px, placed directly below):
  warm red-orange gradient, rounded ends, slight highlight on top edge.

ROW 4 — Horizontal separator (16x4 px):
  warm brown decorative line, slightly ornate.

ROW 5 — Title bar background (32x16 px, horizontally tileable):
  slightly darker warm wood than panel, used as drag handle at top of windows.

ROW 6 — HUD icons (16x16 px each, side by side):
  sun icon: bright golden yellow sun with small rays, cheerful;
  moon icon: soft pale crescent moon with a star, calm night feel.

ROW 7 — Current item frame (52x52 px):
  warm wooden square frame, slightly thicker border, inner dark slot area,
  cozy highlight on top-left corner.

Pixel art, clean edges, consistent warm palette, transparent background
```

### 应用方式（Godot）

| 元素 | 应用节点 | 方式 |
|------|----------|------|
| 面板背景 | `PanelContainer` | `StyleBoxTexture`，9-patch 边距 8px |
| 按钮 | `Button` | `StyleBoxTexture`，分别对应 normal/hover/pressed |
| 物品格子 | 背包 `Button` | `StyleBoxTexture`，`add_theme_stylebox_override` |
| 血量条 | `ProgressBar` | `under` / `fill` 纹理属性 |
| 分隔线 | `HSeparator` | `StyleBoxTexture` |
| 标题栏 | `DraggablePanel` 标题行背景 | `StyleBoxTexture`，`h_axis_stretch_mode = TILE` |
| 昼夜图标 | HUD `TextureRect` | 根据 `TimeSystem` 切换 sun / moon 帧 |
| 当前物品框 | HUD 选中格 | `TextureRect` 叠在格子背景上 |
