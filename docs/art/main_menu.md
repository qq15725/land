# 美术：主菜单专用美术

参考图：`docs/references/main_menu.png`

> 所有资产以参考图为视觉基准生成，提示词只描述结构要求。提示词通用前缀见下。

---

## 通用前缀

```
Reference image: docs/references/main_menu.png
Extract the visual style, color palette, pixel density, and art language directly
from this reference — do NOT invent new colors or styles.
Pixel art style matching the reference. Hard pixel edges, no anti-aliasing.
Transparent background unless stated otherwise.
```

---

## 资产列表

| 文件 | 尺寸 | 9-patch 边距 | 用途 | 状态 |
|------|------|------------|------|------|
| `assets/sprites/ui/main_menu_bg.png` | 1280×720 | — | 全屏背景插图 | ⏳ 待生成 |
| `assets/sprites/ui/title_land.png` | 384×128 | — | "Land" 装饰标题 Logo | ⏳ 待生成 |
| `assets/sprites/ui/panel_wood.png` | 192×192 | 32px | 存档面板木质框（9-patch） | ⏳ 待生成 |
| `assets/sprites/ui/slot_frame.png` | 192×80 | 12px | 单个存档槽内框（9-patch） | ⏳ 待生成 |
| `assets/sprites/ui/save_thumb_farm.png` | 128×80 | — | 有存档时缩略图 | ⏳ 待生成 |
| `assets/sprites/ui/save_thumb_empty.png` | 128×80 | — | 空存档位缩略图 | ⏳ 待生成 |
| `assets/sprites/ui/menu_icons.png` | 128×32 | — | 图标条带：叶片/齿轮/出门/垃圾桶，各 32×32 | ⏳ 待生成 |
| `assets/sprites/ui/btn_green.png` | 192×144 | 16px | 绿色按钮（检查更新），3态竖排 | ⏳ 待生成 |
| `assets/sprites/ui/btn_brown.png` | 192×144 | 16px | 棕色按钮（退出游戏），3态竖排 | ⏳ 待生成 |

---

## 提示词

### 1. 主菜单背景（main_menu_bg.png）

```
[通用前缀]

Recreate the BACKGROUND SCENE from the reference image as a standalone 1280×720 pixel
illustration — no UI panels, no text, no title, no buttons.

Extract from reference:
- Sky: warm twilight gradient (deep orange/amber near horizon, dark blue-purple at top)
- Silhouetted pine/fir trees lining both sides
- Cozy wooden log cabin center-left with warmly lit amber windows
- Foreground: corn/crop field, low wooden fence, garden lantern with warm glow
- Right side: wooden barrels and crates in shadow
- Ground: dark evening grass, winding dirt path

Left side of composition darker/more open — leaves room for title and feature text.
Right side slightly more open — leaves room for the save panel.
No characters. No UI elements. No text.
Opaque background, no transparency.
```

### 2. "Land" 标题 Logo（title_land.png）

```
[通用前缀]

Recreate the "Land" title logo as seen in the top-left of the reference image.
Canvas: 384×128 pixels, transparent background.

Extract from reference:
- The word "Land" in large decorative pixel-art lettering
- Warm golden-amber letter fill with dark brown outline/shadow
- Bright highlight along letter edges (top-left of each stroke)
- Small decorative leaf/vine element above or around the letters
- Thick, slightly organic letter strokes — rustic carved-wood feel
- NOT blocky monospace, NOT perfectly geometric

Centered on canvas. Transparent background.
```

### 3. 木质面板框 9-patch（panel_wood.png）

```
[通用前缀]

Recreate the RIGHT PANEL FRAME from the reference image as a tileable 9-patch asset.
Canvas: 192×192 pixels. Opaque.

Extract from reference:
- Warm medium-brown wood frame with carved decorative border
- Rounded organic corners with small ornamental detail
- Interior fill: warm parchment/tan color
- Frame thickness: ~32px on all sides
- The frame has subtle wood grain, slightly darker lines, highlight on top edge

Designed for 9-slice scaling with 32px corner margins.
The interior (center 128×128) should be flat parchment fill, no decorative elements.
```

### 4. 单存档槽内框 9-patch（slot_frame.png）

