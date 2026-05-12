# Land — 2.5D 休闲生存经营游戏

## 项目概述

2.5D 斜视角休闲游戏，使用 Godot 4 开发。核心玩法围绕采集、建造、种菜、养殖展开，世界中有游荡怪物作为威胁，通过建造贸易站与商人交易获取稀有资源。无饥饿/精神压力，节奏轻松。

## 技术栈

- **引擎**：Godot 4
- **语言**：GDScript
- **渲染**：2D + Y-sort 模拟 2.5D 纵深
- **数据驱动**：物品/配方/生物/作物参数使用 Resource 定义，不硬编码

## 架构原则

- 功能拆分为独立组件（Component），挂载到实体节点，避免大型单体脚本
- 系统间通过**信号（Signal）**或全局 **EventBus** 解耦
- 全局系统注册为 **Autoload 单例**
- 新增物品/配方/生物/作物只加数据文件，不改系统代码
- 每个功能做最小可运行版本再迭代，不过度设计

## 目录结构

```
land/
├── scenes/
│   ├── world/              # 世界场景、资源节点
│   ├── entities/
│   │   ├── player/         # 玩家
│   │   ├── creature/       # 怪物
│   │   ├── merchant/       # 商人 NPC
│   │   └── drop_item/      # 掉落物
│   ├── buildings/          # 可建造建筑
│   ├── farm/               # 农田、养殖围栏、动物
│   ├── ui/                 # 所有 UI 场景
│   └── effects/            # 粒子效果
├── scripts/
│   ├── components/         # 可复用组件（HealthComponent、InventoryComponent）
│   ├── systems/            # 全局系统（Autoload）
│   ├── data/               # GDScript Resource 数据类定义
│   └── utils/              # 工具脚本（DraggablePanel、UIStyle）
├── data/                   # JSON 格式游戏数据（物品/配方/建筑/作物/动物/怪物/交易）
├── resources/              # Godot .tres 资源文件（目前未使用，备用）
├── assets/
│   ├── sprites/
│   │   ├── characters/     # 玩家、商人精灵表
│   │   ├── environment/    # 地砖 atlas、草/灌木/蘑菇等
│   │   ├── buildings/      # 建筑精灵
│   │   ├── items/          # 物品图标表
│   │   └── ui/             # UI 精灵表
│   ├── animals/            # 动物精灵（chicken 等）
│   ├── creatures/          # 怪物精灵（slime、skeleton 等）
│   ├── resources/          # 资源节点精灵（tree、stone 等）
│   └── maps/               # 预设地图图片（0.png、0-0.png 等）
├── docs/                   # 设计文档与美术提示词
│   └── references/         # 参考图
└── tools/                  # Python 离线工具（图集合成等）
```

## 全局系统（Autoload）

| 单例名 | 脚本 | 职责 |
|--------|------|------|
| `EventBus` | `scripts/systems/event_bus.gd` | 全局信号中转 |
| `GameManager` | `scripts/systems/game_manager.gd` | 游戏状态、流程控制 |
| `ItemDatabase` | `scripts/systems/item_database.gd` | 物品/配方/建筑/怪物注册表，从 `data/*.json` 加载 |
| `CraftingSystem` | `scripts/systems/crafting_system.gd` | 合成逻辑 |
| `BuildingSystem` | `scripts/systems/building_system.gd` | 建造模式、建筑放置 |
| `TimeSystem` | `scripts/systems/time_system.gd` | 昼夜循环、季节 |
| `TradeSystem` | `scripts/systems/trade_system.gd` | 商人刷新、交易逻辑 |
| `SaveSystem` | `scripts/systems/save_system.gd` | 存档读写 |
| `UpdateSystem` | `scripts/systems/update_system.gd` | 版本更新检查 |
| `WorldGenerator` | `scripts/systems/world_generator.gd` | 地形生成、TileSet 构建 |
| `UIStyle` | `scripts/utils/ui_style.gd` | 全局 UI 样式工具 |

## 核心组件

