# 美术资源包接入指引（TODO）

> 状态：**适配层已就绪**（`ArtProfile` autoload + `SpriteFrameBuilder`），等待接入正式美术包。
> 切换美术包**只改 `ArtProfile` 配置 + 替换贴图文件**，不动各 entity 代码。

## 一、推荐的免费/低价美术包

| 包 | 价格 | 覆盖 | 链接 |
|---|---|---|---|
| **Cute Fantasy RPG**（首选） | $2.99 商用 | 角色/NPC/史莱姆+骷髅/11动物/22作物/建筑/地砖/物品/UI | https://kenmi-art.itch.io/cute-fantasy-rpg |
| Sprout Lands | 免费(商用$3.99) | 农场全套，**无战斗怪物** | https://cupnooble.itch.io/sprout-lands-asset-pack |
| Mana Seed 农夫 | 免费 | 角色质量最高+换装，需配环境包 | https://seliel-the-shaper.itch.io/farmer-base |
| Kenney RPG | CC0 免费 | 地砖/角色/怪物基础 | https://kenney.nl |
| 怪物补充(wolf/zombie/bat) | $0–4 | Cute Fantasy 缺的怪 | https://itch.io/game-assets/tag-monsters/tag-top-down |

**缺口**：自动化建筑（传送带/抽取器/合成机等）没有现成包——建议**保留现有几何占位**（彩色方块+朝向箭头，风格中性、功能清晰）。

## 二、接入步骤

### 1. 看清新包的角色精灵表布局
打开包里的角色 spritesheet，确认：
- 每行是不是「下/上/左/右」？顺序可能不同（有的是 下/左/右/上）
- 几列（每方向几帧）？
- 整张表尺寸（决定单帧尺寸，**适配层会自动按贴图算，不用手填**）

### 2. 改 `ArtProfile`（`scripts/systems/art_profile.gd`）
```gdscript
var char_cols := 4              # ← 改成新包每方向的帧数
var char_rows := 4              # ← 改成新包的方向行数
var char_row_order := [0,1,2,3] # ← 改成 [下,上,左,右] 各取第几行
```
- **显示大小**：源帧尺寸变了 scale 会自动适应，显示高度恒定。想整体改大小就调 `CHARACTER_TARGET_H` / `ANIMAL_TARGET_H`（世界单位=像素，当前 32 / 64）。
- 帧率：`PLAYER_FPS` / `CREATURE_FPS` / `ANIMAL_FPS`。

### 3. 按命名约定放贴图文件（路径见 `AssetPaths`）
| 类型 | 路径 |
|---|---|
| 玩家/NPC | `assets/sprites/characters/{id}.png`（player.png / merchant.png）|
| 怪物 | `assets/creatures/{id}.png`（slime/skeleton/wolf/zombie/bat...）|
| 动物 | `assets/animals/{id}.png`（chicken/cow/pig/sheep/duck/goose...）|
| 可采集物件 | `assets/resources/{id}.png`（1列×3行：正常/受损/枯竭）|
| 建筑 | `assets/sprites/buildings/{id}.png`（单帧静态）|
| 物品图标 | `assets/sprites/items/icons.png`（整张网格表）|
| 地砖 | 见 `docs/art/tiles.md` + `world_generator` 的 atlas |

> 贴图 id 必须与 `data/*.json` 里的 id 一致（creatures.json / animals.json / buildings.json / items.json）。

### 4. 物品图标网格
整张图标表放 `assets/sprites/items/icons.png`，然后改 `ItemDatabase` 的 `ICON_GRID_COLS`（图标尺寸会自动按 `表宽/列数` 推导）。各物品的格子位置在 JSON 的 `icon_grid: [列,行]`。

### 5. 建筑/物件 scale
若新包建筑像素密度不同，调 `ArtProfile.BUILDING_SCALE` / `OBJECT_SCALE`。

### 6. 风格基调与锚点
- 更新 `docs/art/README.md` 的「整体风格基调」——当前写的是 Minecraft 方块风，换星露谷式柔和像素要改掉，**两种风格不能混**。
- 角色脚部锚点：各 entity 的 `Visual.position`（如 player 的 `VISUAL_BASE_Y = -16`）按新角色高度可能要微调，让脚踩在格子上。

### 7. 验证
跑游戏看：角色四向行走对不对、朝向是否一致（不对就调 `char_row_order`）、大小是否合适（调 `*_TARGET_H`）、物品图标是否错位（调 `ICON_GRID_COLS` / `icon_grid`）。

## 三、已接入（测试，验证适配层）

**玩家角色** 已替换为一套 CC0 真实角色作为概念验证：
- 来源：OpenGameArt「32x64 Female Base Sprite (walking 4 directions)」**CC0**
  https://opengameart.org/content/32x64-female-base-sprite-walking-4-directions
- 处理：原始 `strip16`（512×64，16 帧横排，帧 32×64）→ 用 PIL 重排为游戏的 4 行×4 列布局（128×256，帧 32×64）→ `assets/sprites/characters/player.png`
- **适配层自动生效**：源帧高 64，`scale_for` 自动算出 scale=0.5，让它和其他占位角色一样显示 32 高——证明换不同尺寸的源贴图无需改代码。
- ⚠️ **若四向行走方向对应错乱**（如按"下"却朝上走）：strip 的方向段顺序与假设的"下/上/左/右"不同，改 `ArtProfile.char_row_order`（如 `[0,2,3,1]`）即可，无需重新处理图。
- 其他角色/怪物/动物/建筑仍是占位，按本指引逐类替换即可。

## 四、最省心路线
Cute Fantasy RPG（$2.99）主力 → 免费怪物包补 wolf/zombie/bat → 自动化保留几何占位。总成本 ~$3，覆盖 95%。
