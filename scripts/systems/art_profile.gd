extends Node

# 美术规格中心（适配层）。切换美术包时改这里，各实体的帧切割 + scale 自动适应，
# 不需要动各 entity 代码或 tscn。
#
# 核心思想：世界显示尺寸恒定，scale = 目标显示高 / 源帧高（按贴图运行时自动算）。
# 换不同尺寸/布局的美术包（如 16×16 → 现在的 128×256），只改本文件的几个常量。

# ── 角色类精灵表布局（玩家/怪物/动物/NPC 共用）──
# 当前美术：4 列 × 4 行，行序 下/上/左/右。
# 换包后若布局不同（如某些包是 上/左/右/下），改 char_row_order 即可。
var char_cols: int = 4
var char_rows: int = 4
var char_row_order: Array = [0, 1, 2, 3]   # 下 上 左 右 各取贴图第几行

# ── 各类世界显示目标高度（像素=世界单位），保持现有观感 ──
# 玩家/怪物/商人当前 = 256 源帧高 × 0.125 = 32；动物 = 256 × 0.25 = 64
const CHARACTER_TARGET_H := 32.0
const CREATURE_TARGET_H := 32.0
const ANIMAL_TARGET_H := 64.0
const MERCHANT_TARGET_H := 32.0

# ── 各类动画帧率 ──
const PLAYER_FPS := 12.0
const CREATURE_FPS := 6.0
const ANIMAL_FPS := 6.0
const MERCHANT_FPS := 6.0

# ── 建筑/环境物件 scale（源 ÷ 4 = 世界单位，当前约定）──
# 建筑视觉缩到约 1 格（一个建筑占一个格子）
const BUILDING_SCALE := 0.1
const OBJECT_SCALE := 0.25

# 按贴图自动算 scale，使世界显示高度恒为 target_h（换包后源帧高变，显示不变）
func scale_for(tex: Texture2D, target_h: float) -> float:
	if tex == null:
		return 0.125
	var frame_h := float(tex.get_height()) / float(char_rows)
	if frame_h <= 0.0:
		return 0.125
	return target_h / frame_h

# 构建角色类 4 方向行走帧（统一走布局配置）
func character_frames(tex: Texture2D, fps: float) -> SpriteFrames:
	return SpriteFrameBuilder.build_4way(tex, fps, char_cols, char_rows, char_row_order)
