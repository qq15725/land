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

## 地砖（TileMap Terrain Autotile）

> **核心机制**：使用 Godot 4 **Terrain（自动地形）系统**，根据相邻格子的地砖类型自动选择正确的边缘/角落过渡图块。这就是星露谷物语草地边缘有机融入小路、耕地有清晰界限的原理。

**文件**：`assets/sprites/environment/ground_tiles.png`，每格 **64×64 px 源图块**，游戏内 1 格 = 16×16 px 世界坐标（`texture_region_size=64`，zoom=4 时屏幕 64px 1:1 采样，无放大模糊）。

---

### 美术参考

**主参考**：`docs/references/terrain_island.png`（体素方块岛屿俯视图）

从参考图中提取的**顶面材质语言**（只取顶面纹理，不画侧面/阴影/场景物件）：

| 地砖 | 参考图顶面特征 | 关键色值 |
|------|--------------|---------|
| 草地 | 鲜亮中绿，深绿方形噪点簇，亮黄绿高光像素，少量草叶 | 底 `#4A8A28`，暗簇 `#336618`，高光 `#6BB030` |
| 小路 | 沙米黄，颗粒状深浅像素，零散 1–2px 深色碎石点 | 底 `#C8A060`，暗粒 `#A07840`，碎石 `#705030` |
| 耕地 | 深巧克力棕，横向垄沟每 3–4px 一道，垄脊亮、垄沟暗 | 底 `#4A2810`，垄脊 `#5E3418`，垄沟 `#381A08` |
| 石地 | 中灰方块面，浅灰高光块、深灰不规则裂纹 | 底 `#787878`，高光 `#989898`，裂纹 `#585858` |
| 暴露边缘色 | 方块侧面/土壤色（图中草地侧面的温棕） | `#7A5030` |

> 参考图使用等角投影，**只取顶面 2D 纹理语言**，忽略图中的侧面、阴影厚度、水体、树木、作物等场景物件。

---

### 系统原理

Godot 4 Terrain 使用"**相邻位掩码（peering bits）**"匹配：每个格子检查上下左右 4 个相邻格，若相邻格是**同类地砖**则该方向 bit=1，否则 bit=0，共 4bit = 16 种组合。系统自动从 atlas 中选出对应的图块。

```
相邻掩码编码（Top=8 Right=4 Bottom=2 Left=1，值 0–15）：

  bit3 Top    bit2 Right    bit1 Bottom    bit0 Left
  ----         ------        -------        -----
  "1" = 该方向相邻格是同类地砖（连通，内部纹理延伸）
  "0" = 该方向相邻格是不同地砖（暴露边缘，绘制过渡效果）
```

每种地砖需要 **16 张图块**（掩码 0–15），分 1 行排列：

```
掩码: 0    1    2    3    4    5    6    7    8    9    10   11   12   13   14   15
连通: 无   L    B    BL   R    LR   BR   BLR  T    TL   TB   TBL  TR   TLR  TBR  TLBR
视觉: 孤立 左连 下连 下左 右连 横条 右下 ⊤旋转 上连 上左 竖条 ⊣旋转 上右 ⊤   ⊢   全内部
```

---

### Atlas 布局

**总尺寸：1024×256 px（16 列 × 4 行，每格 64×64 px）**

- **列（col 0–15）= 相邻掩码值**（0 = 完全孤立，15 = 四面全连通/内部）
- **行（row）= 地砖类型**

| 行 | 类型 id | 名称 | 底色参考 |
|----|---------|------|---------|
| 0 | `TILE_GRASS = 0` | 草地 | 鲜亮中绿 `#4A8A28`，深绿噪点 `#336618`，高光 `#6BB030` |
| 1 | `TILE_PATH = 1` | 小路 | 沙米黄 `#C8A060`，暗粒 `#A07840`，碎石点 `#705030` |
| 2 | `TILE_FARMLAND = 2` | 耕地 | 深棕 `#4A2810`，垄脊 `#5E3418`，垄沟 `#381A08` |
| 3 | `TILE_STONE = 3` | 石地 | 中灰 `#787878`，高光 `#989898`，裂纹 `#585858` |

---

### 各图块视觉规则

**关键规则：每个图块由两部分组成**
- **连通侧**（bit=1）：用该地砖的内部纹理延伸到边缘，与相邻同类图块无缝衔接
- **暴露侧**（bit=0）：绘制过渡边缘效果，最外 2–3px 渐变为暴露边缘色 `#7A5030`（参考图方块侧面暖棕）

