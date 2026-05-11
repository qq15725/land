# 美术：地砖（TileMap Terrain — Blob Autotile）

## 系统概述

使用 Godot 4 `TERRAIN_MODE_MATCH_CORNERS_AND_SIDES`（blob 模式）。  
代码调用 `set_cells_terrain_connect()`，引擎自动选 tile，无需手写 bitmask。

**每种地形独立一张 atlas 图片，共 4 张。**

---

## 生成工作流

**所有美术资源统一流程：**

1. 用户先生成/提供**参考图**，确定整体风格（色调、像素粒度、光影风格）
2. 将参考图路径写入提示词，以参考图为视觉基准生成具体资源
3. 这样风格一致性由参考图控制，提示词只描述结构要求

```
参考图：docs/references/terrain.png
```

> 参考图为等角投影 voxel 像素小岛。**只取顶面 2D 纹理语言**，忽略侧面、阴影厚度、水体、树木等场景物件。

---

## Atlas 规格

| 参数 | 值 |
|------|-----|
| 每格像素 | 64×64 px |
| 网格 | 8 列 × 6 行 = 48 slot（47 用，最后一格空） |
| 单张图片尺寸 | **512×384 px** |
| 世界格大小 | 16×16 px（zoom=4 时屏幕 64px，1:1 采样） |

**4 张独立文件：**

| 文件 | 地形 |
|------|------|
| `assets/sprites/environment/terrain_grass.png` | 草地 |
| `assets/sprites/environment/terrain_path.png` | 小路 |
| `assets/sprites/environment/terrain_farmland.png` | 耕地 |
| `assets/sprites/environment/terrain_stone.png` | 石地 |

---

## Blob 47 Tile 原理

8-bit peering（4 边 + 4 角），角只在两侧边都连通时有意义：

```
连通侧（bit=1）：纹理延伸到边缘，与邻格无缝
未连通侧（bit=0）：绘制过渡边缘（fringe）
已连通角（两侧边都连通且角 bit=1）：该角填充地形（凸角，内部感）
未连通角（两侧边都连通但角 bit=0）：该角出现内凹缺口（concave corner）
```

与 16-tile 的关键差别在最后两条：blob 能区分凸角和凹角，地形过渡更自然。

---

## Atlas 布局（47 tile 在 8×6 中的位置）

行列编号从 0 开始，`idx = row*8 + col`。

```
row\col  0      1      2      3      4      5      6      7
  0    [  0]  [  1]  [  2]  [  3]  [  4]  [  5]  [  6]  [  7]
  1    [  8]  [  9]  [ 10]  [ 11]  [ 12]  [ 13]  [ 14]  [ 15]
  2    [ 16]  [ 17]  [ 18]  [ 19]  [ 20]  [ 21]  [ 22]  [ 23]
  3    [ 24]  [ 25]  [ 26]  [ 27]  [ 28]  [ 29]  [ 30]  [ 31]
  4    [ 32]  [ 33]  [ 34]  [ 35]  [ 36]  [ 37]  [ 38]  [ 39]
  5    [ 40]  [ 41]  [ 42]  [ 43]  [ 44]  [ 45]  [ 46]  [空白]
```

各 idx 对应的连通情况（N/E/S/W 边 + 有效角）：

```
idx  sides  corners   描述
  0  ----   -         孤立，四边都是 fringe
  1  ---W   -         仅左连
  2  --S-   -         仅下连
  3  --SW   sw=0      左下连，无内角填充
  4  --SW   sw=1      左下连，有内角填充（凸角）
  5  -E--   -         仅右连
  6  -E-W   -         左右连（横条）
  7  -ES-   se=0      右下连，无内角
  8  -ES-   se=1      右下连，有内角
  9  -ESW   se=0,sw=0 三面连（上开），无角
 10  -ESW   se=1,sw=0 三面连，右下有内角
 11  -ESW   se=0,sw=1 三面连，左下有内角
 12  -ESW   se=1,sw=1 三面连，两角都填充
 13  N---   -         仅上连
 14  N--W   nw=0      左上连，无内角
 15  N--W   nw=1      左上连，有内角
 16  N-S-   -         上下连（竖条）
 17  N-SW   sw=0,nw=0 左上下连，无角
 18  N-SW   sw=1,nw=0 左上下连，左下有内角
 19  N-SW   sw=0,nw=1 左上下连，左上有内角
 20  N-SW   sw=1,nw=1 左上下连，两角
 21  NE--   ne=0      右上连，无内角
 22  NE--   ne=1      右上连，有内角
 23  NE-W   ne=0,nw=0 右上左连，无角
 24  NE-W   ne=1,nw=0 右上左连，右上有内角
 25  NE-W   ne=0,nw=1 右上左连，左上有内角
 26  NE-W   ne=1,nw=1 右上左连，两角
 27  NES-   ne=0,se=0 右上下连，无角
 28  NES-   ne=1,se=0 右上下连，右上有内角
 29  NES-   ne=0,se=1 右上下连，右下有内角
 30  NES-   ne=1,se=1 右上下连，两角
 31  NESW   全无角     四面全连，四个凹角缺口（最"外缘内部"）
 32  NESW   ne        四面连，仅右上角填充
 33  NESW   se        四面连，仅右下角填充
 34  NESW   ne,se     四面连，右两角填充
 35  NESW   sw        四面连，仅左下角填充
 36  NESW   ne,sw
 37  NESW   se,sw
 38  NESW   ne,se,sw
 39  NESW   nw        四面连，仅左上角填充
 40  NESW   ne,nw
 41  NESW   se,nw
 42  NESW   ne,se,nw
 43  NESW   sw,nw
 44  NESW   ne,sw,nw
 45  NESW   se,sw,nw
 46  NESW   全有角     四面全连，四角全填充（纯内部格）
```

