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
| `lucky_charm` | golden four-leaf clover pendant on a chain, glowing pixel sparkles |
| `meteorite_ore` | dark purple-blue cosmic ore chunk with cyan glowing crack pixels, faint star sparkle |
| `fish` | blue freshwater fish, scale pixels, white belly, pixel eye and tail fin |
| `fishing_rod` | wooden fishing rod with brown handle, thin line trailing down, small white float at line end |
| `hat_straw` | wide-brimmed yellow straw hat, woven straw pixel texture, brown band |
| `cape_red` | red flowing cape with gold trim pixels, billowing block shape |
| `flour` | small white sack of flour, brown rope tie, sprinkle of white powder pixels around base |
| `lucky_charm` | golden four-leaf clover pendant |
| `copper_ore` | chunk of grey stone with orange-red copper veins, isometric block, warm metallic speckles |
| `copper_bar` | small ingot of polished copper, orange-pink metallic, isometric block with one bright highlight pixel |
| `gold_ore` | grey stone chunk with bright yellow gold nuggets embedded, isometric block, sparkle pixel |
| `gold_bar` | small ingot of polished gold, vivid yellow metallic, isometric block with two-tone highlight |
| `coal` | chunk of black coal with dim grey highlights, isometric block, faint soot speckle |
| `clay` | small mound of reddish-brown wet clay, glossy highlight pixel, soft rounded block |
| `sand` | pile of pale yellow sand, two-tone tan shading, a few darker grain pixels on top |
| `glass` | transparent pale-blue glass pane block with white edge highlight pixels |
| `ruby` | faceted red gemstone, two-tone red, bright white sparkle pixel on top facet |
| `emerald` | faceted green gemstone, two-tone green, bright white sparkle pixel on top facet |
| `sapphire` | faceted blue gemstone, two-tone blue, bright white sparkle pixel on top facet |
| `amethyst` | faceted purple gemstone, two-tone violet, bright white sparkle pixel on top facet |
| `crystal_shard` | small jagged cyan-blue crystal shard, glowing edge pixel, isometric prism |
| `shell` | spiral seashell, pale pink and cream stripes, smooth pixel curl |
| `pearl` | small round white pearl with soft blue highlight pixel, sitting on a tiny grey shell base |
| `kelp` | bundle of dark green ribbon seaweed, slight teal highlight, droopy silhouette |
| `driftwood` | bleached grey-white weathered log piece, washed-smooth grain pixels |
| `salmon` | pink-orange salmon fish with silver belly, dark stripe along side, pixel eye and tail fin |
| `trout` | speckled brown trout with green back, white belly, small dark spot pixels |
| `catfish` | grey-brown catfish with wide flat head, two pixel whiskers, dark dorsal fin |
| `legendary_fish` | huge golden mythical fish with iridescent rainbow scale pixels, glowing white sparkle aura |
| `fish_bait` | small grey-brown pile of mashed bait worms, faint shine pixel |
| `fiber` | bundle of pale green plant fibers, loose strands, tied with a thin brown string |
| `cloth` | folded square of off-white woven cloth, subtle weave pixel pattern |
| `red_dye` | small glass vial filled with vivid red dye, cork stopper, drip pixel on side |
| `yellow_dye` | small glass vial filled with bright yellow dye, cork stopper, drip pixel on side |
| `blue_dye` | small glass vial filled with deep blue dye, cork stopper, drip pixel on side |
| `red_flower` | single red blossom with four square petals, yellow center pixel, two green leaf pixels |
| `yellow_flower` | single yellow blossom with four square petals, orange center pixel, two green leaf pixels |
| `spinach` | bundle of dark green spinach leaves, curly edge pixels, light vein highlights |
| `spinach_seed` | small brown pouch with green seed pixels spilling out |
| `parsnip` | pale cream parsnip root with tapered tip, green leafy top pixels |
| `parsnip_seed` | small brown pouch with cream seed pixels spilling out |
| `green_bean` | cluster of bright green long bean pods, slight pod bulge pixels |
| `green_bean_seed` | small brown pouch with dark green seed pixels spilling out |
| `chili` | bright red chili pepper, curved pod shape, small green stem pixel |
| `chili_seed` | small brown pouch with red seed pixels spilling out |
| `blueberry` | cluster of deep blue blueberries, white frost highlight pixels on top |
| `blueberry_seed` | small brown pouch with blue seed pixels spilling out |
| `grape` | bunch of purple grapes in pyramid cluster, small green leaf and stem on top |
| `grape_seed` | small brown pouch with purple seed pixels spilling out |
| `garlic` | white garlic bulb with pale papery skin, top stem pixels, faint clove division lines |
| `garlic_seed` | small brown pouch with white clove pixels spilling out |
| `coffee_bean` | small handful of glossy brown coffee beans, white center groove pixel on each |
| `coffee_seed` | small brown pouch with dark brown coffee seed pixels spilling out |
| `sunflower` | bright yellow sunflower with brown center disk pixels, single green stem |
| `sunflower_seed` | small brown pouch with striped black-and-white sunflower seed pixels |
| `duck_egg` | pale blue oval duck egg, smooth surface highlight |
| `goose_egg` | large cream-white goose egg, slightly elongated oval with soft highlight pixel |
| `rabbit_fur` | folded patch of fluffy white rabbit fur, soft pixel tufts, faint pink underside |
| `salmon_steak` | pink salmon steak fillet on a wooden plate, dark stripe and white fat line pixels |
| `fish_stew` | wooden bowl with creamy fish stew, fish chunk and herb pixels floating, steam pixels |
| `salad` | wooden bowl of mixed green salad, red tomato and yellow flower pixels on top |
| `blueberry_pie` | golden pie slice with deep blue blueberry filling, lattice crust pixels on top |
| `grape_wine` | green glass bottle with red wine, cork stopper, small grape cluster label pixel |
| `spicy_stew` | wooden bowl with red spicy stew, chili pixel floating on top, steam swirl pixels |
| `garlic_bread` | golden toasted bread slice with white garlic spread pixels and tiny green herb specks |
| `pumpkin_pie` | orange pumpkin pie slice with golden crust, cinnamon sprinkle pixels on top |
| `coffee_drink` | brown ceramic mug filled with dark coffee, white foam pixel on top, steam swirl |
| `omelette` | folded yellow omelette on a wooden plate, brown crispy edge pixels |
| `sunflower_oil` | small glass bottle filled with golden yellow oil, sunflower symbol on label pixel |
| `ward_charm` | small silver pentagram charm on a thin chain, faint blue protective glow pixels |
| `speed_charm` | small bronze winged-foot charm on a thin chain, motion blur pixel lines beside it |
| `lantern` | small handheld iron-frame lantern with warm yellow glowing pane, top ring handle pixel |
| `copper_sword` | wood-handled copper longsword, orange-pink metallic blade, rectangular guard |
| `gold_sword` | wood-handled gold longsword, bright yellow metallic blade with sparkle pixel |
| `copper_pickaxe` | wood-handled copper pickaxe, orange-pink T-shape head, two-tone metallic |
| `iron_pickaxe` | wood-handled iron pickaxe, dark grey T-shape head, single highlight pixel |
| `iron_axe` | wood-handled iron axe, dark grey wedge blade, single highlight pixel |
| `hoe` | wood-handled iron hoe, flat rectangular blade head angled forward, soil grain pixels |
| `watering_can` | green metal watering can with curved spout, water droplet pixels, rivet highlight |

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

## 已生成清单 _(自动同步自 assets/ 目录)_

### 物品图标（单文件）（53 个）

目录：`assets/sprites/items/icons/`

- `animal_feed`, `arrow`, `axe`, `berry`, `berry_jam`
- `blueprint`, `bone`, `bone_meal`, `bow`, `cape_red`
- `carrot`, `carrot_seed`, `chicken_egg`, `cooked_carrot`, `cooked_meat`
- `cooked_mushroom`, `corn`, `corn_bread`, `corn_seed`, `fish`
- `fishing_rod`, `flour`, `hat_straw`, `hay`, `iron_armor`
- `iron_bar`, `iron_ore`, `iron_sword`, `leather`, `leather_armor`
- `lucky_charm`, `meat`, `meteorite_ore`, `milk`, `mushroom`
- `mushroom_soup`, `pickaxe`, `potato`, `potato_seed`, `pumpkin`
- `pumpkin_seed`, `pumpkin_soup`, `rare_seed`, `rope`, `stone`
- `tomato`, `tomato_seed`, `wheat`, `wheat_seed`, `wood`
- `wooden_plank`, `wooden_sword`, `wool`
