# 美术：技能图标

> **风格基准**：冒险岛（MapleStory）经典技能图标的方形铆钉边框 + 中央插画 + 深色金属背景，重画为像素方块风。
> 单图标尺寸 **64×64 px**，独立 PNG，文件名 = skill_id。

- 文件位置：`assets/sprites/skills/{id}.png`
- 当前代码用 `ItemDatabase.get_icon_at_grid(icon_grid)` 从 `items/icons.png` 借位占位；
  正式图加载顺序：`skills/{id}.png` 优先 → 否则借位 `icons.png` → 否则纯色占位。
- 风格锚：与物品图标一致 — 像素方块 + 2-3 色平涂 + 硬边缘，画布留 4-6 px 透明边距。

---

## 提示词模板（冒险岛风格 + 像素化）

```
Generate a single MapleStory-inspired pixel-art skill icon, 64×64 pixels, transparent background.
Style: dark square metal frame with riveted corners (4 small studs at corners), 
inset dark slate background, centered illustration of the skill subject in chunky pixel art.
2-3 tone shading per shape face, hard edges, no anti-aliasing, no gradients,
no outer glow beyond the frame, no anti-aliased rounded corners.
Bold readable silhouette at 32x32 thumbnail size. Strong color contrast on inset.

Subject: {单技能描述，见下表}
```

---

## 通用（共通技能）

| id | 类型 | Subject（英文） |
|---|---|---|
| `basic_swing` | 主动 fan | three pixel snail shells in a fan layout, brown shells with white spiral pixels, casual flick motion lines |

---

## 战士 Warrior（参考冒险岛 1转「剑士共通」+ 2转「斗士/侍卫」）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `power_strike` | 强力一击 | 主动 fan | a wooden-hilt iron sword angled diagonally with a single bright impact crash star at its tip, warm gold spark pixels |
| `slash_blast` | 横扫千军 | 主动 fan-AOE | three overlapping arc slashes forming a wide horizontal fan, bronze blade with gold motion lines |
| `iron_body` | 铁壁 | 主动 buff | a grey hexagonal pixel shield with thick rivets, faint blue glow halo edge |
| `sword_mastery` | 剑术精通 | 被动 | two crossed iron swords over a small pixel star, silver blades with brown hilts |
| `final_attack_sword` | 致命攻击：剑 | 被动 | a sword in front with a faint mirrored sword behind it, "+1" tiny pixel mark in upper right |
| `rage` | 怒吼 | 主动 buff | an angry shouting blocky warrior face with red aura pixels, jagged red lines radiating outward |
| `power_guard` | 格挡反弹 | 主动 buff | a blue tower shield head-on with a small white spark on its center, reflective pixel highlights |
| `coma_sword` | 重击：剑 | 主动 fan | a heavy iron broadsword swinging downward with a dark impact crater pixel below, dust particles |
| `ground_slash` | 地裂斩 | 主动 fan | a red downward sword slash splitting earth, jagged ground crack pixels with orange lava glow inside |
| `whirlwind` | 旋风斩 | 主动 fan | two iron swords whirling inside a swirling wind vortex, white motion ring pixels, dust trail |
| `berserk` | 怒气爆发 | 主动 buff | a snarling blocky warrior face engulfed in red-orange flame aura pixels, fists clenched, "ATK+" pixel mark |
| `guardian_shield` | 守护盾 | 主动 buff | a large golden tower shield with a glowing white center cross, radiating soft warm light pixels |
| `war_cry` | 战吼 | 主动 buff | a shouting blocky warrior head with yellow sound-wave ring pixels expanding outward, mouth open wide |

---