```
掩码 15（TLBR 全连通）= 纯内部图块：
  四边全部延伸内部纹理，完全平铺，无任何边缘效果。这是面积最大区域显示的图块。

掩码 0（无连通）= 孤立图块（四面暴露）：
  中心区域为内部纹理，四周 3px 渐变为暴露边缘色。
  草地孤立块四周有细小草尖向外探出。

掩码 5（LR 左右连通，上下暴露）= 横向条带中段：
  左右边缘无缝延伸，上下边缘绘制过渡。
  草地的上下边缘有参差不齐的草尖轮廓。

掩码 10（TB 上下连通，左右暴露）= 纵向条带中段：
  上下无缝，左右绘制过渡。
```

**各地砖暴露边缘的具体样式：**

| 地砖 | 暴露边缘样式 |
|------|------------|
| 草地 | 边缘 2–3px 草色变薄，最外 2px 为暖棕 `#7A5030`；1px 草尖不规则向外探出，轮廓参差 |
| 小路 | 边缘 2px 略浅偏干（`#D4B070`），轮廓较规整，偶有 1px 碎石粒探出 |
| 耕地 | 垄沟在暴露侧截断，最外 1px 暗棕 `#381A08`，轮廓整齐（人工开垦感） |
| 石地 | 裂纹向边缘延伸后截断，最外 2px 深灰 `#585858`，边缘略呈碎裂锯齿 |

---

### 图块绘制参考（以草地行为例）

```
col 0  (0000): 孤立草地，四边全过渡，中心草色，周边 3px 暖棕
col 1  (0001): 左接草，右/上/下三边过渡
col 2  (0010): 下接草，上/左/右三边过渡
col 3  (0011): 下左接草，上/右两边过渡（右上角圆弧草尖）
col 4  (0100): 右接草，左/上/下三边过渡
col 5  (0101): 左右接草（横条中段，上下有草尖轮廓）
col 6  (0110): 右下接草（左上角过渡）
col 7  (0111): 左右下接草（仅上边过渡，草尖向上探出）
col 8  (1000): 上接草，下/左/右三边过渡
col 9  (1001): 上左接草（右下角过渡）
col 10 (1010): 上下接草（竖条中段，左右有草尖）
col 11 (1011): 上左下接草（仅右边过渡）
col 12 (1100): 上右接草（左下角过渡）
col 13 (1101): 上右左接草（仅下边过渡）
col 14 (1110): 上右下接草（仅左边过渡）
col 15 (1111): 全连通内部，纯草地纹理，无任何过渡
```

---

### 提示词（分行生成，每次生成一行 1024×64 px）

> **生成前必读——最常见的错误：**
> - ❌ 等角/斜视角方块（每格下半部分出现暗色侧面） → 整行作废
> - ❌ 16 列图块全部相同，没有边缘过渡差异 → 需要重新生成
> - ❌ 画了树/草丛/水/作物/场景物件 → 整行作废
> - ✅ 正确：每格整个 64×64 区域都是纯粹的地面顶面纹理，**像从正上方垂直俯视看到的地面**

**通用前缀（每行都加）：**

```
Pixel art terrain tile strip. CRITICAL PERSPECTIVE: pure 2D flat top-down view,
as if looking STRAIGHT DOWN from directly above — like a satellite/bird's eye view.
The entire 64x64 tile area is filled with flat ground surface texture.
NO isometric angle, NO axonometric projection, NO visible block sides or edges,
NO voxel depth, NO 3D perspective, NO shadows from block height.
If any tile shows a dark bottom edge or side face: generation is WRONG.

Reference material texture from: Minecraft voxel island top-face textures
(vivid grass, sandy path, dark farmland, grey stone). Color palette and pixel
style only — NOT the isometric 3D shape. Use ONLY the flat top-face colors.

NO transparent background. Opaque fill. Seamless tiling.

Canvas: 1024x64 pixels. 16 cells in one row, each cell 64x64 pixels. No padding, no gaps.
This is ONE ROW of a terrain autotile blob tileset for a 2D top-down game.
Each cell is a different edge-connection variant (bitmask 0–15, columns left to right).

CONNECTED SIDE (bit=1): terrain texture extends fully to that tile edge — seamless join.
EXPOSED SIDE (bit=0): draw a 4-6px fringe at that tile edge, transitioning in
pixel-perfect hard steps (1-2px per color band) toward warm earth brown #7A5030.
NO anti-aliasing, NO smooth gradients — each step must be a solid block of color.
The fringe must be visibly distinct from the interior.
CRITICAL: col 5 (left+right connected, top+bottom exposed) MUST look noticeably different
from col 15 (all connected/interior). If they look the same: WRONG.
CRITICAL: every exposed-edge tile must show the brown fringe on the exposed sides —
the fringe must be visible and clearly different from the terrain surface color.

Do NOT draw: isometric blocks, voxel side faces, trees, crops, water, props, shadows.
Do NOT use anti-aliasing or sub-pixel blending anywhere in the image.
```

