# Roadmap

## 阶段划分

### Phase 0 · 基础骨架 ✅
> 目标：能跑起来的最小世界，玩家能动、能采集、能捡东西

- [x] 项目结构搭建（目录、Autoload注册）
- [x] 玩家移动（8方向 + 摄像机跟随）
- [x] Y-sort 层级排序
- [x] 基础世界生成（单Biome、随机散布资源）
- [x] 可采集资源节点（树/石，带交互提示）
- [x] 物品数据层（ItemResource 基类）
- [x] 背包系统（数据层）
- [x] 掉落物 + 自动拾取

---

### Phase 1 · 建造与合成 ✅
> 目标：能采集 → 合成 → 建造基地

- [x] 合成系统（RecipeResource + CraftingSystem）
- [x] 工作台建筑（解锁工作台配方）
- [x] 建造系统（选蓝图 → 预览 → 放置 → 消耗材料）
- [x] 建筑基类（耐久）
- [x] 储物箱建筑（独立 InventoryComponent，点击转移物品）
- [x] 背包 UI（Tab 键，格子显示）
- [x] 合成面板 UI（C 键，灰显不可合成配方）
- [x] 建造菜单 UI（B 键）
- [x] HUD（生命值进度条、建造模式提示）

---

### Phase 2 · 农场 ✅
> 目标：能种菜、能养殖、产出形成循环

- [x] 耕地系统（播种 → 生长 → 收获，数据驱动）
- [x] 作物生长周期 + 数据驱动（胡萝卜/小麦）
- [x] 农田建筑（可建造，E 键交互播种收获）
- [x] 鸡圈建筑（放置后自动生成鸡）
- [x] 动物 AI（游荡，限定半径）
- [x] 喂食逻辑（消耗饲料，计时产出）
- [x] 动物产出采集（鸡蛋掉落，自动拾取）
- [x] 烹饪锅建筑（解锁烹饪配方）
- [x] 烹饪系统（胡萝卜 → 烤胡萝卜，恢复生命值）
- [x] F 键使用选中物品（食物回血）
- [x] 背包槽位点击选中，HUD 显示当前物品

---

### Phase 3 · 世界与怪物 ✅
> 目标：世界有内容，有探索价值，有威胁感

- [x] 昼夜循环（TimeSystem，白天120s/夜晚60s，HUD显示）
- [x] 夜晚黑暗叠加层（渐变暗化效果）
- [x] 怪物数据层（CreatureResource，掉落表）
- [x] 怪物场景（状态机：游荡/追击/攻击/死亡）
- [x] 怪物攻击行为（夜晚刷新，检测玩家后追击）
- [x] 玩家近战攻击（J键，击退效果）
- [x] 死亡 + 复活流程（原地掉落，2秒后原点复活）
- [x] 怪物掉落表（史莱姆掉石头，骷髅掉木头/石头）
- [ ] 多 Biome 世界生成（后续迭代）
- [ ] Chunk 按需加载/卸载（后续迭代）
- [ ] 四季系统（后续迭代）

---

### Phase 4 · 交易 ✅
> 目标：产出有出口，稀有内容有获取途径

- [x] 贸易站建筑（木材×12 + 石头×8，E键激活）
- [x] TradeSystem Autoload（管理商人来访计时、随机选商人）
- [x] 商人 NPC 场景（走路到贸易站，停留后淡出离开）
- [x] 商人交易表（TradeEntry 数据驱动）
- [x] 交易面板 UI（显示给/换物品，背包不足时灰显）
- [x] 行商（农产品换稀有种子/图纸，180s间隔）
- [x] 矿商（矿物/木材换稀有种子/图纸，240s间隔）
- [x] 新物品：稀有种子、配方图纸

---

### Phase 5 · 打磨 & 体验 ✅
> 目标：可玩的完整 Demo