## 法师 Magician（参考冒险岛 1转「魔法师共通」+ 2转「火毒/冰雷」）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `energy_bolt` | 能量弹 | 主动 projectile | a purple-blue magic sphere with a four-point pixel sparkle on top |
| `magic_claw` | 魔法爪 | 主动 projectile×2 | a violet three-clawed mark slashing forward, magic glyph pixels in background |
| `magic_guard` | 魔法守护 | 主动 buff | a blue magic barrier orb with concentric ring pixels, hexagonal energy texture |
| `magic_armor` | 魔法盔甲 | 主动 buff | a pixel breastplate enchanted with blue rune lines, glowing core pixel on chest |
| `mp_eater` | MP偷取 | 被动 | a blue mana droplet with a small arrow curving back into a pixel beaker |
| `teleport` | 传送 | 主动 buff | a purple spiral portal with two arrows wrapping clockwise, fading edge pixels |
| `fire_arrow` | 火焰之箭 | 主动 projectile | a flaming red-orange arrow tip with thick fire trail pixels behind, ember sparks |
| `meditation` | 冥想 | 主动 buff | a meditating wizard silhouette in lotus pose, soft purple glow pixels above head |
| `fireball` | 火球术 | 主动 projectile | a fiery red-orange flaming sphere with a hot yellow core pixel, ember trail pixels behind |
| `ice_storm` | 寒冰风暴 | 主动 aoe | a swirling cyan-white blizzard ring with jagged ice shard pixels and snowflake speckles |
| `chain_lightning` | 雷电链 | 主动 chain | a jagged yellow lightning bolt branching into two zigzag forks, electric crackle pixel speckles |
| `time_stop` | 时间停滞 | 主动 buff | a pixel clock face frozen in cyan-white ice, clock hands stopped, faint snow speckles around |
| `summon_elemental` | 召唤元素仆从 | 主动 summon | a glowing blue elemental cube spirit with two dot eyes summoned inside a purple magic circle |
| `heal` | 治愈术 | 主动 buff | a pixel green cross floating inside a soft white-gold halo glow, sparkle pixels around |

---

## 弓手 Archer（参考冒险岛 1转「弓箭手共通」+ 2转「猎人」）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `arrow_blow` | 箭刃 | 主动 projectile | a single sharp arrow flying right with strong yellow motion lines behind, green fletching pixels |
| `double_shot` | 双重射击 | 主动 projectile×2 | two parallel arrows flying right side-by-side, yellow trail pixels |
| `focus` | 专注 | 主动 buff | a stylized eye iris in green with a small white target reticle overlay |
| `critical_shot` | 致命射击 | 被动 | a red crosshair pixel reticle over a tiny arrow tip, "!" pixel mark |
| `bow_mastery` | 弓术精通 | 被动 | a horizontal wooden bow over a small bullseye pixel target |
| `arrow_bomb` | 爆裂箭 | 主动 projectile | an arrow tip embedded in a small black bomb with lit fuse pixels, orange flame at fuse end |
| `soul_arrow_bow` | 灵魂之箭 | 主动 buff | a glowing ghostly silver arrow with faint soul wisp pixels around its body |
| `final_attack_bow` | 致命攻击：弓 | 被动 | a horizontal bow with a second translucent bow behind it, "+1" tiny pixel mark in upper right |
| `arrow_rain` | 箭雨 | 主动 aoe | a dense cluster of arrows falling at steep downward angles, dotted impact pixels at the bottom, motion lines |
| `piercing_arrow` | 穿透箭 | 主动 projectile | a single long sharp arrow with bright white trail piercing through two ghostly enemy silhouettes |
| `eagle_eye` | 鹰眼侦察 | 主动 buff | a sharp green eagle eye iris with target reticle pixels overlaid, intense focus highlight |
| `camouflage` | 隐身 | 主动 buff | a faint translucent archer silhouette merged with green leaf pixels, vanishing fade effect |
| `summon_hawk` | 召唤雄鹰 | 主动 summon | a brown blocky hawk swooping forward with spread wings, sharp yellow beak and talon pixels |

---

