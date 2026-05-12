# 美术：游戏内 UI

风格：Minecraft 方块 UI 风格，深灰色石头质感背景，方形描边，无圆角，像素格子感。

## 格式约定

| 元素 | 源文件尺寸 | 视觉用途 |
|------|-----------|---------|
| 面板背景（9-patch） | 128×128 px，角 32px | 拖拽面板、对话框背景 |
| 按钮（3 状态竖排） | 192×64 px × 3（共 192×192） | normal / hover / pressed 三态 |
| 物品格子 | 80×80 px | 背包 / 储物箱格子背景 |
| 血量条背景 | 384×48 px | HUD 血量条底 |
| 血量条填充 | 384×48 px | HUD 血量条填充 |
| 分隔线 | 64×16 px（可横向拉伸） | 面板分隔线 |
| 标题栏背景 | 128×64 px（可横向拉伸） | 面板顶部拖拽区域 |
| 时间 / 昼夜图标 | 64×64 px × 2（太阳 + 月亮） | HUD 昼夜状态 |
| 当前物品框 | 208×208 px | HUD 选中物品显示框 |

文件路径：`assets/sprites/ui/ui_sheet.png`（统一一张图，各元素按行排列）

## 提示词

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
