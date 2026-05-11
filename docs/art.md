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

> 所有尺寸为**源文件尺寸**（4 倍高清），Godot 场景缩放参考下表。**Camera2D zoom = 4.0**，格子 = 64×64 屏幕像素，对齐星露谷物语比例。

| 类型 | 单帧源尺寸 | 场景 scale | 游戏世界渲染尺寸 | 屏幕像素（zoom×4） | 精灵表布局 | 动画说明 |
|------|-----------|-----------|----------------|------------------|-----------|----------|
| 角色 / 怪物 | 128×256 px | 0.125 | 16×32 px（1×2 格） | 64×128 px | 4列 × 4行 | 每行一个方向：下/上/左/右，每行4帧 |
| 可破坏环境物件 | 视物件而定 | 0.25 | 原尺寸 ÷ 4 | 原尺寸 | 1列 × 3行 | 行0正常，行1受损，行2枯竭 |
| 静态环境物件 | 视物件而定 | 0.25 | 原尺寸 ÷ 4 | 原尺寸 | 单帧静态 | 无动画 |
| 建筑 | 192×192 / 256×256 等 | 0.25 | 48×48 / 64×64 px | 192×192 / 256×256 px | 单帧静态 | 无动画 |
| 物品图标 | 64×64 px | — | 16×16 px（UI） | — | grid 排列 | 无动画 |

**文件命名规范**（与 JSON 中 `sprite` 字段对应）：
```
assets/sprites/characters/{id}.png     # 角色/怪物
assets/sprites/environment/{id}.png    # 环境物件
assets/sprites/buildings/{id}.png      # 建筑
assets/sprites/items/{id}.png          # 物品图标（整张图标表）
```

---

## 分类文档

| 类型 | 文档 | 说明 |
|------|------|------|
| 角色与生物 | [art/characters.md](art/characters.md) | 玩家、NPC、怪物帧动画精灵表 |
| 地砖 Autotile | [art/tiles.md](art/tiles.md) | ground_tiles.png，掩码系统，变体列，生成提示词 |
| 环境物件 | [art/environment.md](art/environment.md) | 树、石、草丛、蘑菇等可采集/装饰物件 |
| 建筑 | [art/buildings.md](art/buildings.md) | 工作台、箱子、贸易站等可建造建筑 |
| 物品图标 | [art/items.md](art/items.md) | 背包 UI 图标表 |
| 游戏内 UI | [art/ui.md](art/ui.md) | HUD、面板、按钮、血量条等游戏内界面 |
| 主菜单美术 | [art/main_menu.md](art/main_menu.md) | 背景、标题 Logo、存档槽、菜单按钮 |