## 盗贼 Thief（参考冒险岛 1转「盗贼共通」+ 2转「刺客/侠盗」）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `lucky_seven` | 幸运七 | 主动 projectile | two crossed shining silver throwing stars with a small "7" pixel mark glowing yellow between them |
| `dark_sight` | 暗影潜行 | 主动 buff | a hooded thief silhouette fading into dark purple shadow pixels, faint outline only |
| `poison_blade` | 毒刃 | 主动 fan | a dark green dagger dripping purple-green venom droplets, toxic vapor pixels around the blade |
| `shadow_dash` | 暗影闪现 | 主动 dash | a dark purple-black streak of motion blur with a translucent thief afterimage at the trailing end |
| `shadow_clone` | 影分身 | 主动 summon | three overlapping translucent thief silhouettes in fan stance, dark purple aura pixels behind |
| `assassinate` | 暗杀 | 主动 fan | a black-hooded dagger plunging downward with a single red blood-splash pixel and "X" mark |
| `smoke_bomb` | 烟雾弹 | 主动 aoe | a round black bomb releasing a cloud of grey smoke puff pixels, lit fuse with orange spark |

---

## 海盗 Pirate（参考冒险岛 1转「海盗共通」+ 2转「拳手/枪手」）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `somersault_kick` | 回旋踢 | 主动 fan | a blocky pirate leg performing a sweeping roundhouse kick with white arc motion lines, boot impact pixel |
| `double_shot_pirate` | 双枪连射 | 主动 projectile | two black flintlock pistols crossed, both firing forward with bright yellow muzzle flash pixels |
| `anchor_punch` | 船锚拳 | 主动 fan | a grey iron ship anchor swung forward like a fist with white impact spark pixels at its hook |
| `gatling_burst` | 双枪扫射 | 主动 fan | two pistols fanning a wide spread of yellow bullet pixel trails, smoke puff behind hands |
| `summon_shark` | 鲨鱼召唤 | 主动 aoe | a grey shark leaping forward with open jaws and white pixel teeth, water splash pixel ring around it |
| `blank_shot` | 震慑空弹 | 主动 projectile | a single pistol firing a bright yellow concussion ring with no bullet, white shockwave pixels |
| `battleship_call` | 战舰轰炸 | 主动 aoe | a small wooden battleship silhouette above firing two cannonballs downward, impact crater pixels below |

---

## 通用扩展（无 class_id）

| id | 中文 | 类型 | Subject（英文） |
|---|---|---|---|
| `combo_strike` | 连击突刺 | 主动 fan | three rapid sword thrusts shown as overlapping motion-line silhouettes, white spark pixel at tips |
| `haste` | 急速 | 主动 buff | a small blue clock face with two yellow speed lightning bolts beside it, motion blur pixels |
| `thorn_aura` | 荆棘光环 | 主动 buff | a circular ring of brown thorn vine pixels surrounding a central pixel figure, small green leaf and sharp spike pixels |
| `lifesteal_aura` | 吸血光环 | 主动 buff | a glowing red heart pixel emitting a ring of small red droplet pixels orbiting outward, dark crimson aura |

---

## 被动技能（`data/skills.json`，11 个，HUD/技能面板用）

| skill_id | Subject（英文） | 状态 |
|---|---|---|
| `farming`             | a brown hoe over a tilled green sprout, soil pixel grains, warm earth palette | ✅ |
| `mining`              | a stone pickaxe striking a grey ore chunk with cyan pixel crystals, two impact spark pixels | ✅ |
| `woodcutting`         | a wooden axe embedded in an oak log cross-section, brown bark + lighter inner ring pixels | ✅ |
| `combat`              | two crossed swords (one iron, one wooden) over a red shield, golden rivet pixels | ✅ |
| `gathering_mastery`   | a basket of mixed berries and herbs with a small "+1" pixel mark in upper right corner, green leaf accents | ⏳ |
| `cooking_master`      | a chef hat over a steaming pixel cauldron, golden ladle, warm orange glow halo | ⏳ |
| `merchant_eye`        | a single golden coin with an eye iris pixel inside, faint sparkle pixels, treasure palette | ⏳ |
| `nightwalker`         | a hooded silhouette under a crescent moon, faint translucent footprint trail behind, deep blue night palette | ⏳ |
| `endurance`           | a stylized red heart with armor plate overlay, "+HP" pixel mark, sturdy iron rivet pixels | ⏳ |
| `concentration`       | a single eye iris with crosshair lines, blue focus aura ring, "ZEN" calm palette | ⏳ |
| `fishing`             | a fishing rod with a hooked fish silhouette on the line, wave pixel ripples below, blue-aqua palette | ⏳ |

