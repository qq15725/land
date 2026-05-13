extends Node

# VFX 中心库。所有战斗 / 命中 / 拾取等视觉效果统一从这里 spawn，
# 避免散落在 SkillExecutor / Fireball / Player 各处重复实现。
#
# 调用约定：
#   VFXLibrary.spawn(vfx_id, parent, pos, rotation=0, color=WHITE, scale=Vector2.ONE)
#
# vfx_id 直接对应 scenes/vfx/{vfx_id}.tscn。
# 场景的根节点需实现 setup(color: Color, scale: Vector2) -> void（可选）。
#
# 文件不存在则静默忽略，避免缺资源时崩溃。

var _cache: Dictionary = {}  # vfx_id → PackedScene

func spawn(vfx_id: String, parent: Node, pos: Vector2, rotation_rad: float = 0.0, color: Color = Color.WHITE, scale: Vector2 = Vector2.ONE) -> Node2D:
	if vfx_id.is_empty() or parent == null:
		return null
	var scene := _resolve(vfx_id)
	if scene == null:
		return null
	var inst := scene.instantiate() as Node2D
	if inst == null:
		return null
	parent.add_child(inst)
	inst.global_position = pos
	inst.rotation = rotation_rad
	inst.scale = scale
	if inst.has_method("setup"):
		inst.setup(color, scale)
	return inst

func preload_all() -> void:
	# 预热常用 VFX。可在主菜单 → 进入世界过场时调用。
	for id in ["melee_fan", "aoe_circle", "melee_rect", "hit_spark", "projectile_trail"]:
		_resolve(id)

func _resolve(id: String) -> PackedScene:
	if _cache.has(id):
		return _cache[id]
	var path := AssetPaths.vfx_scene(id)
	if not ResourceLoader.exists(path):
		_cache[id] = null
		return null
	var ps := load(path) as PackedScene
	_cache[id] = ps
	return ps
