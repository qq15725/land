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

> 已完成大循环后，按下方路线持续迭代。每个分类内可独立推进，互不阻塞。
>
> **战略主线（2026 Q2 起）**：
> 1. **补齐 HUD**（路线 E）—— 把愿景图 [`references/main.png`](references/main.png) 中的信息密度补到位
> 2. **多人架构改造**（路线 G）★ **强制前置** —— 已决策支持局域网多人联机（ENet host-authoritative）。**F 自动化必须建立在多人架构之上**，否则后期重写代价过大
> 3. **自动化建造**（路线 F）—— 参考图三大卖点之一
> 4. **以自动化 + 多人为设计锚**：后续 B/D 路线的新建筑、新生物、新作物、新机制，**默认评估**：①能否作为自动化的输入源/输出/处理器；②状态是 server-authoritative 还是 client-local

### A. QoL 与流程闭环 ✅
> 不引入新玩法，只把现有流程做顺滑。

- [x] A1 快捷栏（HUD 底部 9 格 hotbar，1-9 数字键直接选；选中边框同步背包）
- [x] A2 死亡惩罚 + 重生点（新增 `bed` 建筑，死亡复活到最近的床；非装备物品掉一半数量在死亡地点）
- [x] A3 自动保存（5 分钟周期 + 进入新天触发，HUD toast 提示）

### B. 玩法深度
> 让玩家从 30 分钟玩到 30 小时。

- [x] B1 货币系统（G 金币 + 商人收购农产品 + UI 显示余额）
- [ ] B2 钓鱼系统（水域 tile + 鱼竿物品 + 鱼数据 + 钓鱼小游戏）
- [ ] B3 天气（下雨 / 雪 / 雷暴；下雨自动浇灌作物）
- [ ] B4 成就 / 图鉴（收集进度、击杀统计、合成种类）
- [ ] B5 节日 / 季节事件（春樱 / 秋丰收 / 冬雪人）
- [ ] B6 PvE 平衡 + Boss / 副本（怪物难度递增曲线，季节性 Boss）
- [x] B7 战斗反馈（DamageNumber 飘字 + hit-stop 60ms + KNOCKBACK ×1.5 + 15% 暴击 ×2 倍伤 + combo 计数→HUD toast）

### C. 质量打磨 / 已知 bug
> 存量问题清理。

- [x] C1 `trading_post._activated` 存档（加 get_save_state/load_save_state，读档自动重激活）
- [x] C2 `animal._is_fed` / `_produce_timer` 存档（由 animal_pen 收集子 animal 状态，读档延迟一帧喂回）
- [x] C3 UI 按钮音效（SoundSystem 监听 SceneTree.node_added，所有 Button.pressed 自动播 ui_click）
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

### E. HUD / UI 完善
> 文档：[`art/hud.md`](art/hud.md)。参考图：[`references/hud.png`](references/hud.png) + [`references/main.png`](references/main.png)。
> 当前 HUD 只有左上 HP/金币/时间 + 底部 9 格 hotbar，远低于愿景图密度。

- [~] E1 角色信息条（头像+名字+Lv+HP/MP/FP 三条，结构已搭；HP/MP 已接通；**FP 系统未实现** 固定 100/100 占位；经验条统一放底部 hotbar 上方）
- [x] E2 快捷栏强化（9-patch 容器 + 经验条 + 等级徽章 + 亮黄选中边框）
- [x] E3 小地图实绘（Minimap 控件：玩家黄点 + 朝向三角 + 附近建筑/农田/怪物色点）
- [ ] E4 状态 Buff 条（**依赖 Buff 系统**，未实现）
- [x] E5 资源计数行（金币 + 当前选中物品 + 基地占位）
- [ ] E6 任务追踪条（**依赖任务系统**，未实现）
- [x] E7 顶右菜单按钮组（👤 角色 / 🗺 地图 / ⚙ 设置，模拟键盘动作打开对应面板）