---

## Buff 图标（`data/buffs.json`，29 个，HUD `hud_buff_slot.png` 内 32×32 居中）

| buff_id | Subject（英文） | 状态 |
|---|---|---|
| `harvest_blessing`     | a golden wheat sheaf wreathed in soft yellow glow pixels, autumn warm palette | ✅ |
| `well_fed`             | a steaming bowl of stew with a wooden spoon, warm orange steam pixels, small heart pixel above | ✅ |
| `swift`                | a pair of small white feathered wings forming an X, motion blur pixel lines behind | ✅ |
| `iron_skin`            | a grey hexagonal metal shield outline filled with cross-hatched rivet pixels, cool blue tint | ✅ |
| `rage_buff`            | an angry red roaring face with jagged aura pixels, "+%" mark | ✅ |
| `power_guard_buff`     | a blue tower shield with reflected spark pixels | ✅ |
| `magic_guard_buff`     | a blue glowing orb with hexagonal aura pixels | ✅ |
| `magic_armor_buff`     | a purple-blue rune chestplate with glowing core | ✅ |
| `meditation_buff`      | a glowing lotus flower pixel with rising spirit dots | ✅ |
| `focus_buff`           | a green eye iris with target reticle | ✅ |
| `soul_arrow_buff`      | a translucent silver arrow glowing softly | ✅ |
| `berserk_buff`         | a snarling face with red-orange flame aura pixels and "ATK++" mark, jagged outline | ⏳ |
| `guardian_shield_buff` | a golden tower shield with glowing white center cross, radiating warm light pixels | ⏳ |
| `crit_up_buff`         | a red crosshair reticle with a small lightning spark, "CRIT%" pixel mark | ⏳ |
| `evasion_up_buff`      | a faint dodging silhouette afterimage with motion-blur pixel arrow curving aside | ⏳ |
| `lifesteal_buff`       | a red heart with a tiny crimson droplet falling from it into a vampire fang outline | ⏳ |
| `thorns_buff`          | a circular shield ringed with sharp green-brown thorn spikes, reflective spark on rim | ⏳ |
| `silence_debuff`       | a grey speech bubble with a diagonal red slash through it, mouth pixel crossed out | ⏳ |
| `freeze_debuff`        | a humanoid silhouette encased in pale cyan ice crystal block, frost speckle pixels around | ⏳ |
| `burn_debuff`          | a humanoid silhouette engulfed in flickering orange-red flame pixels, ember rising | ⏳ |
| `bleed_debuff`         | a red heart with three crimson droplet pixels falling down, slight dark vignette | ⏳ |
| `poison_debuff`        | a green skull pixel with bubbles rising from a poison drop, sickly chartreuse palette | ⏳ |
| `double_gold_buff`     | two golden coins stacked with a "×2" pixel mark and small star spark | ⏳ |
| `double_exp_buff`      | a glowing yellow "XP" letterform with a "×2" multiplier pixel mark above | ⏳ |
| `combo_buff`           | a pixel counter "COMBO ×5" in red-orange, motion blur lines, fist silhouette behind | ⏳ |
| `stealth_buff`         | a translucent hooded silhouette with dotted outline only, fading edge pixels | ⏳ |
| `time_stop_buff`       | a frozen pixel clock face with cyan ice glaze, clock hands stopped at twelve | ⏳ |
| `haste_buff`           | a pair of running pixel legs with three motion-blur trail lines behind, yellow energy aura | ⏳ |
| `hyper_body_buff`      | a flexing muscular pixel arm wrapped in glowing red aura, "HP+ATK" mark | ⏳ |

