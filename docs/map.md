# 地图生成规范

## 设计图规格

| 参数 | 值 |
|------|----|
| 图片尺寸 | 400 × 400 px |
| 格式 | PNG，无损 |
| 色深 | RGB（无需 alpha） |
| 1 px | = 1 游戏格子 |
| 存放路径 | `res://assets/maps/` |

---

## 地图命名与连接规范

### 树形命名

地图以树形结构组织，文件名即表达层级关系：

```
assets/maps/
├── 0.png          # 起始地图（根节点）
├── 0-0.png        # 0.png 的第 0 个分支
├── 0-1.png        # 0.png 的第 1 个分支
├── 0-2.png        # 0.png 的第 2 个分支（最多 3 个）
├── 0-0-0.png      # 0-0.png 的分支，以此类推
└── ...
```

规则：
- `0.png` 固定为起始地图
- 每张地图最多 **3 个** next 出口（next-0、next-1、next-2）
- 父地图由文件名直接推断，`0-1.png` 的父一定是 `0.png`，无需额外记录

### 像素标记

地图切换的入口/出口直接编码在 PNG 像素中，无需配置文件。

| 标记 | Hex | 说明 |
|------|-----|------|
| next-0 出口 | `#FF0000` | 走到此格 → 加载 `X-0.png` |
| next-1 出口 | `#FF6600` | 走到此格 → 加载 `X-1.png` |
| next-2 出口 | `#FF00FF` | 走到此格 → 加载 `X-2.png` |
| prev 入口   | `#0000FF` | 从子图返回时玩家出现的位置 |

规则：
- 每种标记颜色在同一张图中**只能出现一次**
- 触发范围：玩家进入标记像素**半径 2 格**内即触发切换
- `0.png` 没有 prev 入口（根节点无父级）
- 标记像素本身不渲染为地形，由代码拦截处理

### 切换逻辑

```
玩家踩到 next-0 → 加载 X-0.png → 玩家出现在 X-0.png 的 prev 位置
玩家踩到 prev   → 加载父地图    → 玩家出现在父地图对应 next-X 位置
```

### 设计示例

```
0.png 中放置：
  #FF0000 像素 → 通往森林区 (0-0.png)
  #FF6600 像素 → 通往矿洞区 (0-1.png)
  #0000FF 像素 → 不需要（根节点）

0-0.png 中放置：
  #0000FF 像素 → 返回 0.png，玩家出现在 0.png 的 #FF0000 处
  #FF0000 像素 → 可选，继续深入 (0-0-0.png)
```

---

---

## 颜色编码

| 地形 | Hex | 说明 |
|------|-----|------|
| 草地 | `#4A8A28` | 主要开阔地 |
| 耕地 | `#7B5C2A` | 玩家农场区，放在地图中心 |
| 路径 | `#C8A850` | 小道，从农场向外辐射 |
| 石地 | `#808080` | 岩石区域 |
| 深石 | `#404040` | 地图边缘/悬崖 |

生成后在 Aseprite / Photoshop 中把颜色量化为以上标准色（魔棒 + 填充），再缩放到精确 400×400 px 导出。

---

## AI 生成提示词

适用于 Midjourney、DALL-E、Stable Diffusion。

### 主提示词

```
top-down 2D game world map layout, pixel art style, 400x400 grid,
flat view directly from above, NO isometric angle, NO 3D perspective,
color-coded terrain zones only, flat solid colors NO gradients NO textures NO shadows,
colors: bright green #4A8A28 grassland, dark brown #7B5C2A farmland at center,
sand yellow #C8A850 dirt paths, medium gray #808080 rocky stone areas,
dark gray #404040 cliff edges at border.
Layout: farmland cluster at center radius 8% of map,
surrounded by large open grassland, rocky mountains towards outer edges,
2 to 3 dirt paths radiating outward from farmland,
organic irregular shapes, NO straight lines, NO grid pattern,
simple schematic suitable for game map programming reference
```

### 限制词（Negative Prompt）

```
isometric, 3D, perspective, shadow, gradient, texture, realistic,
decorative art, anti-aliasing, blur, noise, dithering,
trees, icons, labels, UI elements
```

### 风格变体

在主提示词末尾追加以下任意一条，生成不同风格地图：

| 风格 | 追加词 |
|------|--------|
| 平原（默认） | `large open grassland, minimal stone` |
| 多石 | `heavy rocky terrain, stone dominates outer 40%` |
| 丛林感 | `dense inner grassland, narrow paths, thick stone border` |
| 河道 | `river channel splitting map diagonally, no stone on river` |

---

## 设计要点

- 耕地在地图**正中心**，轮廓不规则（非完美圆）
- 路径从耕地边缘出发，2~4 条，走向弯曲
- 石地从半径 60% 处开始出现，越靠边越密
- 四角为最密集深石，形成天然边界感