### G. 多人架构改造 ★ 主线 / F 前置
> **决策已定**：支持局域网多人联机，传输层用 ENet host-authoritative（房主即权威）。单机视为 1 人房间，统一走多人代码路径，不维护两套实现。
>
> **设计决策（已锁定）**：
> - 协作模式：**纯合作**（同房无 PvP）
> - 死亡惩罚：**掉一半物品在原地，所有人可捡**（沿用单人逻辑）
> - 储物箱权属：**全员共享**（合作向，无锁）
> - 存档权限：**仅房主能存**（单一权威源）
> - 跨网范围：**仅局域网**（先做）；后期再考虑 UPnP / WebRTC
>
> **阶段 A · 架构改造** ✅ 已完成（单机继续正常运行，代码按多人规范写）
- [x] G1 多人协议层（Network autoload + OfflineMultiplayerPeer 包装单机；ENet host/client 接口；`multiplayer.is_server()` 在单机返回 true）
- [x] G2 实体 network_id（NetworkRegistry 注册表 + 7 类实体 _ready 时 attach 获得 int ID；存档持久化 next_id 防回退）
- [x] G3 输入抽象（PlayerActions autoload 9 个 server-auth 动作入口；DropItem 拾取走 server 仲裁）
- [x] G4 SkillSystem 拆 per-player（PlayerSkills 组件下沉数据；EventBus 3 信号加 player 参数；修复砍树挖矿不加 xp 的 dead signal）
- [x] G5 系统行为 ID 化（Crafting/Building 签名 Player 化；UI 走 PlayerActions，不直接改 InventoryComponent）
- [x] G6 EventBus 参数 ID 化（5 个含 Node 引用的信号改 int network_id；数据对象 ItemData/CreatureData 等保留）
- [x] G7 存档拆 world / per-player（v2 结构 `{world, players[]}`，v1 旧存档兼容加载）

> **阶段 B · 实际联机** 🟡 基础设施铺设完毕，需双开 Godot 实测打磨
- [x] G8 玩家节点同步（Player 加 MultiplayerSynchronizer 同步 position/hp/anim；authority = peer_id；非 authority 不跑物理/输入；远程玩家头顶名字）
- [x] G9 世界实体 Spawner（world 添加 MultiplayerSpawner 监听 YSortLayer；spawnable scenes 配置完毕；仅多人启用，避免污染单机 ChunkManager）
- [x] G10 DropItem 同步（含在 G9 spawnable；拾取走 PlayerActions.request_pickup server 仲裁）
- [x] G11 主菜单房间界面（创建房间 / 加入房间 + IP/端口输入 + 可选 UPnP 复选框）
- [x] G12 HUD 多人增强（HUD setup 时找本地玩家；远程玩家头顶名字标签 `display_name #peer_id`）
- [x] G13 UPnP 端口转发（`Network.try_open_upnp(port)`，host 启动时可选启用）
- [ ] G14 实测打磨（同机双开 Godot 对联；ChunkManager 动态 add_child 需改 force_readable_name=true；建筑/资源/怪物状态同步细节）

### F. 自动化建造 ★ 主线
> **前置**：必须完成 G 路线阶段 A（G1–G7）。所有自动化节点、tick、物品流走 server-authoritative。
>
> 参考图三大卖点之一。设计原则：从"轻松休闲"延展到"看着自己工厂运转的爽感"，不走 Factorio 极致硬核路线。
>
> **设计目标**：玩家从 30 小时玩到 100 小时的核心驱动力。每个生产链 5–15 个节点，能 1 屏看完，不引入逻辑/电路。
>
> **未决策的关键设计问题（开工前需选）**：
> - 能源模型：无能源 / 燃料 / 电力 三选一
> - 节点连接：方块格 + 朝向（Minecraft 红石/管道风）/ 自由连线（Factorio 风）
> - 项目内多工厂：所有生产线都在主世界铺设 / 单独「工厂维度」入口
> - 与休闲玩法的关系：是替代手动操作（取代采集 / 烹饪）还是补充（手动更快 / 自动量大但低效）
> - 多人下工厂权属：全员共享 / 个人产权 / 跟随建筑权属设定