---

## 成就 / 图鉴图标（可选独立）

文件路径：`assets/sprites/achievements/{id}.png` 64×64

| achievement_id | Subject（英文） |
|---|---|
| `first_tree` / `lumberjack` | small wooden axe with a tiny tree icon next to it, friendly green palette |
| `miner` | grey pickaxe with a sparkling ore chunk, cool blue palette |
| `first_kill` / `slime_slayer` | small green slime with a red X mark above it, kill icon |
| `first_harvest` / `farmer` | golden wheat bundle with a small basket icon, warm yellow palette |
| `rich` | a stack of three gold coins with sparkle pixels |
| `survivor_7` / `survivor_30` | a calendar block icon with a number "7" or "30" inside, soft blue palette |

---

## 元素 VFX 占位扩展（与 [vfx.md](vfx.md) 配合）

| vfx_id | 关联技能 | 概念 |
|---|---|---|
| `melee_fan` ✅ | basic_swing / power_strike / slash_blast / coma_sword | 已规划，见 vfx.md |
| `aoe_circle` ✅ | iron_body / rage / power_guard / magic_guard / magic_armor / meditation / focus / soul_arrow_bow / teleport | 已规划，buff 自身光环 |
| `melee_rect` ✅ | （预留） | 已规划 |
| `projectile_fire` ✅ | energy_bolt / magic_claw / fire_arrow | 法师弹道 trail，调用方 `vfx_color` 区分颜色 |
| `projectile_arrow` ✅ | arrow_blow / double_shot / arrow_bomb | 弓系弹道短尾迹 |
| `hit_spark` ✅ | 所有命中 | 通用爆点 |

> 命名规范：vfx_id 用 snake_case；新增时同步更新 `vfx.md` 当前清单与本文件。

---

## 命名 → 数据对照

技能图标 grid（`data/active_skills.json` 中 `icon_grid` 字段）在美术替换前从 `items.png` 借位（先有视觉再迭代）：

| skill_id | borrowed icon_grid | 借位含义 |
|---|---|---|
| basic_swing / power_strike / iron_body / rage / power_guard / magic_guard / magic_armor / meditation / focus / soul_arrow_bow | `[4,5]` 借位皮甲框 | 通用 frame，正式美术按本文件 subject 替换 |
| slash_blast / arrow_blow / double_shot / soul_arrow_bow | `[5,5]` | |
| coma_sword | `[6,5]` | |
| energy_bolt / magic_claw / fire_arrow / arrow_bomb | `[7,5]` | 弹道类共用 |
| sword_mastery / bow_mastery | `[0,5]` 借位木剑 | 被动 |
| final_attack_sword / final_attack_bow | `[1,5]` 借位铁剑 | 被动 |
| mp_eater / teleport | `[3,1]` 借位图纸 | 被动/位移 |

正式美术接入后，`icon_grid` 字段保留作 fallback，由 `assets/sprites/skills/{id}.png` 优先覆盖。

## 已生成清单 _(自动同步自 assets/ 目录)_

### 技能图标（29 个）

目录：`assets/sprites/skills/`

- `arrow_blow`, `arrow_bomb`, `basic_swing`, `bow_mastery`, `coma_sword`
- `combat`, `critical_shot`, `double_shot`, `energy_bolt`, `farming`
- `final_attack_bow`, `final_attack_sword`, `fire_arrow`, `focus`, `iron_body`
- `magic_armor`, `magic_claw`, `magic_guard`, `meditation`, `mining`
- `mp_eater`, `power_guard`, `power_strike`, `rage`, `slash_blast`
- `soul_arrow_bow`, `sword_mastery`, `teleport`, `woodcutting`

### Buff 图标（11 个）

目录：`assets/sprites/buffs/`

- `focus_buff`, `harvest_blessing`, `iron_skin`, `magic_armor_buff`, `magic_guard_buff`
- `meditation_buff`, `power_guard_buff`, `rage_buff`, `soul_arrow_buff`, `swift`
- `well_fed`
