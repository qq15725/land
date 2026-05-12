# 音效资源

`SoundSystem`（autoload）从 `data/sounds.json` 加载所有音效，并自动监听 `EventBus` 信号播放。
所有文件放在 `assets/audio/`，建议格式 `.wav`（无压缩，短促音效首选）或 `.ogg`。

## 当前事件 → 音效映射

| 事件来源 | 触发时机 | 音效 id | 路径 | 时长建议 | 风格描述 |
|----------|----------|---------|------|---------|---------|
| `EventBus.item_picked_up` | 玩家拾取掉落物 | `pickup` | `assets/audio/pickup.wav` | 80–150 ms | 轻快短促"叮"，星露谷拾取风 |
| `EventBus.resource_depleted` | 采集树/石/矿成功 | `collect` | `assets/audio/collect.wav` | 200–400 ms | 木/石碎裂感，1-2 层混合 |
| `EventBus.item_crafted` | 工作台/烹饪合成成功 | `craft` | `assets/audio/craft.wav` | 300–500 ms | 锤击 + 完成提示音 |
| `BuildingSystem.building_placed` | 建筑放置成功 | `place` | `assets/audio/place.wav` | 200–300 ms | 木板/石块落地"咚" |
| `EventBus.player_damaged` | 玩家受伤 | `hurt` | `assets/audio/hurt.wav` | 150–250 ms | 短促"喔" |
| `EventBus.player_died` | 玩家死亡 | `death` | `assets/audio/death.wav` | 600–1000 ms | 下行音阶 + 闷响 |
| `EventBus.item_used` | 玩家使用食物 | `use` | `assets/audio/use.wav` | 150–300 ms | 咀嚼/喝水声 |
| `EventBus.trade_completed` | 商人交易成功 | `trade` | `assets/audio/trade.wav` | 300–500 ms | 金币掉落 + 商人吆喝点缀 |
| （UI 按钮按下） | UI 点击 | `ui_click` | `assets/audio/ui_click.wav` | 50–80 ms | 短促"哒" |

## 调整音量

在 `data/sounds.json` 中调 `volume_db`：`0.0` 原始，`-6.0` 一半响度，`-12.0` 1/4 响度。

## 添加新音效

1. 把音频文件放入 `assets/audio/`
2. 在 `data/sounds.json` 加一行 `{"id": "xxx", "path": "...", "volume_db": -3.0}`
3. 在代码中 `SoundSystem.play("xxx")` 或新增 EventBus 信号 + 监听

## 占位策略

如果暂时没有真实音频文件，缺失文件不会报错（`SoundSystem._load_config` 用 `ResourceLoader.exists` 跳过），但播放时会静音。
