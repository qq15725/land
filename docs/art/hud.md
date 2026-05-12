# 美术：HUD 布局

> **参考图（强制）**：[`docs/references/hud.png`](../references/hud.png)
>
> 本目录所有 HUD 部件**必须**基于该参考图生成。提示词只写**结构 / 位置 / 尺寸**要求，**风格、配色、描边、字体观感**全部由参考图控制 —— 不要在提示词里描述像素风格、Minecraft 风、配色、圆角等，避免与参考图产生分歧导致风格不统一。
>
> 生成流程：参考图 + 本文档对应部件 §部件规格 描述 → 一次只生成一个部件 → 透明背景 PNG。

整张 HUD 由若干**独立部件**组成，每个部件单独出图，不合并到 `ui_sheet.png`，便于按分辨率/移动端单独替换。

## 区域总览（按参考图分区，逆时针）

| 区域 | 锚点 | 内容 |
|------|------|------|
| ① 角色信息条 | 左上 | 头像 + 名字 + Lv + **3 条进度条**（HP / XP / 耐力） |
| ② Buff 条 | 顶部居中-左 | 横排状态效果图标，带剩余时间 |
| ③ 环境信息条 | 顶部居中 | 昼夜图标 + 时间数字 + 天气图标 |
| ④ 事件提示条 | 顶部居中-右 | 高优事件倒计时（怪物入侵 / 商人将至） |
| ⑤ 小地图框 | 右上 | 圆形地图 + 指南针 N/E/S/W + 兴趣点图钉 + 坐标条 |
| ⑥ 任务追踪条 | 小地图下方 | 多任务列表，每条「任务名 + 当前/目标」，可展开/折叠 |
| ⑦ 快捷栏 | 底部居中 | **上方经验/技能进度条 + 中央等级徽章 + 9 格物品栏** |
| ⑧ 移动控制 | 左下（移动端） | 8 方向 D-pad / 虚拟摇杆 |
| ⑨ 交互按钮 | 左下移动控制旁（移动端） | 攻击 / 拾取 / 对话 圆按钮组 |
| ⑩ 技能栏 | 右下 | 4 个圆形技能图标 + 冷却遮罩 |
| ⑪ 底部信息行 | 底部 | 资源/货币 + 装备耐久 + 基地防御 三个并列子条 |
| ⑫ 危险边框特效 | 全屏外圈（特效层） | 屏幕外缘红色脉冲遮罩，仅在危险事件触发时显示 |

---

## 部件规格

> 每个部件下方只列**结构和尺寸**。材质、颜色、边框宽度等以参考图为准 —— 生成时把 [`docs/references/hud.png`](../references/hud.png) 作为附图，不需要在提示词里复述这些。

### ① 角色信息条 `assets/sprites/ui/hud_charinfo.png`

源尺寸：**320×128 px**

结构（参考图左上）：
- 左侧头像框 64×64 px（9-patch 角 16px，留 4px 内描边）
- 右侧上排：名字 Label + Lv 徽章 32×32 px
- 右侧下方 **3 条进度条**，每条 192×16 px（底+填充两层，叠加显示数字 "当前/上限"）：
  - 行 1：HP（红）
  - 行 2：XP（蓝） —— 显示总角色等级累积进度
  - 行 3：耐力 / 饥饿（绿）

> 当前代码层只接通 HP；XP 接 SkillSystem 总累计；耐力先固定 100/100。

### ② Buff 条 `assets/sprites/ui/hud_buff_slot.png`

单格源尺寸：**56×56 px**（图标 32×32 居中 + 4px 边 + 底部 24×8 px 剩余时间小条位）

结构：
- 横向 N 个 buff 格子等距排列，间距 8px，由代码动态生成
- 每格独立绘制图标 + 剩余时间，图标 32×32 来自后续 buff 数据表

### ③ 环境信息条 `assets/sprites/ui/hud_envinfo.png`

源尺寸：**256×56 px**，9-patch 横向可拉伸

结构（参考图顶部居中）：
- 昼夜图标 32×32（太阳/月亮，已在 `ui_sheet.png` ROW 6）
- 时间数字 Label（像素字体）
- 天气图标 32×32（晴/雨/雪，独立 atlas `hud_weather.png` 64×32 横排两态作占位）

### ④ 事件提示条 `assets/sprites/ui/hud_event.png`