```
[通用前缀]

Recreate the INDIVIDUAL SAVE SLOT FRAME from the reference image.
Canvas: 192×80 pixels. Opaque.

Extract from reference:
- Thin dark wood border (~12px) around the slot
- Interior: slightly recessed parchment/tan fill
- Left ~100px: darker recessed area for thumbnail preview
- Right area: lighter parchment for text
- Subtle inset/shadow effect giving depth

Designed for 9-slice scaling with 12px corner margins.
```

### 5. 存档缩略图 — 有存档（save_thumb_farm.png）

```
[通用前缀]

Recreate the SAVE SLOT THUMBNAIL seen in slots 1 and 2 of the reference image.
Canvas: 128×80 pixels. Opaque.

Extract from reference:
- Small pixel-art farm scene viewed from slight top-down angle
- Green grass, plowed soil rows, small farmhouse silhouette, one tree
- Warm afternoon/daytime lighting
- Saturated, readable colors at small scale
No UI, no text.
```

### 6. 存档缩略图 — 空档位（save_thumb_empty.png）

```
[通用前缀]

Recreate the EMPTY SAVE SLOT placeholder as seen in slot 3 of the reference image.
Canvas: 128×80 pixels. Opaque.

Extract from reference:
- Dark muted grey-brown background
- Simple "empty" visual indication (subtle question mark or blank field texture)
- Subdued, low-contrast — clearly communicates "no data"
```

### 7. 图标条带（menu_icons.png）

```
[通用前缀]

Recreate the BADGE ICONS seen in the reference image (left side feature list icons).
Canvas: 128×32 pixels, 4 icons side by side (each 32×32). Transparent background.

Extract from reference:
- Circular badge/medallion style: round frame with colored fill and embossed look
- Bright highlight arc top-left, dark shadow arc bottom-right
Icon 1 (col 0, 0–31px):   leaf/sprout symbol  — green badge (matches "采集" icon)
Icon 2 (col 1, 32–63px):  gear/cog symbol     — green badge (matches "养殖" icon)
Icon 3 (col 2, 64–95px):  door with arrow     — green badge (exit/enter)
Icon 4 (col 3, 96–127px): red trash bin       — red-tinted badge (delete action)

Hard pixel edges, no anti-aliasing. Transparent background.
```

### 8. 绿色按钮 3态（btn_green.png）

```
[通用前缀]

Recreate the GREEN "检查更新" BUTTON from the reference image as a 3-state sprite sheet.
Canvas: 192×144 pixels (3 states stacked vertically, each 192×48px). Opaque.

Extract from reference:
- Green pixel-art button with decorative border matching the panel's wood style
- Gear icon area on left, text area on right (icon/text will be overlaid in code)
- Warm dark green border, medium green fill, bright highlight on top edge

State 0 (top,    y=0–47):   normal — as in reference
State 1 (middle, y=48–95):  hover  — slightly brighter, subtle glow/outline
State 2 (bottom, y=96–143): pressed — darker, slight inset

16px border margins for 9-slice if needed.
```

### 9. 棕色按钮 3态（btn_brown.png）

```
[通用前缀]

Recreate the BROWN/TAN "退出游戏" BUTTON from the reference image as a 3-state sprite sheet.
Canvas: 192×144 pixels (3 states stacked vertically, each 192×48px). Opaque.

Extract from reference:
- Brown/tan pixel-art button — same style as green button but with warm brown palette
- Matches the wood panel's color language
- Arrow/exit icon area on left (icon overlaid in code)

State 0 (top):    normal
State 1 (middle): hover — slightly lighter
State 2 (bottom): pressed — darker, inset

Same structure as green button, different color.
```

---

## 当前状态

| 文件 | 状态 |
|------|------|
| 参考图 | ✅ `docs/references/main_menu.png` |
| `main_menu_bg.png` | ⏳ 待生成 |
| `title_land.png` | ⏳ 待生成 |
| `panel_wood.png` | ⏳ 待生成 |
| `slot_frame.png` | ⏳ 待生成 |
| `save_thumb_farm.png` | ⏳ 待生成 |
| `save_thumb_empty.png` | ⏳ 待生成 |
| `menu_icons.png` | ⏳ 待生成 |
| `btn_green.png` | ⏳ 待生成 |
| `btn_brown.png` | ⏳ 待生成 |
