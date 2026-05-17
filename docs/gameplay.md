# 玩法总览

> 当前已实现的玩法快照，避免后续开发脱离已有循环。新建系统/内容前先回这里对一下定位。
> 进度状态见 [`roadmap.md`](roadmap.md)；本文只描述「现在玩起来是什么样」。

---

## 核心循环

**采集 → 合成 → 建造 → 种植 / 养殖 → 交易 / 战斗 → 升级 / 换装备 → 探索更多 Biome**

定位：**轻量休闲 + RPG 养成**。无饥饿、无精神值、无硬时间压力，但已有职业 / 主动技能 / 装备 / 怪物难度曲线，**战斗权重比传统 Stardew 类高**。

---

## 一、世界

- **4 Biome**：草原 / 森林 / 山地 / 沼泽（权重图分区，resources/creatures 按 Biome 分布）
- **Chunk 按需加载**，玩家半径外存 snapshot
- **昼夜循环**：白天 120s / 夜晚 60s，HUD 显示
- **四季**：春 / 夏 / 秋 / 冬，每季 7 天，作物受季节限制
- **夜晚色调压暗（CanvasModulate）+ 怪物刷新加压**
- **天气**：晴 / 雨 / 雪 / 雷暴（每日新一天按季节权重随机；雨自动加速作物 1.5×；雷暴有闪光）
- **节日**：每季固定一天触发（樱花祭 / 夏至 / 丰收节 / 雪人节），影响生长 / 怪物刷新 / 售价 / buff
- **稀有事件**：每晚低概率触发流星雨（陨石掉稀有矿）或神秘旅人来访（独立交易表）

## 二、玩家身份（开局选择）

- **3 职业**（`data/classes.json`）：
  - 战士 — 高 HP / 低 MP / 扇形 AOE
  - 法师 — 低 HP / 高 MP / 弹道
  - 弓手 — 均衡 / 矩形穿刺 / 连射
- **5 主动技能槽**（J 固定 basic_swing + Q/E/R/G 4 个可装配槽）
- **冒险岛风格技能**（`data/active_skills.json`，共 25 个）：每职业 8 个一转技能，含 3 类型 — **主动**（fan/circle/rect/projectile）/ **buff**（自挂状态）/ **passive**（被动占位，效果待接通）
- **真·技能树**：节点 + 父子连线（基于 parent_skill_id），按职业 tab 切换，冒险岛卡片样式（图标 + 名字 + Lv X/Max + [+] 学习按钮）
- **4 被动技能**（farming / mining / woodcutting / combat），事件自动 +xp，每级 +1.5% 额外掉落
- **装备 5 槽**（武器 / 护甲 / 饰品 / 装扮帽 / 装扮披风）
- **装扮**（cosmetic_hat / cosmetic_cape）独立于战斗装备，仅视觉
- **三条状态条**：HP（HealthComponent）/ MP（ManaComponent）/ FP（FocusComponent，技能消耗 + 食物恢复）

## 三、资源 / 合成 / 建造

- **35+ 物品**：原材料 / 食物 / 种子 / 装备 / 工具 / 装扮 / 陨石矿 / 鱼 / 面粉 / 鱼竿
- **工具系统**：斧（伐木）/ 镐（采矿）/ 鱼竿（钓鱼），`tool_required` 校验
- **23 种建筑**：
  - 功能：工作台、储物箱、烹饪锅、贸易站、农田、鸡圈、畜棚、筒仓、邮箱、床
  - 多功能：井（浇水 + swift buff）/ 烤炉（高级烹饪 station=oven）/ 铁砧（station=anvil）/ 磨坊（小麦→面粉）
  - 围栏：木栅栏 + 栅门、铁栅栏
  - 装饰：花盆 / 椅子 / 路灯（夜晚 PointLight2D 发光）/ 旗帜 / 喷泉
- **合成 / 烹饪**：手动 + 工作台 + 烹饪锅 + 烤炉 + 铁砧；配方 / 交易表全 JSON 驱动

## 四、农场

- **6 作物**：胡萝卜 / 小麦 / 土豆 / 番茄 / 玉米 / 南瓜
- **4 动物**：鸡（蛋）/ 牛（奶）/ 猪（肉）/ 羊（毛）；动物围栏 + 喂食 + 计时产出
- **5+ 烹饪配方**：烤胡萝卜 / 蘑菇汤 / 南瓜汤 / 玉米饼 / 浆果酱 / 烤肉，F 键使用回血

## 五、战斗