源尺寸：**320×56 px**，9-patch 横向可拉伸

结构（参考图最上方 "怪物入侵倒计时 02:30 后来袭"）：
- 左侧 32×32 警示图标
- 中间事件描述 Label
- 右侧倒计时数字

> 仅在事件队列非空时显示；可同时显示 1 条。

### ⑤ 小地图框 `assets/sprites/ui/hud_minimap.png`

源尺寸：**192×192 px**

结构（参考图右上指南针）：
- 圆形外环 + 内圆透明区（地图由代码绘制）
- 外环上 N / E / S / W 4 个方位字符
- 配套坐标条 `hud_coord.png`：160×24 px，9-patch 横向可拉伸
- 兴趣点图钉 `hud_poi_pin.png`：16×16 px，叠加在内圆上

### ⑥ 任务追踪条 `assets/sprites/ui/hud_quest_row.png`

单行源尺寸：**256×40 px**，9-patch 横向可拉伸

结构（参考图小地图下方）：
- 左侧 24×24 px 任务图标
- 中间任务名 Label
- 右侧进度数字 "x/y"
- 多任务时纵向堆叠；顶部一个 256×24 px 标题栏 `hud_quest_header.png`（"任务追踪"）可折叠

### ⑦ 快捷栏 `assets/sprites/ui/hud_hotbar.png`

源尺寸：**640×128 px**（**关键参考区域**）

结构（参考图底部居中）：

| 元素 | 尺寸 | 说明 |
|------|------|------|
| 经验/技能条 | 576×16 px（底+填充两层） | 中间留 40×28 px 等级徽章位 |
| 等级徽章 | 40×28 px | 内嵌经验条中点，数字由代码绘制（参考图显示 "32"） |
| 槽位容器 9-patch | 576×80 px，角 16px | 可横向拉伸适配 9 格 |
| 物品格 | 64×64 px × 9 | 等距横排 |
| 选中态高亮 | 80×80 px，9-patch 角 16px | 覆盖物品格外延 8px，与参考图选中格高亮一致 |
| 数量徽章 | 24×16 px | 置于格子右下 |

> 当前代码（`hud.gd`）已实现 9 格 + 1–9 数字键选中。重出美术时槽位间距对齐到 64×64。

### ⑧ 移动控制 `assets/sprites/ui/hud_dpad.png`

源尺寸：**256×256 px**（仅移动端）

结构（参考图左下）：
- 8 方向 D-pad，中心实心按钮 64×64，外围 4 方向 + 4 对角，各 64×64
- 中间一个独立摇杆球 `hud_stick.png` 80×80 px

### ⑨ 交互按钮 `assets/sprites/ui/hud_actionbtns.png`

源尺寸：**192×192 px**（仅移动端）

结构（参考图左下移动控制旁）：
- 3 个 96×96 px 圆按钮 L 形排列
- 图标位 48×48 居中：剑（攻击）/ 手（拾取/交互）/ 对话泡 —— 三个图标单独出

### ⑩ 技能栏 `assets/sprites/ui/hud_skillslot.png`

单格源尺寸：**80×80 px**

结构（参考图右下）：
- 圆角方形底（深色），内嵌 48×48 技能图标
- 左下角 16×16 px 键位字符（Q/E/R/F 或鼠标键标记）
- 冷却遮罩由代码绘制圆形扇形蒙版
- 横排 4 格，间距 8px

### ⑪ 底部信息行 `assets/sprites/ui/hud_infoslot.png`

单子条源尺寸：**192×48 px**，9-patch 横向可拉伸

结构（参考图底部排成 3 段）：
- 子条内部：左侧 32×32 图标 + 右侧 Label
- 子条之间间距 16px
- 当前固定 3 子条：**资源/货币** / **装备耐久** / **基地防御**
- 资源子条内可显示多个 「图标 + 数字」单元（金币 + 宝石 + 主要资源）

### ⑫ 危险边框特效 `assets/sprites/ui/hud_danger_edge.png`

源尺寸：**1920×1080 px**（全屏外圈遮罩，**9-patch 角 256px**）

结构：
- 外圈红色脉冲渐变 256px 厚
- 内部完全透明
- 由代码控制 `modulate.a` 做呼吸动画
- 不需要可拉伸版本，使用 9-patch 适配任意分辨率

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
