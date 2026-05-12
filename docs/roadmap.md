# Roadmap

## 阶段划分

### Phase 0 · 基础骨架 ✅
> 目标：能跑起来的最小世界，玩家能动、能采集、能捡东西

- [x] 项目结构搭建（目录、Autoload 注册）
- [x] 玩家移动（8 方向 + 摄像机跟随）
- [x] Y-sort 层级排序
- [x] 基础世界生成（单 Biome、随机散布资源）
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

- [x] 昼夜循环（TimeSystem，白天 120s / 夜晚 60s，HUD 显示）
- [x] 夜晚黑暗叠加层（渐变暗化效果）
- [x] 怪物数据层（CreatureResource，掉落表）
- [x] 怪物场景（状态机：游荡/追击/攻击/死亡）
- [x] 怪物攻击行为（夜晚刷新，检测玩家后追击）
- [x] 玩家近战攻击（J 键，击退效果）
- [x] 死亡 + 复活流程（原地掉落，2 秒后原点复活）
- [x] 怪物掉落表（史莱姆掉石头，骷髅掉木头/石头）

---

### Phase 4 · 交易 ✅
> 目标：产出有出口，稀有内容有获取途径

- [x] 贸易站建筑（木材×12 + 石头×8，E 键激活）
- [x] TradeSystem Autoload（管理商人来访计时、随机选商人）
- [x] 商人 NPC 场景（走路到贸易站，停留后淡出离开）
- [x] 商人交易表（TradeEntry 数据驱动）
- [x] 交易面板 UI（显示给/换物品，背包不足时灰显）
- [x] 行商（农产品换稀有种子/图纸，180s 间隔）
- [x] 矿商（矿物/木材换稀有种子/图纸，240s 间隔）
- [x] 新物品：稀有种子、配方图纸

---

### Phase 5 · 打磨 & 体验 ✅
> 目标：可玩的完整 Demo

- [x] 存档系统（序列化玩家背包/位置/血量、资源节点、农田、时间/天数）
- [x] 主菜单（3 个存档槽，显示天数/时间/保存时间）
- [x] 暂停菜单（ESC：继续/保存/保存并退出）
- [x] 粒子效果（采集物品颜色、受伤红色、收获金色）
- [x] 主场景改为主菜单，游戏从主菜单进入

---

### Phase 6 · 数据抽象化与美术接入 ✅
> 目标：所有实体类型从 JSON 批量加载，接入像素风美术资源

#### 数据层重构
- [x] 定义通用 GDScript 数据类（`ItemData` / `CreatureData` / `ResourceNodeData` / `BuildingData` / `CropData` / `AnimalData`），不继承 Resource，字段间引用改为 `id` 字符串
- [x] 编写 JSON 数据文件（`data/items.json` / `creatures.json` / `resources.json` / `buildings.json` / `crops.json` / `animals.json` / `recipes.json` / `trades.json`）
- [x] `ItemDatabase` 重写：加载全部 JSON → 解析为数据对象 → 统一按 `id` 查询；跨类引用集中解析
- [x] `RecipeData` / `TradeEntry` 改为用 `item_id` 字符串
- [x] `BuildingSystem` / `CraftingSystem` / `TradeSystem` 适配新数据类

#### 通用场景
- [x] 统一用一个 `resource.tscn`，按 JSON 配置动态实例化资源节点
- [x] 夜晚刷怪从 JSON 读取怪物列表，按权重随机生成
- [x] `animal_pen` 的动物种类由 `BuildingData.animal_id` 决定
- [x] `drop_item` 视觉从 Polygon2D 改为 Sprite2D 显示物品图标
- [x] 物品图标动态加载（路径配置在 ItemDatabase）

#### 美术资源接入
- [x] player / creature / merchant / animal 用 `AnimatedSprite2D` + `SpriteFrames`（4 方向 × 4 帧行走）
- [x] 资源节点 3 帧动画（正常 / 受击 / 破坏 + tween 淡出）
- [x] 建筑通过 `BuildingBase` 抽象统一加载 `sprite_path`，缺失时回退占位
- [x] 物品图标精灵表接入，`drop_item` 和 UI 格子按 `icon_grid` 切割
- [x] 占位美术 + 完整 docs/art/ 提示词文档（`docs/art/README.md` 索引）

#### UI 优化
- [x] `DraggablePanel` 基类（背包 / 合成 / 储物箱 / 交易 / 建造面板均可拖拽）
- [x] 像素风 UI 皮肤（panel 9-patch / 按钮三态 / slot 槽位 / progress bar）
- [x] 像素字体接入预留（`assets/fonts/pixel.ttf` 自动接入 Theme）
- [x] HUD 美化（图片血量条、昼夜符号、当前物品框）
- [x] ItemIcon 通用控件 + tooltip 自定义气泡

---

### Phase 7 · 世界深度与系统补完 ✅
> 目标：把世界做大、做活、做出可玩的循环

#### 世界生成
- [x] 多 Biome 世界生成（草原/森林/山地/沼泽 + 权重图）
- [x] Chunk 按需加载 / 卸载（围绕玩家半径加载，超出存 snapshot）
- [x] 四季系统（春/夏/秋/冬，每季 7 天，作物受季节限制）

#### 内容深度
- [x] 工具系统（axe / pickaxe + tool_required 校验）
- [x] 怪物扩展（slime / skeleton / wolf / zombie / bat）
- [x] 动物扩展（chicken / cow / pig / sheep）
- [x] 作物扩展（胡萝卜 / 小麦 / 土豆 / 番茄 / 玉米 / 南瓜）
- [x] 食物 / 配方扩展（蘑菇汤 / 南瓜汤 / 玉米饼 / 烤肉 / 浆果酱）