- [x] 存档系统（序列化玩家背包/位置/血量、资源节点、农田、时间/天数）
- [x] 主菜单（3个存档槽，显示天数/时间/保存时间）
- [x] 暂停菜单（ESC：继续/保存/保存并退出）
- [x] 粒子效果（采集物品颜色、受伤红色、收获金色）
- [x] 主场景改为主菜单，游戏从主菜单进入
- [ ] 音效 + 背景音乐（后续迭代）
- [ ] 游戏内教程/新手引导（后续迭代）

---

### Phase 6 · 数据抽象化与美术接入
> 目标：所有实体类型从 JSON 批量加载，接入像素风美术资源，淘汰逐文件的 .tres 方式

#### 数据层重构
- [ ] 定义通用 GDScript 数据类（`ItemData` / `CreatureData` / `ResourceNodeData` / `BuildingData` / `CropData` / `AnimalData`），不继承 Resource，字段间引用改为 `id` 字符串
- [ ] 编写 JSON 数据文件（`data/items.json` / `creatures.json` / `resource_nodes.json` / `buildings.json` / `crops.json` / `animals.json` / `recipes.json` / `trades.json`）
- [ ] `ItemDatabase` 重写：加载全部 JSON → 解析为数据对象 → 统一按 `id` 查询；所有跨类引用（如配方里的 item_id）在全部加载完后集中解析
- [ ] `RecipeIngredient` / `TradeEntry` 改为用 `item_id` 字符串，不再持有对象引用
- [ ] `BuildingSystem` / `CraftingSystem` / `TradeSystem` 适配新数据类
- [ ] 移除旧 `.tres` 数据文件及对应 Resource 基类

#### 通用场景
- [ ] 删除 `tree_node.tscn` / `stone_node.gd` 等空壳场景，统一用一个 `resource_node.tscn`；world.gd 按 JSON 配置动态实例化资源节点
- [ ] world.gd 夜晚刷怪改为从 JSON 读取怪物列表（移除 `_slime_data` / `_skeleton_data` 硬编码 preload），按权重随机生成
- [ ] `animal_pen` 的动物种类改由 `BuildingData` 字段决定，不再用场景 `@export`
- [ ] `drop_item` 视觉从颜色方块（`Polygon2D`）改为 `Sprite2D` 显示物品图标
- [ ] 物品图标动态加载（路径写在 JSON，`load()` 在运行时载入）

#### 美术资源接入
- [ ] player / creature / merchant / animal 的 `Sprite2D` 换成 `AnimatedSprite2D`，配置 `SpriteFrames`（4方向 × 4帧行走）
- [ ] 怪物 `creature.gd` 移除 `sprite_scale` 字段，改为统一尺寸精灵表
- [ ] 资源节点换成 `AnimatedSprite2D`（3帧：正常 / 受击 / 破坏），破坏帧播完后淡出
- [ ] 建筑接入静态 `Sprite2D`（48×48）
- [ ] 物品图标精灵表接入，`drop_item` 和背包格子按图标坐标切割显示
- [ ] 所有精灵路径写在 JSON 的 `sprite` 字段，运行时 `load()`

#### UI 优化
- [x] `DraggablePanel` 基类（背包 / 合成 / 储物箱 / 交易 / 建造面板均可拖拽）
- [ ] 像素风 UI 皮肤：面板 9-patch 背景、按钮三态、物品格子（参考 `docs/art-prompts.md`）
- [ ] 像素风字体接入（替换 Godot 默认字体，全局 Theme 统一设置）
- [ ] HUD 美化：图片血量条（背景 + 填充）、昼夜图标、当前物品框
- [ ] 面板细节对齐：标题栏拖拽区域视觉提示（cursor 变化）、关闭按钮样式统一

---

## 当前进度

**当前阶段**：Phase 5 完成，进入 Phase 6

**最近完成**：Phase 5 — 存档/主菜单/暂停/粒子效果

---

## 搁置 / 后续考虑

- 村落系统（真实 NPC 村落、好感度、任务线）—— Phase 6 之后扩展
- 多人联机
- MOD 支持