**行 0 — 草地（Grass）：** 在通用前缀后追加：

```
TERRAIN TYPE: grass — vivid medium green top face #4A8A28, scattered darker green square
pixel clusters #336618 (~30% coverage), bright yellow-green highlight pixels #6BB030,
occasional 1-2px upward grass blade tips. Matches the bright grass block top faces in
the voxel island reference — saturated, clean, NOT warm golden or brown.

EXPOSED SIDE specifics: outermost 2px fade to #7A5030, with 1-2px irregular green grass
blade tips poking outward along the exposed edge, organic uneven silhouette.

The 16 cells (bitmask TRBL, T=Top R=Right B=Bottom L=Left, 1=connected):
  Col 0  [0000]: isolated — all 4 sides exposed, grass center, earth fringe all around
  Col 1  [0001]: left connected — right/top/bottom exposed
  Col 2  [0010]: bottom connected — top/left/right exposed
  Col 3  [0011]: bottom+left — top/right exposed, top-right corner has square-pixel fringe meeting point
  Col 4  [0100]: right connected — left/top/bottom exposed
  Col 5  [0101]: left+right — horizontal strip, top/bottom exposed with blade fringe
  Col 6  [0110]: right+bottom — left/top exposed, top-left corner has square-pixel fringe meeting point
  Col 7  [0111]: left+right+bottom — only top exposed, grass blades pointing up
  Col 8  [1000]: top connected — bottom/left/right exposed
  Col 9  [1001]: top+left — bottom/right exposed, bottom-right corner has square-pixel fringe meeting point
  Col 10 [1010]: top+bottom — vertical strip, left/right exposed with blade fringe
  Col 11 [1011]: top+left+bottom — only right exposed
  Col 12 [1100]: top+right — bottom/left exposed, bottom-left corner has square-pixel fringe meeting point
  Col 13 [1101]: top+right+left — only bottom exposed, grass blades pointing down
  Col 14 [1110]: top+right+bottom — only left exposed
  Col 15 [1111]: all connected — pure interior grass texture, no fringe anywhere

Minecraft voxel pixel art, seamless autotile grass strip
```

**行 1 — 小路（Path）：** 通用前缀 + 替换 TERRAIN TYPE 和 EXPOSED SIDE：

```
TERRAIN TYPE: sandy dirt path — warm beige top face #C8A060, organic gritty pixel clusters
in tan #A07840 (~40% coverage), scattered 1-2px dark pebble pixels #705030.
Matches the sandy path/dirt block top faces in the voxel reference — beige-yellow, grainy.

EXPOSED SIDE specifics: outermost 2px lighten to dry sandy #D4B070, occasional 1px pebble
pixel at edge, fringe is subtle and roughly rectangular but slightly uneven.

[Same 16-cell bitmask layout as grass strip above]

Minecraft voxel pixel art, seamless autotile path strip
```

**行 2 — 耕地（Farmland）：** 通用前缀 + 替换：

```
TERRAIN TYPE: tilled farmland — deep chocolate brown base #4A2810, horizontal furrow lines
with a strict 4px repeat (1px ridge #5E3418 then 3px furrow gap #381A08, starting at y=0).
Furrows MUST be phase-locked: the pattern starts at y=0 so rows align pixel-perfectly
across all tiles. Matches dark tilled soil in voxel reference.

EXPOSED SIDE specifics: furrows terminate cleanly at the exposed edge (1px dark #381A08).
Edge boundary is relatively straight — man-made field feel, minimal organic fringe.

[Same 16-cell bitmask layout as grass strip above]

Minecraft voxel pixel art, seamless autotile farmland strip
```

**行 3 — 石地（Stone）：** 通用前缀 + 替换：