#### 系统补完
- [x] 音效系统（SoundSystem + EventBus 自动播放）
- [x] BGM 系统（昼夜自动切歌）
- [x] 设置菜单（主音量 / SFX / BGM / 全屏，`user://settings.json` 持久化）
- [x] 物品 tooltip（自定义气泡显示效果 chip + 描述）

---

### Phase 8 · 装备与技能 ✅
> 目标：装备 / 进度系统，给玩家持续养成的目标

#### 装备
- [x] `ItemData` 加 `equip_slot` / `damage` / `defense` / `attack_speed` / `ranged` / `ammo_item_id`
- [x] 装备物品：木剑 / 铁剑 / 短弓 / 箭矢 / 皮甲 / 铁甲 / 幸运护符 + 合成配方
- [x] `InventoryComponent` 加 `equipped` 字典 + `equip_from_slot` / `unequip`
- [x] 玩家攻击伤害集成装备 bonus；远程武器消耗弹药
- [x] `HealthComponent.damage_reduction` 由 armor 同步
- [x] 背包 UI 顶部装备槽（武器/护甲/饰品）+ 点击装备/卸下

#### 技能
- [x] `SkillSystem` autoload（farming / mining / woodcutting / combat）
- [x] 4 个技能数据驱动（`data/skills.json`）
- [x] EventBus 监听 `resource_depleted` / `crop_harvested` / `creature_killed` 自动加 xp
- [x] 等级 bonus（每级 +1.5% 额外掉落概率）
- [x] 技能面板 UI（K 键，4 行进度条）
- [x] 存档接入（装备 + 技能 xp 持久化）

---

## 后续规划（长期）

> 已完成大循环后，按下方四组路线持续迭代。每个分类内可独立推进，互不阻塞。

### A. 玩家上手 / 流程闭环
> 让新人 5 分钟内能玩起来。Demo 能不能交付的关键。

- [ ] A1 新手引导（首次进入弹气泡 + 高亮按键，覆盖 E/Tab/C/B/F/J/K 7 个核心交互）
- [ ] A2 首要目标 / 任务系统（任务面板 + 主线引导："砍 5 木→做工作台→建箱子→种菜"）
- [ ] A3 快捷栏（1-9 数字键直接选物品，hotbar 显示在 HUD 底部）
- [ ] A4 死亡惩罚 + 重生点（家/床作为重生位置；死亡掉落部分背包）
- [ ] A5 自动保存（按时间间隔 / 进入新天 / 关键事件触发）

### B. 玩法深度
> 让玩家从 30 分钟玩到 30 小时。

- [ ] B1 货币系统（G 金币 + 商人收购农产品 + UI 显示余额）
- [ ] B2 钓鱼系统（水域 tile + 鱼竿物品 + 鱼数据 + 钓鱼小游戏）
- [ ] B3 天气（下雨 / 雪 / 雷暴；下雨自动浇灌作物）
- [ ] B4 任务 / 成就 / 图鉴（在 A2 任务系统之上扩展，含收集进度）
- [ ] B5 节日 / 季节事件（春樱 / 秋丰收 / 冬雪人）
- [ ] B6 PvE 平衡 + Boss / 副本（怪物难度递增曲线，季节性 Boss）

### C. 质量打磨 / 已知 bug
> 存量问题清理。

- [ ] C1 `trading_post._activated` 状态不存档 → 读档后商人不再来
- [ ] C2 `animal._is_fed` / `_produce_timer` 不存档 → 读档后动物喂食状态丢失
- [ ] C3 UI 按钮无音效（`ui_click` 数据已就绪，但没有触发点）
- [ ] C4 性能 stress test（高密度资源/怪物 + chunk 边界）
- [ ] C5 移动端控制完整性（`mobile_controls.gd` 验证 + 适配）
- [ ] C6 升级 / 装备变更 / 收获 / 放置粒子反馈
- [ ] C7 面板细节对齐（标题栏拖拽区域 cursor、关闭按钮样式统一）

### D. 内容广度
> 数据扩展，纯加法。

- [ ] D1 装饰建筑（花盆 / 椅子 / 路灯 / 旗帜 / 喷泉）
- [ ] D2 多功能建筑（井——浇水、烤炉——高级烹饪、铁砧——修武器、磨坊——小麦→面粉）
- [ ] D3 野生生物（兔子/鹿被动 + 鱼）
- [ ] D4 稀有事件（流星雨夜、神秘旅行商人、地牢宝箱）
- [ ] D5 服装 / 外观（玩家装扮，与战斗装备独立的视觉皮肤）

### 长期搁置
- 村落系统（真实 NPC 村落、好感度、对话、任务线）—— 比 A2 / B4 更重的社交内容
- 多人联机
- MOD 支持
- 本地化（中/英 / 切换）

---

## 当前进度

**已完成**：Phase 0–8（基础玩法 + 数据抽象 + 美术占位接入 + 世界深度 + 装备技能）

**下一步建议路线**：
- 若优先"能交付 Demo"：A1 → A2 → A3 → A5（一周内补齐上手体验）
- 若优先"内容更厚"：B1 → B4 → B2（货币奠基 → 任务图鉴 → 钓鱼）
- 若优先"修存量"：C1 + C2 + C3（三个轻量 bug 一起做）
