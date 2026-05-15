# 美术：物品图标

物品图标按 **id 单独成图**，每个 `64×64 px` 独立 PNG，方便逐个迭代。

- 文件位置：`assets/sprites/items/icons/{id}.png`
- 代码加载顺序（`ItemDatabase._resolve_item_icon`）：
  1. JSON `icon_path` 字段 override（特殊路径才填）
  2. `assets/sprites/items/icons/{id}.png`
  3. 旧 atlas `icons.png` 切片（兼容用，逐步淘汰）
  4. `color` 字段纯色占位

> 旧的 `icons.png` atlas 仍可工作（兼容老流程），但**新增物品图标请走单文件**。下面表中已分配 atlas 格子的物品，画完单文件后可以无视那个格子。

## 提示词模板（单图标）

每次只生成一张。**风格锚**：参考现有 `assets/sprites/items/icons.png` 中已有的 8 个 isometric 图标（木块 / 石块 / 胡萝卜 / 麦穗 / 蛋 / 烤鸡 / 魔晶 / 卷轴）作为风格基准。

```
Generate a single pixel-art item icon, 64×64 pixels, transparent background.
Use the reference image as the style anchor: chunky isometric 3/4 view, same warm earthy palette, hard pixel edges, 2-3 tone shading per face, no anti-aliasing, no gradients, no outline.
Center the icon in the canvas, leave 4–6 px transparent margin on all sides.
No background fill, no cell border, no text, no watermark, no item shadow.

Subject: {单个物品的简短描述，见下表}
```

把 `{Subject}` 替换成下表对应行的英文描述即可。

## 物品图标清单

文件名 = `{id}.png`。下表列出每个 id 的 Subject。

| id | Subject（英文，喂给提示词） |
|---|---|
| `wood` | brown oak log block, pixel grain lines on top face |
| `stone` | grey cobblestone block, 2-3 pixel cracks |
| `wooden_plank` | light brown plank block, two horizontal seam lines |
| `iron_ore` | grey-brown ore block with iron speckle pixels |
| `iron_bar` | pale grey metal ingot, geometric, 1-2 pixel highlight |
| `rope` | coiled hemp rope ring, light brown weave pixels |
| `hay` | golden hay bale, vertical straw pixels |
| `carrot` | orange carrot with green leaf pixels |
| `carrot_seed` | small brown pouch with orange seeds spilling out |
| `wheat` | golden wheat bundle, ear pixels |
| `wheat_seed` | small brown pouch with yellow seeds spilling out |
| `potato` | beige potato with darker spot pixels |
| `potato_seed` | small brown pouch with beige seeds spilling out |
| `tomato` | red tomato with green stem pixels |
| `tomato_seed` | small brown pouch with red seeds spilling out |
| `berry` | cluster of purple-red berries |
| `mushroom` | red-cap white-stem mushroom |
| `chicken_egg` | white oval egg |
| `milk` | glass bottle filled with white milk |
| `animal_feed` | brown feed sack |
| `cooked_carrot` | roasted orange carrot on a wooden plate |
| `cooked_mushroom` | dark brown grilled mushroom |
| `berry_jam` | glass jar of purple-red jam |
| `rare_seed` | glowing purple rare seed with star sparkle pixels |
| `blueprint` | rolled beige parchment blueprint |
| `axe` | wood-handled iron axe, blade highlight pixel |
| `pickaxe` | wood-handled iron pickaxe, T-shape head |
| `meat` | pink raw meat chunk with white bone pixel |
| `cooked_meat` | brown roasted meat with grill mark pixels |
| `leather` | stacked brown leather rolls |
| `wool` | white wool tuft, blocky cloud shape |
| `bone` | white bone, block-shaped knuckles on both ends |
| `corn` | yellow corn cob with green husk pixels |
| `corn_seed` | small brown pouch with yellow corn seeds spilling out |
| `pumpkin` | orange pumpkin with vertical groove pixels, green stem |
| `pumpkin_seed` | small brown pouch with orange pumpkin seeds spilling out |
| `mushroom_soup` | wooden bowl with brown mushroom soup, floating mushroom chunks |
| `pumpkin_soup` | wooden bowl with orange pumpkin soup, steam pixels |
| `corn_bread` | golden flat cornbread square |
| `bone_meal` | pile of off-white bone meal granules |
| `wooden_sword` | wood-handled wooden shortsword, rectangular blade |
| `iron_sword` | wood-handled iron longsword, rectangular blade |
| `bow` | wooden bow with bowstring pixels, D-shape |
| `arrow` | bundle of wooden arrows, pixel arrowhead |
| `leather_armor` | brown leather vest with stitch pixels |
| `iron_armor` | grey iron chestplate with rivet pixels |
| `lucky_charm` | golden four-leaf clover pendant |

## 工作流

1. 选一个还没出图的 id（背包里显示为纯色块的就是缺图的）。
2. 用上方模板 + 该 id 的 Subject 跑一张 64×64 PNG。
3. 存到 `assets/sprites/items/icons/{id}.png`，Godot 自动 import。
4. 进游戏看效果，不满意只需要重画这一张。

## 旧 atlas 状态（仅供 fallback）

`assets/sprites/items/icons.png` 是早期 4×2 = 8 个 isometric 图标的占位 atlas。新流程不再依赖它，但代码保留切片回退以兼容已有 `icon_grid` 字段。等所有物品都有单文件之后，可以：

1. 删除 `assets/sprites/items/icons.png` 和对应 `.import`
2. 删除 `ItemDatabase` 里 `_icon_sheet` 相关代码段
3. `ItemData` 移除 `icon_grid` 字段，`items.json` 同步清掉
