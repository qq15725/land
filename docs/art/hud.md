# 美术：HUD 布局

> **参考图（强制）**：[`docs/references/hud.png`](../references/hud.png)
>
> 本目录所有 HUD 部件**必须**基于该参考图生成。提示词只写**结构 / 位置 / 尺寸**要求，**风格、配色、描边、字体观感**全部由参考图控制 —— 不要在提示词里描述像素风格、Minecraft 风、配色、圆角等，避免与参考图产生分歧导致风格不统一。
>
> 生成流程：参考图 + 本文档对应部件 §部件规格 描述 → 一次只生成一个部件 → 透明背景 PNG。

整张 HUD 由若干**独立部件**组成，每个部件单独出图，不合并到 `ui_sheet.png`，便于按分辨率/移动端单独替换。

## 区域总览

| 区域 | 锚点 | 内容 |
|------|------|------|
| 角色信息条 | 左上 | 头像框 + 名字 + 等级 + HP 条 + XP 条 |
| 任务追踪条 | 顶部居中 | 任务名 + 进度 + 任务图标（可选） |
| 菜单按钮组 | 右上 | 角色 / 地图 / 设置 三个按钮 |
| 小地图 | 右上（菜单按钮下方） | 圆形地图 + 指南针刻度 + 坐标条 |
| 快捷栏 | 底部居中 | 经验/技能进度条 + 9 格物品栏 |
| 状态栏 | 底部偏左 | 时间/天气 + Buff 图标条 |
| 资源计数 | 底部偏右 | 金币 / 关键资源数量 / 背包按钮 |
| 移动摇杆 | 左下（移动端） | 8 方向 D-pad |
| 操作按钮 | 右下（移动端） | 攻击 / 跳跃 / 交互 |

---

## 部件规格

> 每个部件下方只列**结构和尺寸**。材质、颜色、边框宽度等以参考图为准 —— 生成时把 [`docs/references/hud.png`](../references/hud.png) 作为附图，不需要在提示词里复述这些。

### 1. 角色信息条 `assets/sprites/ui/hud_charinfo.png`

源尺寸：**320×96 px**

结构（参考图左上）：
- 头像框 64×64 px（9-patch 角 16px）
- 右侧上排：名字 Label + 等级徽章 32×32 px
- 右侧下排：HP 条 192×16 px（底+填充两层）+ XP 条 192×16 px（底+填充两层）

### 2. 任务追踪条 `assets/sprites/ui/hud_quest.png`

源尺寸：**320×64 px**，9-patch 横向可拉伸，角 16px

结构（参考图顶部居中）：
- 主体木牌，左侧任务名 + 进度，右上角 24×24 px 状态图标位

### 3. 菜单按钮 `assets/sprites/ui/hud_menubtn.png`

源尺寸：**192×64 px**（横排 3 状态：normal / hover / pressed，每态 64×64 px）

结构（参考图右上）：
- 单态空按钮容器
- 三个语义图标各自独立出图：`hud_icon_char.png` / `hud_icon_map.png` / `hud_icon_settings.png`，各 32×32 px

### 4. 小地图框 `assets/sprites/ui/hud_minimap.png`

源尺寸：**192×192 px**

结构（参考图右上指南针）：
- 圆形外环 + 内圆透明区（地图由代码绘制）
- 外环上 N / E / S / W 4 个方位标记
- 配套坐标条 `hud_coord.png`：160×24 px，9-patch 横向可拉伸

### 5. 快捷栏 `assets/sprites/ui/hud_hotbar.png`

源尺寸：**640×128 px**

结构（参考图底部居中，**关键参考区域**）：

| 元素 | 尺寸 | 说明 |
|------|------|------|
| 经验/技能条 | 576×16 px（底+填充两层） | 中间留 32×24 px 等级徽章位 |
| 等级徽章 | 32×24 px | 数字由代码绘制，仅出底框 |
| 槽位容器 9-patch | 576×80 px，角 16px | 可横向拉伸 |
| 物品格 | 64×64 px × 9 | 等距横排 |
| 选中态高亮 | 80×80 px，9-patch 角 16px | 覆盖物品格外延 8px，与参考图槽位 4 的高亮态一致 |
| 数量徽章 | 24×16 px | 置于格子右下 |

> 当前代码（`hud.gd`）已经实现 9 格 + 1–9 数字键选中。重出美术时，槽位间距对齐到 64×64，选中边框单独导出。

### 6. 状态栏 `assets/sprites/ui/hud_statusbar.png`

源尺寸：**384×64 px**，9-patch 横向可拉伸

结构（参考图底部偏左）：
- 左半：时间图标 32×32 + 时间文字 + 天气图标 32×32
- 右半：Buff 图标横排，每个 32×32 px，下方 24×8 px 持续时间小条

### 7. 资源计数 `assets/sprites/ui/hud_resources.png`

源尺寸：**384×64 px**，9-patch 横向可拉伸

结构（参考图底部偏右）：
- 多个「图标 32×32 + 数字」单元横排
- 末端 64×64 px 背包按钮

### 8. 移动摇杆 `assets/sprites/ui/hud_dpad.png`

源尺寸：**256×256 px**（仅移动端）

结构（参考图左下）：
- 8 方向 D-pad，中心实心按钮 64×64，外围 4 方向 + 4 对角，各 64×64

### 9. 操作按钮组 `assets/sprites/ui/hud_actionbtns.png`

源尺寸：**192×192 px**（仅移动端）

结构（参考图右下）：
- 3 个 96×96 按钮 L 形排列
- 图标位 48×48：剑（攻击）/ 上箭头（跳跃 / 交互）/ 背包，三个图标单独出

---

## AI 提示词模板

**核心约束**：提示词只描述**结构和元素**，不描述风格、配色、边框样式 —— 这些全部由参考图 `docs/references/hud.png` 提供。每次生成都把参考图作为附图传入，并加上模板：

```
Generate a single UI element. The attached reference image defines the entire
visual style — match its palette, border, material, and pixel density exactly.
Transparent background. No scene, no text, no watermark.

Element: <部件名，如 "hotbar slot row"，对应 §部件规格 章节>
Composition: <按 §部件规格 列出的结构，例如 "9 square item slots in a horizontal
row, each slot 64x64 pixels, evenly spaced inside a 9-patch container panel">
Output size: <部件源尺寸>
```

**禁止**在提示词里出现：
- 风格词："Minecraft style"、"pixel art"、"flat colors"、"hard edges"
- 配色："dark grey"、"wood brown"、"bright yellow"
- 装饰："rounded corners"、"glow"、"shadow"

这些都通过参考图传达，避免 AI 二次解读导致风格漂移。

如需变体（如选中态高亮），单独出一张图，参考图依旧用同一张 `hud.png`，提示词描述差异点（"the same hotbar slot but with a bright outer border indicating it's selected, color matching the highlight already shown on slot 4 in the reference"）。