---

## 视觉规则

| 情况 | 画法 |
|------|------|
| 连通侧 | 纹理延伸到像素边缘，无任何过渡 |
| 未连通侧 | 边缘 4–6px fringe，渐变为该地形的"暴露边缘色" |
| 已连通角（idx 有 corner=1） | 角落填满本地形纹理（凸角填充） |
| 未连通角（idx 有 corner=0，但两侧边连通） | 角落出现 fringe 缺口（凹角内切） |

---

## 生成提示词

**通用前缀（每张图都加）：**

```
Reference image: docs/references/terrain.png
This image shows an isometric voxel pixel-art island. Extract ONLY the flat top-face
surface texture of [TERRAIN] — ignore all side faces, shadows, block thickness,
trees, crops, water, and any scene objects. Treat the top face as a pure 2D texture
viewed straight down from above.

Generate a 512×384 pixel terrain autotile atlas in blob (MATCH_CORNERS_AND_SIDES) format.
Pixel art. Pure 2D flat top-down view — NO isometric angle, NO voxel sides, NO shadows.
Grid: 8 columns × 6 rows, each cell 64×64 pixels. Last cell (col=7, row=5) leave empty.

47 blob terrain tiles in row-major order (idx=row*8+col, see layout table).
  Connected side: texture extends seamlessly to that pixel edge.
  Exposed side: 4–6 px fringe, stepping in 1–2 px hard bands toward the terrain's
                border/edge color. No anti-aliasing, no smooth gradients.
  Filled corner (corner=1): terrain fills that corner — no notch.
  Notched corner (corner=0, both adjacent sides connected): small concave cutout
                in that corner, showing the border fringe color.

Seamless: all tiles must tile with neighbors without visible seams.
Hard pixel edges only. No anti-aliasing anywhere.
```

**草地（terrain_grass.png）：** 通用前缀，`[TERRAIN]` = ：

```
the GRASS top faces (the vivid green horizontal surfaces).
Base color: bright medium green ~#4A8A28.
Texture: scattered darker green square pixel clusters (~30% coverage) and
occasional bright yellow-green highlight pixels. Slightly irregular organic noise.
Border/fringe color: warm brown ~#7A5030 (the earth seen at block edges in the reference).
Exposed edge: 2–3 px grass color thinning then 2 px warm brown; 1–2 px irregular
grass-tip pixels poking outward along exposed sides.
```

**小路（terrain_path.png）：** 通用前缀，`[TERRAIN]` = ：

```
the PATH / dirt road top faces (the sandy-brown diagonal path surface).
Base color: warm beige ~#C8A060.
Texture: organic gritty pixel clusters in tan ~#A07840, scattered 1–2 px dark
pebble pixels ~#705030.
Border/fringe color: slightly lighter dry sand ~#D4B070.
Exposed edge: 2 px subtle lightening, roughly rectangular, minimal organic variation.
```

**耕地（terrain_farmland.png）：** 通用前缀，`[TERRAIN]` = ：

```
the TILLED FARMLAND top faces (the dark brown plowed soil in the farm area).
Base color: deep chocolate brown ~#4A2810.
Texture: strict horizontal furrow lines — 1 px ridge #5E3418 then 3 px furrow gap
#381A08, repeating from y=0. Furrows MUST be phase-locked across all tiles.
Border/fringe color: darkest furrow brown #381A08.
Exposed edge: furrows terminate cleanly, 1 px dark edge, relatively straight
(man-made feel, minimal organic variation).
```

**石地（terrain_stone.png）：** 通用前缀，`[TERRAIN]` = ：

```
the STONE / rocky ground top faces (the grey rocky terrain in the upper-right area).
Base color: medium grey ~#787878.
Texture: irregular crack/crevice lines (not regular grid), light grey square
highlight patches ~#989898, dark grey crevices ~#585858. Block-like, clean.
Border/fringe color: dark grey ~#585858.
Exposed edge: 2 px darkening, crack lines approach edge and terminate, slight
jagged pixel variation — broken stone feel.
```

---

## 当前状态

| 文件 | 状态 |
|------|------|
| `terrain_grass.png` | ❌ 待生成（fallback 占位中） |
| `terrain_path.png` | ❌ 待生成 |
| `terrain_farmland.png` | ❌ 待生成 |
| `terrain_stone.png` | ❌ 待生成 |
| 参考图 | ✅ `docs/references/terrain.png` |