```
TERRAIN TYPE: stone ground — mid grey top face #787878, irregular crack line patterns
(NOT regular grid noise), light grey square highlight patches #989898, dark grey crevices
#585858. Matches grey stone block top faces in the voxel reference — blocky, clean.

EXPOSED SIDE specifics: outermost 2px darken to #585858, crack lines approach edge and
terminate. Edge has slight jagged pixel variation — broken stone feel.

[Same 16-cell bitmask layout as grass strip above]

Minecraft voxel pixel art, seamless autotile stone strip
```

---

> **代码已就绪**：`world_generator.gd` 自行计算每格的 4 位掩码（检查上下左右相邻格是否同类型），直接用 `set_cell(Vector2i(mask, tile_type))` 写入 atlas 坐标，不依赖 Godot Terrain 系统。你只需提供符合以下布局的 atlas 图片即可直接运行。

---

### 当前状态

| 文件 | 尺寸 | 状态 |
|------|------|------|
| `assets/sprites/environment/ground_tiles.png` | **1024×256**（16列×4行，每格64×64） | ⚠️ 当前为程序化合成版，待用上方 AI 提示词重新直出 |

**生成方式**：用上方提示词为 4 种地形各直接生成一张 **1024×64 px 条带**（16 格一行，每格 64×64，边缘过渡由 AI 绘制），再用合成脚本垂直拼合。

- 不再用平铺原材质 + 程序化叠色的方式
- 每张条带 AI 直出，边缘质量由提示词控制
- 合成脚本只做 NEAREST 缩放对齐和垂直拼合，不再处理边缘

**合成命令**（4 张条带生成后执行）：

```bash
python3 tools/build_ground_tiles_atlas.py \
  --grass  path/to/grass_strip_1024x64.png \
  --path   path/to/path_strip_1024x64.png \
  --farmland path/to/farmland_strip_1024x64.png \
  --stone  path/to/stone_strip_1024x64.png
# 默认输出到 assets/sprites/environment/ground_tiles.png
```

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

---

## 主菜单专用美术

> 主菜单采用独立的暖木/羊皮纸风格，与游戏内 UI 的深灰石头风格分开。参考 `docs/references/main_menu_concept_v1.png`。

### 资产列表

| 文件 | 尺寸 | 9-patch 边距 | 用途 | 状态 |
|------|------|------------|------|------|
| `assets/sprites/ui/main_menu_bg.png` | 1280×720 | — | 全屏背景插图 | ⏳ 待生成 |
| `assets/sprites/ui/title_land.png` | 384×128 | — | "Land" 装饰标题 Logo | ⏳ 待生成 |
| `assets/sprites/ui/panel_wood.png` | 192×192 | 32px | 存档槽面板木质框（9-patch） | ⏳ 待生成 |
| `assets/sprites/ui/slot_frame.png` | 192×80 | 12px | 单个存档槽内框（9-patch） | ⏳ 待生成 |
| `assets/sprites/ui/save_thumb_farm.png` | 128×80 | — | 有存档时的缩略图（农场场景） | ⏳ 待生成 |
| `assets/sprites/ui/save_thumb_empty.png` | 128×80 | — | 空存档位缩略图（灰色占位） | ⏳ 待生成 |
| `assets/sprites/ui/menu_icons.png` | 128×32 | — | 图标条带：叶片/齿轮/出门，各 32×32 | ⏳ 待生成 |
| `assets/sprites/ui/btn_green.png` | 192×48 | 16px | 绿色按钮（检查更新），3态竖排 192×144 | ⏳ 待生成 |
| `assets/sprites/ui/btn_brown.png` | 192×48 | 16px | 棕色按钮（退出游戏），3态竖排 192×144 | ⏳ 待生成 |
| `assets/sprites/ui/icon_trash.png` | 32×32 | — | 红色垃圾桶图标（删除存档） | ⏳ 待生成 |

---

### 提示词

**1. 主菜单背景（main_menu_bg.png）**

```
Pixel art game main menu background, 1280x720 pixels.
Warm dusk/sunset scene: orange-purple gradient sky, silhouette of pine trees in background.
Center-left: cozy wooden log cabin farmhouse with lit windows (warm yellow glow inside),
thatched or wooden roof, stone chimney. Foreground: small garden with corn crops and
flower bushes, low wooden fence, one garden lantern with warm light glow.
Right side: some wooden crates and barrels stacked. Ground is dark green grass.
Overall mood: warm, cozy, inviting. Rich pixel art detail, Stardew Valley aesthetic.
No characters, no UI elements, no text.
Pixel art style, 16-bit color palette, dithering for sky gradient, detailed background scene.
```