已实现：
```
HealthComponent       # 生命值、受伤、死亡（scripts/components/health_component.gd）
InventoryComponent    # 物品槽、堆叠逻辑（scripts/components/inventory_component.gd）
```

规划中（尚未实现）：
```
AIComponent           # 怪物状态机（游荡/警觉/攻击/逃跑）
InteractableComponent # 可交互标记与范围检测
DurabilityComponent   # 工具/建筑耐久
GrowthComponent       # 作物/动物生长状态
```

## 功能模块

### 世界生成
- Chunk 分块，按需加载卸载
- Biome 权重图驱动分区：草地、森林、沼泽、山地
- 资源/怪物按 Biome 规则程序化分布
- 昼夜循环 + 四季，影响作物品种和怪物活跃度

### 采集
- 可交互资源：树、矿石、草、浆果、蘑菇等
- 工具区分（斧头砍树、镐子挖矿），提升采集效率
- 资源有再生周期，稀有资源在特定 Biome

### 建造
- 自由放置建筑，消耗材料
- 建筑类型：住所、仓库、工作台、围栏、装饰
- 建筑有耐久，可修复

### 种菜
- 耕地 → 播种 → 浇水 → 收获
- 作物有生长周期，四季影响可种品种
- 仓库存储收成，食物可烹饪恢复生命值

### 养殖
- 围栏圈养动物（鸡/猪/牛）
- 喂食、繁殖、采集产出（蛋/奶/皮毛）
- 轻量心情值影响产出，不构成压迫

### 交易系统（第一版）
- 建造**贸易站**后，商人 NPC 周期性来访
- 商人携带稀有种子、配方图纸、特殊材料
- 用农产品/矿物/动物产出与商人交换
- 不同商人有不同交易表，由数据驱动
- 后续版本扩展为真实村落、好感度、任务线

### 怪物
- 各 Biome 有对应游荡怪物，默认中性
- 被攻击或夜晚靠近据点时转为攻击状态
- 夜晚活跃度整体提升
- 击杀掉落皮/骨/特殊材料，驱动合成需求

### 战斗
- 玩家近战/远程攻击
- 生命值，可用食物恢复
- 死亡原地掉落，原地复活

### 物品与合成
- 所有物品由 Resource 数据定义（图标、名称、堆叠上限、耐久）
- 背包格子式 UI
- 手动合成 + 工作台合成，配方数据驱动

### 存档
- 序列化世界种子、Chunk 状态、玩家数据、时间/季节
- 多存档槽，主菜单选择

### UI
- HUD：生命值、当前工具、时间/季节指示
- 背包、合成面板、交易面板
- 主菜单、存档选择、暂停菜单

## 文档

- [`docs/roadmap.md`](docs/roadmap.md) — 开发阶段规划与待办事项，按 Phase 划分，开工前更新进度
- [`docs/art/`](docs/art/README.md) — 美术资源生成提示词（按类别分文件），含角色、环境、建筑、物品图标
- [`docs/sounds.md`](docs/sounds.md) — 音效与 BGM 资源映射、风格描述
- [`docs/map.md`](docs/map.md) — 地图设计图生成规范，含命名规则、颜色编码、AI 提示词

## 开发约定

- 回复和注释使用**简体中文**
- Y-sort 节点统一挂在 YSort 层，不混入 UI 层
- 新增内容优先加数据文件，不改核心系统
- 不写多余注释，命名即文档

## 提交规范

- git commit 信息不加 `Co-Authored-By`

## 美术 / 代码比例约定

美术文档（`docs/art/`）只描述源文件像素尺寸，不包含 Godot scale/zoom。代码层独立维护：

- Camera2D zoom = 4.0（每格 64 屏幕像素）
- 角色 / 怪物 `AnimatedSprite2D.scale = 0.125`（128×256 单帧源 → 16×32 世界单位 = 1×2 格）
- 环境物件 / 建筑 `Sprite2D.scale = 0.25`（源尺寸 ÷ 4 = 世界单位）

修改源文件标准尺寸或 scale 时需要双侧同步，否则新资产会显示错位。
