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
| 金币图标 | 64×64 px | HUD 金币余额前缀图标 |
| Hotbar 选中边框 | 96×96 px（9-patch，角 16px） | 1–9 动作栏当前选中格高亮，覆盖 80×80 物品格 + 8px 余边 |
| Toast 气泡背景（9-patch） | 96×48 px，角 16px | HUD 顶部临时提示（拾取、卖出、自动保存等）|

文件路径：`assets/sprites/ui/ui_sheet.png`（统一一张图，各元素按行排列）

## 提示词

```
Minecraft-style pixel art UI sprite sheet, transparent background,
blocky square UI elements, dark stone/grey panel texture, hard pixel edges,
flat color fills, no gradients, no rounded corners, no soft outlines.

Canvas size: 512×1120 pixels.
All elements aligned to the top-left, pixel-perfect, clean hard edges.
No labels, no text, no icons except the requested sun, moon, and gold coin.
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

ROW 8 — Gold coin icon (64x64 px):
  blocky pixel gold coin, bright golden yellow flat fill, 4px darker amber outline,
  small 4px white pixel highlight in upper-left corner for shine,
  centered on transparent background, no text or numerals on the coin face,
  Minecraft pixel art style.

ROW 9 — Hotbar selected highlight (96x96 px, 9-patch with 16px corners):
  bright white pixel square border, 4px thick outer line plus 2px inner shadow line,
  fully transparent center so the underlying item slot shows through,
  designed to overlay an 80x80 item slot with 8px outset on every side,
  Minecraft hotbar selected slot outline style, no fill, no glow.

ROW 10 — Toast bubble background (96x48 px, 9-patch with 16px corners):
  dark grey stone slab with 4px lighter grey border, slightly translucent feel
  via subtle 1-pixel dither in the body, square edges, designed to tile horizontally
  for variable-length text, Minecraft notification banner style, no text.

Minecraft pixel art UI, clean edges, consistent dark grey palette, transparent background
```

## 已生成清单 _(自动同步自 assets/ 目录)_

### UI 美术（33 个）

目录：`assets/sprites/ui/`

- `btn_brown`, `btn_green`, `hud_action_attack`, `hud_action_icons`, `hud_action_interact`
- `hud_action_talk`, `hud_actionbtns`, `hud_buff_slot`, `hud_charinfo`, `hud_coord`
- `hud_danger_edge`, `hud_dpad`, `hud_envinfo`, `hud_event`, `hud_hotbar`
- `hud_hotbar_selected`, `hud_infoslot`, `hud_minimap`, `hud_poi_pin`, `hud_quest_header`
- `hud_quest_row`, `hud_skillslot`, `hud_stick`, `hud_weather`, `icon_trash`
- `main_menu_bg`, `menu_icons`, `panel_wood`, `save_thumb_empty`, `save_thumb_farm`
- `slot_frame`, `title_land`, `ui_sheet`