**2. "Land" 标题 Logo（title_land.png）**

```
Pixel art game title logo, 384x128 pixels, transparent background.
The word "LAND" in large decorative pixel lettering.
Style: carved wooden sign / medieval tavern sign aesthetic.
Letters are thick blocky pixel art, warm golden-brown color (#C8901A),
with darker brown outline/shadow (#7A4A10) and bright highlight pixels (#F0C060)
on top-left of each letter stroke. Slight wood grain texture implied.
No border frame, just the text. Centered on canvas.
Pixel art, game logo style, transparent background.
```

**3. 木质面板框 9-patch（panel_wood.png）**

```
Pixel art decorative wooden panel frame, 192x192 pixels.
Warm brown wood texture fill (#8B5A2B base, #6B3A1B darker grain lines, #A07040 highlight).
Border: 32px thick decorative carved wood frame on all sides.
Corners: slightly ornate square carved detail.
Interior: slightly lighter warm parchment/paper fill (#D4B88A).
Clean hard pixel edges, no gradients, 2-3 tone shading per wood plank face.
Suitable for 9-slice scaling with 32px corner margins.
Minecraft-style pixel art, transparent background not needed (opaque fill).
```

**4. 单存档槽内框 9-patch（slot_frame.png）**

```
Pixel art save slot inner frame, 192x80 pixels.
Thin decorative border (12px) in warm dark wood (#5A3010).
Interior fill: slightly darker parchment (#C4A87A), slightly recessed look.
Left 100px area: darker recessed box for thumbnail preview (#9A7850 border, #3A2810 fill).
Right area: lighter for text content.
Hard pixel edges, no gradients.
Suitable for 9-slice scaling with 12px margins.
```

**5. 存档缩略图（save_thumb_farm.png）**

```
Pixel art farm scene thumbnail, 128x80 pixels.
Top-down slightly angled view of a small farm: green grass field,
small farmhouse silhouette top-left, plowed soil rows center, one tree.
Warm afternoon lighting, saturated colors.
Stardew Valley pixel art style, very small scale, readable key shapes.
No UI, no text.
```

**6. 空档位缩略图（save_thumb_empty.png）**

```
Pixel art empty placeholder thumbnail, 128x80 pixels.
Dark grey/brown muted background (#3A3028), simple pixel art question mark "?"
in center in medium grey (#787060), subtle border.
Implies "no save data". Dark and subdued.
Pixel art style.
```

**7. 图标条带（menu_icons.png）**

```
Pixel art icon strip, 128x32 pixels, 4 icons side by side (each 32x32), transparent background.
Icon 1 (col 0): green leaf — simple 2-3 tone pixel leaf shape, bright green
Icon 2 (col 1): gear/cog — grey mechanical gear, 8-tooth, pixel art
Icon 3 (col 2): door with arrow — brown wooden door with right-pointing arrow, "exit" symbol
Icon 4 (col 3): trash bin — red open-top bin with vertical line detail, delete symbol
Hard square pixel edges, flat 2-3 tone fills, Minecraft inventory icon style.
```

**8. 绿色按钮 3-态（btn_green.png）**

```
Pixel art button sprite sheet, 192x144 pixels, 3 states stacked vertically (each 192x48).
Color scheme: green (#4A8A3A base, #336628 dark, #6BB050 highlight).
State 0 (normal): flat green slab with lighter top-left edge highlight, dark bottom-right edge.
State 1 (hover): slightly brighter green, 2px bright pixel outline on top and left.
State 2 (pressed): darker green, no top highlight, slight inset look.
All states: 16px rounded-square border in darker green. Hard pixel edges, no gradients.
Minecraft-style pixel art button, opaque.
```

**9. 棕色按钮 3-态（btn_brown.png）**

```
Pixel art button sprite sheet, 192x144 pixels, 3 states stacked vertically (each 192x48).
Color scheme: warm brown/tan (#8B6040 base, #6B4020 dark, #B08060 highlight).
Same structure as green button above but with warm brown palette.
State 0 (normal): flat brown slab with highlight/shadow edges.
State 1 (hover): slightly lighter, pixel outline.
State 2 (pressed): darker, inset look.
Minecraft-style pixel art button, opaque.
```