- **5 敌对怪物**：slime / skeleton / wolf / zombie / bat（夜晚刷新，状态机：游荡 / 追击 / 攻击 / 死亡）
- **2 野生 passive 生物**：兔子 / 鹿（白天 chunk 激活时刷，非主动，受击逃跑）
- **季节 Boss**：`season_bear`（每季最后一晚刷一只）；难度递增曲线：怪物 HP 每周 +10%（封顶 +200%，Boss 不叠）
- **25 技能**（冒险岛复刻）：数据驱动，`SkillExecutor` 按 shape 派发（fan / circle / rect / projectile / buff / passive），server-authoritative
  - 战士：强力一击、横扫千军、铁壁、剑术精通(被)、致命攻击-剑(被)、怒吼、格挡反弹、重击-剑
  - 法师：能量弹、魔法爪、魔法守护、魔法盔甲、MP偷取(被)、传送、火焰之箭、冥想
  - 弓手：箭刃、双重射击、专注、致命射击(被)、弓术精通(被)、爆裂箭、灵魂之箭、致命攻击-弓(被)
- **战斗反馈**：DamageNumber 飘字 + hit-stop（每招独立 30~90ms）+ 击退（每招独立 140~360px）+ combo → HUD toast
- **Buff 系统**：HUD buff_row 实时显示；damage_mul / defense_add / speed_mul / regen_per_sec；丰收节自动给 harvest_blessing
- **死亡惩罚**：复活到最近的床，非装备物品掉一半在原地，所有人可捡

## 六、交易 / 经济

- **贸易站**激活后商人周期来访（行商 180s / 矿商 240s）
- **货币 G**：商人收购农产品，HUD 显示余额（雪人节售价 +20%）
- **稀有产出**：`rare_seed` / `blueprint` / `meteorite_ore`
- **神秘旅人**：稀有事件直接 spawn，无需贸易站；可用陨石矿换图纸 / 装扮 / 幸运护符

## 六、成就 / 图鉴

- **10 个成就**：砍树 / 采矿 / 击杀 / 收获 / 卖钱 / 存活
- **触发 + 累积**：监听 EventBus 各信号；进度持久化到 `user://achievements.json`（独立于存档槽）
- **解锁奖励**：直接发金币 + HUD toast 🏆 通知
- **图鉴 UI**：HUD 右上 📖 按钮打开（DraggablePanel）

## 七、操作

| 键 | 动作 |
|---|---|
| WASD | 移动 |
| E | 交互（采集 / 播种 / 收获 / 交易 / 睡床 / 井 / 磨坊 / 烤炉 / 铁砧） |
| J + Q/E/R/G | basic + 4 主动技能 |
| F | 用选中物品（食物回血 / 鱼竿钓鱼） |
| 1–9 | hotbar 切槽 |
| Tab / C / B / K / ESC | 背包 / 合成 / 建造 / 技能树 / 暂停 |
| HUD 右上 📖 | 图鉴 / 成就 |

## 八、HUD

- **左上**：角色信息条（头像 + Lv + HP / MP / FP 三条全接通）
- **顶部**：buff 条 / 环境信息（时间 + 天气图标）/ 节日事件 banner
- **底部**：9 格 hotbar + 经验条 + 等级徽章
- **右上**：金币、菜单按钮（角色 / 📖 图鉴 / 地图 / 设置）+ 小地图 + 任务条
- **小地图**：玩家黄点 + 朝向三角 + 建筑 / 农田 / 怪物色点

## 九、系统底层

- **多人架构**：host-authoritative，单机即 1 人房间（同一份代码路径）
- **VFXEventRouter**：全局粒子反馈（升级 / 装备 / 收获 / 放置）
- **存档 v2**：`{world, players[]}`，主菜单 3 槽
- **音效 + BGM**：昼夜切歌，设置菜单（音量 / 全屏 / 持久化）
- **Autoload 全景**：EventBus / Network / NetworkRegistry / PlayerActions / GameManager / ItemDatabase / CraftingSystem / BuildingSystem / TimeSystem / **WeatherSystem** / TradeSystem / SaveSystem / UpdateSystem / WorldGenerator / ChunkManager / SkillSystem / UIStyle / SoundSystem / VFXLibrary / VFXEventRouter / **FestivalSystem** / **BuffSystem** / **AchievementSystem** / **RareEventSystem**

---

## 玩法定位提醒（避免脱节）

新增系统 / 内容前对一下：

1. **节奏一致** — 不要引入硬压力（饥饿、断电、强制时间到死）。
2. **战斗权重已经不低** — 别再单方面加战斗复杂度，除非配套给玩家新工具。
3. **数据驱动优先** — 新物品 / 怪物 / 作物 / 建筑只加 JSON，不改系统代码。
4. **多人友好** — 新行为默认 server-authoritative；客户端只做表现层。
5. **可接自动化** — 新建筑 / 生物 / 作物默认评估能否作为 F 路线的输入源 / 输出 / 处理器。

**下一步 F 路线（自动化）会是大转折**：从「亲手种 / 亲手打 / 亲手做」延展到「看着工厂运转的爽感」。开 F 前需先决策：自动化是**替代手动**（农场全自动 = 玩家不种了），还是**补充**（手动更快但量小，自动慢但能堆量）—— 直接决定后续 100 小时怎么玩。
