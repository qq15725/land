# 美术提示词

## 整体风格基调

Minecraft 风格像素方块世界：所有物体由方块/像素格组成，硬边缘无平滑曲线，角色和物件都是方形/矩形拼接的块状造型。配色明亮，每个方块面用 2-3 个色阶平涂，风格简洁有力。避免圆角、渐变、柔和轮廓。

### 通用约束（追加到每条提示词末尾）

```
Minecraft-style pixel art, transparent background, hard square pixel edges,
flat block faces with 2-3 tone shading, no smooth curves, no rounded shapes,
no anti-aliasing, no gradients, no realistic rendering, no 3D render,
no background scene, no text, no watermark, no logo,
no extra objects, no cropped sprite, no inconsistent frame sizes
```

---

## 精灵表格式约定

所有尺寸为**源文件尺寸**（4 倍高清），最终游戏内会按 1/4 比例显示。

| 类型 | 单帧源尺寸 | 精灵表布局 | 动画说明 |
|------|-----------|-----------|----------|
| 角色 / 怪物 | 128×256 px | 4 列 × 4 行（512×1024 px） | 每行一个方向：下/上/左/右，每行 4 帧 |
| 可破坏环境物件 | 视物件而定 | 1 列 × 3 行 | 行 0 正常，行 1 受损，行 2 枯竭 |
| 静态环境物件 | 视物件而定 | 单帧静态 | 无动画 |
| 建筑 | 192×192 / 256×256 等 | 单帧静态 | 无动画 |
| 物品图标 | 32×32 / 64×64 px | grid 排列 | 无动画 |

**文件命名规范**：

```
assets/sprites/characters/{id}.png     # 角色 / NPC
assets/animals/{id}.png                # 圈养动物
assets/creatures/{id}.png              # 敌对怪物
assets/resources/{id}.png              # 可采集环境物件
assets/sprites/environment/{id}.png    # 装饰物件 / 地砖
assets/sprites/buildings/{id}.png      # 建筑
assets/sprites/items/icons.png         # 物品图标整张表
```

---

## 分类文档

| 类型 | 文档 | 说明 |
|------|------|------|
| 角色与生物 | [characters.md](characters.md) | 玩家、NPC、怪物、动物帧动画精灵表 |
| 地砖 Autotile | [tiles.md](tiles.md) | 掩码系统，变体列，生成提示词 |
| 环境物件 | [environment.md](environment.md) | 树、石、草丛、蘑菇等可采集/装饰物件 |
| 建筑 | [buildings.md](buildings.md) | 工作台、箱子、贸易站等可建造建筑 |
| 物品图标 | [items.md](items.md) | 背包 UI 图标表（8×5 grid） |
| 游戏内 UI | [ui.md](ui.md) | 面板背景、按钮、9-patch、血量条等通用 UI 元素 |
| HUD 布局 | [hud.md](hud.md) | 游戏内 HUD 各区域部件规格（角色信息 / 快捷栏 / 小地图 / 状态栏 / 移动端控制） |
| 主菜单美术 | [main_menu.md](main_menu.md) | 背景、标题 Logo、存档槽、菜单按钮 |

## 字体

可选项：在 `assets/fonts/pixel.ttf` 放置像素字体（如 Press Start 2P / Pixeled / Determination Mono Web，中文像素字体如 Zpix）。
