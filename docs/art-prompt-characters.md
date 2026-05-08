# 美术提示词 · 角色与生物

推荐工具：Leonardo.AI（Pixel Art 模型）或 Scenario.gg

## 目标尺寸

每个角色 32×64 px，pivot 在底边中心，透明背景，PNG 导出。

## 提示词

```
pixel art sprite sheet, white background, 2.5D isometric view, 
Don't Starve art style, thick black outlines, muted earthy colors.

Characters arranged in a row, each 32x64 pixels with consistent style:
1. farmer player - simple peasant clothes, brown hair
2. traveling merchant - wide hat, long coat, bag
3. green slime - round blob with eyes
4. skeleton - simple bone humanoid
5. small white chicken

All facing front-left (2.5D angle), clear separation between sprites,
pixel art, game asset, transparent background
```

## 对应游戏实体

| 序号 | 图中角色 | 游戏文件 |
|------|----------|----------|
| 1 | 玩家 | `scenes/entities/player/` |
| 2 | 商人 NPC | `scenes/entities/merchant/` |
| 3 | 史莱姆 | `scenes/entities/creature/` |
| 4 | 骷髅 | `scenes/entities/creature/` |
| 5 | 鸡 | `scenes/farm/` |