- [ ] F1 物品流核心（数据结构：节点 / 连接 / 物品 token；tick 调度）
- [ ] F2 传送带建筑（带朝向、可串联，渲染流动动画）
- [ ] F3 抽取器（从资源节点 / 农田 / 动物围栏 / 储物箱抽取物品到传送带）
- [ ] F4 放入器（从传送带送入储物箱 / 烹饪锅 / 烤炉 / 工作台）
- [ ] F5 自动合成机（绑定 recipe，从输入传送带接收材料，输出到输出传送带）
- [ ] F6 农田自动化接口（自动播种 / 浇水 / 收获 → 现有 FarmPlot 加 IO 端口）
- [ ] F7 动物围栏自动化接口（自动喂食 / 收集产出）
- [ ] F8 分流 / 合流 / 过滤器（按物品 id 分流，作为基础逻辑节点）
- [ ] F9 生产线总览 UI（俯瞰图 + 瓶颈高亮 + 吞吐统计）
- [ ] F10 能源系统（按选定模型实施 F1–F9 的能耗约束）

### 长期搁置

**教学 / 任务类（需要先有完整内容再做引导）**
- 新手引导（首次进入弹气泡 + 高亮按键，覆盖 E/Tab/C/B/F/J/K/I）
- 任务 / 主线系统（任务面板 + 阶段目标 + 奖励发放）
- 村落系统（真实 NPC 村落、好感度、对话、任务线）

**架构级扩展（需独立大改）**
- MOD 支持
- 本地化（中/英 / 切换)

**愿景图候选大模块（main.png 提到但未立项）**
- 遗迹 / 地牢副本（独立场景 + 入口建筑 + 生成式房间 + Boss 房间宝箱）—— 对应 B6，可作为 B6 的具体落地形式
- 同伴 / 宠物系统（跟随 NPC、可指令、可装备、可成长）—— 参考图展示"可爱的伙伴"群像，会引入跟随 AI + 宠物背包等新组件

---

## 当前进度

**已完成**：Phase 0–8 + 路线 A（QoL）+ B1（货币）+ 路线 G 阶段 A 全部（G1–G7 多人架构改造）+ 阶段 B 基础设施（G8–G13）+ 战斗系统抽象（见下）

**战斗系统（2026-05-13 完成）**：
- **数据驱动技能**：`ActiveSkillData` 30+ 字段；`data/active_skills.json` 4 招（basic_swing / triple_slash / fireball / whirlwind）
- **统一入口**：`SkillExecutor` 按 shape 派发（fan/circle/rect/projectile），多段 tick 命中，server-authoritative
- **VFX 体系**：`VFXLibrary` autoload + `scenes/vfx/{id}.tscn` + 通用 `vfx_geom.gd`；占位几何先用，美术按 `docs/art/vfx.md` 替换
- **状态机**：`PlayerAnimState` 组件 (cast_fan/cast_circle/cast_rect/cast_projectile/hit/die)，等 character 帧扩展自动接入
- **预留**：职业 `class_id`、技能树 `parent_skill_id`、技能学习 `learned[]`、技能装配 `equipped_skills[5]`
- **资源约定**：`AssetPaths` 统一路径；`ZLayer` 全局 z_index 常量

**战略主线（已确定）**：
1. **路线 E · 补齐 HUD** ✅ 信息密度已对齐参考图，hud.gd 12 部件全接美术
2. **路线 G · 多人架构改造** ✅ 阶段 A 全部完成（架构）；阶段 B 基础设施完成（G8–G13），G14 待双开 Godot 实测打磨
3. **路线 F · 自动化建造** —— G 阶段 A 已完成前置，可开工
4. **B / D 路线**：所有新内容需同时满足「可接自动化」+「server-authoritative」

**与主线无关的清理工作**（任何时候可插入）：
- C1 + C2 + C3：三个轻量 bug
- 现存 A 路线都已完成；B1 货币已完成
