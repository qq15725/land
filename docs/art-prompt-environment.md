# 美术提示词 · 环境物件

推荐工具：Leonardo.AI（Pixel Art 模型）或 Scenario.gg

## 目标尺寸

各物件尺寸见下表，透明背景，PNG 导出，pivot 在底边中心。

## 提示词

```
pixel art sprite sheet, white background, 2.5D top-down isometric view,
Don't Starve art style, thick black outlines.

Environment objects arranged in grid:
1. oak tree (32x48) - round dark green canopy, brown trunk
2. stone rock cluster (32x24) - grey rocks pile
3. grass tuft (16x16) - small green grass
4. berry bush (32x32) - bush with red berries
5. dead tree (24x48) - bare branches
6. mushroom (16x24) - red cap white stem

Top-down 45 degree angle, each object clearly separated,
transparent background, pixel art game assets
```

## 对应游戏实体

| 序号 | 物件 | 尺寸 | 游戏文件 |
|------|------|------|----------|
| 1 | 橡树 | 32×48 | `scenes/world/resource_nodes/tree_node.tscn` |
| 2 | 石堆 | 32×24 | `scenes/world/resource_nodes/stone_node.tscn` |
| 3 | 草丛 | 16×16 | 装饰，无交互 |
| 4 | 浆果丛 | 32×32 | 可采集资源节点 |
| 5 | 枯树 | 24×48 | 装饰 |
| 6 | 蘑菇 | 16×24 | 可采集资源节点 |
