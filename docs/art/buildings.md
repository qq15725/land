# 美术：建筑

2.5D 斜视角，pivot 在底边中心，透明背景，PNG 导出。所有建筑由方块堆叠构成，每个面用 2-3 色平涂区分亮面/暗面。

| 类型 | 源文件尺寸 | 示例 |
|------|----------|------|
| 小型家具/设施 | 192×192 px | 工作台、箱子、烹饪锅 |
| 中型建筑 | 256×256 px | 贸易摊、信箱、筒仓 |
| 大型建筑 | 384×384 / 384×512 px | 房屋、仓库、畜棚 |

## 提示词模板

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

## 当前资产列表

| id | 描述 | 源文件尺寸 | 文件路径 | 状态 |
|----|------|----------|----------|------|
| `workbench` | wooden crafting table block, oak plank texture on top, tool icons as pixel squares | 192×192 | `assets/sprites/buildings/workbench.png` | ✅ |
| `storage_chest` | wooden chest block, brown oak planks, metal latch pixel line on front | 192×192 | `assets/sprites/buildings/storage_chest.png` | ✅ |
| `cooking_pot` | stone block furnace with orange fire pixel glow on front face | 192×192 | `assets/sprites/buildings/cooking_pot.png` | ✅ |
| `farm_plot` | flat farmland block, dark brown tilled soil with pixel row lines | 192×192 | `assets/sprites/buildings/farm_plot.png` | ✅ |
| `trading_post` | wooden block booth, plank walls, colorful pixel banner squares on front | 256×256 | `assets/sprites/buildings/trading_post.png` | ✅ |
| `barn` | large red wood barn block, white pixel trim, hay door on front face | 384×384 | `assets/sprites/buildings/barn.png` | ✅ |
| `silo` | tall cylindrical silo made of grey metal block panels, conical top, square pixel rivets | 256×384 | `assets/sprites/buildings/silo.png` | ✅ |
| `mailbox` | small wooden mailbox block on a thin post, red pixel flag on side | 192×192 | `assets/sprites/buildings/mailbox.png` | ✅ |
| `animal_pen` | small wooden fenced pen with hay floor square inside, oak fence post blocks | 256×256 | `assets/sprites/buildings/animal_pen.png` | ✅ |
| `bed` | low wooden bed block, white pillow on top, red blanket pixel | 192×128 | `assets/sprites/buildings/bed.png` | ✅ |
| `flowerpot` | small terracotta clay pot block with green plant pixels and 2-3 colored flower dots on top | 192×192 | `assets/sprites/buildings/flowerpot.png` | ✅ |
| `chair` | simple wooden chair block, oak plank seat, three-rail back, square legs | 192×192 | `assets/sprites/buildings/chair.png` | ✅ |
| `lamppost` | tall iron lamppost block on stone base, square lantern at top emitting warm yellow pixel glow at night | 192×256 | `assets/sprites/buildings/lamppost.png` | ✅ |
| `flag` | tall wooden pole with rectangular pixel banner in red and gold, pixel rope tie | 192×256 | `assets/sprites/buildings/flag.png` | ✅ |
| `fountain` | square stone fountain block, two stacked basins, blue pixel water with white foam pixels, splash droplets | 256×256 | `assets/sprites/buildings/fountain.png` | ✅ |
| `well` | round stone well block with wooden roof gable on top, dark water pixel inside, rope and pulley | 192×256 | `assets/sprites/buildings/well.png` | ✅ |
| `oven` | brick block oven with arched mouth, glowing orange fire pixels inside, stone chimney on top | 192×256 | `assets/sprites/buildings/oven.png` | ✅ |
| `anvil` | dark iron anvil block on wooden stump, classic anvil silhouette, light grey highlight pixels on top face | 192×192 | `assets/sprites/buildings/anvil.png` | ✅ |
| `mill` | wooden windmill block, four cross sail blades on the side, stone base, roof block | 256×384 | `assets/sprites/buildings/mill.png` | ✅ |
| `smelter` | brick-and-stone smelting furnace block, tall square shape, glowing molten orange opening at front, smoke vent on top, two-tone grey stone with copper trim pixels | 192×256 | `assets/sprites/buildings/smelter.png` | ⏳ |
| `fishing_dock` | small wooden plank pier extending over water, dark blue water pixels lapping the front edge, rope coil and a single wooden post with a hanging fishing rod | 256×192 | `assets/sprites/buildings/fishing_dock.png` | ⏳ |
| `loom` | wooden floor loom block, vertical frame with parallel white thread lines, half-finished cloth roll at bottom, wooden treadle pedal at base | 192×256 | `assets/sprites/buildings/loom.png` | ⏳ |
| `dye_vat` | round terracotta clay vat half-filled with bubbling dye, three swirling colored pixel pools (red/yellow/blue) on top, wooden hoop band around the middle | 192×192 | `assets/sprites/buildings/dye_vat.png` | ⏳ |
| `coop` | small wooden chicken coop block, slanted shingle roof, oval entry hole in front, wire mesh window on side, hay-strewn pixel floor visible inside | 256×192 | `assets/sprites/buildings/coop.png` | ⏳ |
| `brewing_keg` | tall wooden barrel keg block with iron hoops, glowing amber liquid pixels at the top opening, a small spigot on the front face, slight steam wisp | 192×256 | `assets/sprites/buildings/brewing_keg.png` | ⏳ |
| `scarecrow` | farm scarecrow on a cross post, straw-stuffed burlap body, painted pumpkin head with stitched eyes, ragged shirt fluttering, hay tufts at hands/feet | 192×256 | `assets/sprites/buildings/scarecrow.png` | ⏳ |
| `sign_post` | short wooden sign post block, two horizontal directional plank arrows nailed to a single vertical post, faint carved arrow pixels, dirt mound base | 128×192 | `assets/sprites/buildings/sign_post.png` | ⏳ |

> 围栏类（`wood_fence` / `iron_fence` / `wood_fence_gate`）无需独立 sprite，运行时按拼接结构自动绘制。
> 装饰类（flowerpot/chair/flag/fountain）共用 `decoration.tscn`，仅靠 `sprite_path` 区分外观。
> 路灯（lamppost）有独立 PointLight2D 节点，sprite 主体应当包含可识别的"灯笼"高光位置。
