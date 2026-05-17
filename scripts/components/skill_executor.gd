class_name SkillExecutor
extends Node

# 通用战斗执行器。所有战斗动作都走这里，包括基础挥砍。
# 数据驱动：新增技能只改 active_skills.json，无需改这里的代码。
#
# 流程：cast(skill, target_pos, caster)
#   1. 计算施法方向 dir = (target_pos - caster) 归一化
#   2. 生成 VFX（按 shape 用 Polygon2D 几何，或加载 vfx_scene）
#   3. 按 shape 派发：fan / circle / rect → 走多段 tick + 即时形状查询命中
#                    projectile → 实例化 projectile_scene
#   4. 每段命中：扣血 + 击退 + 飘字 + 手感反馈（屏震 + hit-stop）

const QUERY_MASK := 4  # layer 3 = creature
# 冒险岛风格暴击：10% 概率，伤害 ×1.5（后续可由装备 / buff 改写）
const CRIT_CHANCE := 0.10
const CRIT_MULT := 1.5

var _in_hit_stop: bool = false

func cast(skill: ActiveSkillData, target_pos: Vector2, caster: Player) -> void:
	if skill == null or caster == null:
		return
	var dir := target_pos - caster.global_position
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	match skill.shape:
		"fan":        _exec_melee(skill, dir, caster, _hits_in_fan)
		"circle":     _exec_melee(skill, dir, caster, _hits_in_circle)
		"rect":       _exec_melee(skill, dir, caster, _hits_in_rect)
		"projectile": _exec_projectile(skill, dir, caster)
		"passive":    pass  # 被动技能：仅占技能树位置，不可释放（PlayerActions 应拦截装备）
		"buff":       _exec_self_buff(skill, caster)
		_:            push_warning("未知 skill shape: %s" % skill.shape)

# 自身 buff 技能：mp_cost + 给自己挂 buff_id 一段时间
func _exec_self_buff(skill: ActiveSkillData, caster: Player) -> void:
	if caster == null:
		return
	if not skill.vfx_id.is_empty():
		VFXLibrary.spawn(skill.vfx_id, caster.get_parent(), caster.global_position, 0.0, skill.vfx_color)
	if caster.buffs and not skill.buff_id.is_empty():
		caster.buffs.add_buff(skill.buff_id)

# ─── 近战公共流程（多段 tick） ─────────────────────────────────────────

func _exec_melee(skill: ActiveSkillData, dir: Vector2, caster: Player, hits_fn: Callable) -> void:
	_spawn_release_vfx(skill, dir, caster)
	var n: int = mini(skill.hit_ticks.size(), skill.hit_damage_ratios.size())
	var prev_t := 0.0
	for i in n:
		var t := float(skill.hit_ticks[i])
		var dt := maxf(0.0, t - prev_t)
		prev_t = t
		if dt > 0.0:
			await get_tree().create_timer(dt).timeout
		if not is_instance_valid(caster) or caster.health.current_health <= 0.0:
			return
		var ratio := float(skill.hit_damage_ratios[i])
		var buff_mul: float = caster.buffs.damage_mul() if caster.buffs else 1.0
		var base_dmg: float = (skill.base_damage + caster.inventory.total_damage_bonus()) * ratio * buff_mul
		var targets: Array = hits_fn.call(skill, dir, caster)
		var hit_any := false
		var any_crit := false
		for body in targets:
			if body is Creature:
				var c := body as Creature
				# 独立判定暴击：每个目标一次 roll
				var is_crit := randf() < CRIT_CHANCE
				var dmg: float = base_dmg * (CRIT_MULT if is_crit else 1.0)
				c.take_damage_from(caster, dmg)
				var kb_dir: Vector2 = (c.global_position - caster.global_position)
				if kb_dir.length() > 0.01:
					kb_dir = kb_dir.normalized()
				else:
					kb_dir = dir
				c.velocity += kb_dir * skill.knockback * (1.4 if is_crit else 1.0)
				DamageNumber.spawn(caster.get_parent(), c.global_position + Vector2(0, -16), dmg, is_crit, Color(0, 0, 0, 0))
				VFXLibrary.spawn("hit_spark", caster.get_parent(), c.global_position + Vector2(0, -12), 0.0, skill.vfx_color)
				ComboSystem.register_hit()
				hit_any = true
				any_crit = any_crit or is_crit
		if hit_any:
			_apply_feedback(skill, caster, any_crit)

# ─── 形状命中检测（PhysicsShapeQuery，实时） ────────────────────────────

func _hits_in_circle(skill: ActiveSkillData, _dir: Vector2, caster: Player) -> Array:
	return _query_shape(_make_circle(skill.shape_size), Transform2D(0.0, caster.global_position), caster)

func _hits_in_fan(skill: ActiveSkillData, dir: Vector2, caster: Player) -> Array:
	var bodies := _query_shape(_make_circle(skill.shape_size), Transform2D(0.0, caster.global_position), caster)
	var result: Array = []
	var half_angle := deg_to_rad(skill.shape_angle * 0.5)
	var ref_angle := dir.angle()
	for b in bodies:
		if not (b is Node2D):
			continue
		var to := (b as Node2D).global_position - caster.global_position
		if to.length() < 0.01:
			result.append(b)
			continue
		var diff := wrapf(to.angle() - ref_angle, -PI, PI)
		if absf(diff) <= half_angle:
			result.append(b)
	return result

func _hits_in_rect(skill: ActiveSkillData, dir: Vector2, caster: Player) -> Array:
	var shape := RectangleShape2D.new()
	# rect 模式：shape_size = 长度（朝向方向）；shape_angle 复用为宽度
	var width := maxf(skill.shape_angle, 16.0)
	shape.size = Vector2(skill.shape_size, width)
	var center := caster.global_position + dir * (skill.shape_size * 0.5)
	return _query_shape(shape, Transform2D(dir.angle(), center), caster)

func _query_shape(shape: Shape2D, transform: Transform2D, caster: Player) -> Array:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = transform
	query.collision_mask = QUERY_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var space := caster.get_world_2d().direct_space_state
	var hits := space.intersect_shape(query, 32)
	var out: Array = []
	for h in hits:
		var c: Object = h.get("collider")
		if c != null:
			out.append(c)
	return out

func _make_circle(r: float) -> CircleShape2D:
	var s := CircleShape2D.new()
	s.radius = r
	return s

# ─── 弹道 ──────────────────────────────────────────────────────────────

func _exec_projectile(skill: ActiveSkillData, dir: Vector2, caster: Player) -> void:
	if skill.projectile_scene.is_empty():
		return
	var scene := load(skill.projectile_scene) as PackedScene
	if scene == null:
		return
	var proj := scene.instantiate() as Node2D
	if proj == null:
		return
	caster.get_parent().add_child(proj)
	proj.global_position = caster.global_position + Vector2(0, -16)
	if proj.has_method("setup"):
		var buff_mul: float = caster.buffs.damage_mul() if caster.buffs else 1.0
		proj.setup(dir, (skill.base_damage + caster.inventory.total_damage_bonus()) * buff_mul, skill.shape_size, caster)

# ─── 手感反馈 ──────────────────────────────────────────────────────────

func _apply_feedback(skill: ActiveSkillData, caster: Player, is_crit: bool = false) -> void:
	# 暴击放大反馈：屏震 ×1.6 / hit-stop ×2（冒险岛 50ms 普通 → 100ms 暴击）
	var shake_mul := 1.6 if is_crit else 1.0
	var stop_mul := 2.0 if is_crit else 1.0
	if skill.screen_shake > 0.0 and caster.has_method("_camera_shake"):
		caster._camera_shake(skill.screen_shake * shake_mul)
	if caster.has_method("on_skill_hit_landed"):
		caster.on_skill_hit_landed(skill)
	if skill.hit_stop_ms > 0:
		_hit_stop(int(skill.hit_stop_ms * stop_mul))

func _hit_stop(ms: int) -> void:
	if _in_hit_stop:
		return
	_in_hit_stop = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(ms / 1000.0, true, false, true).timeout
	Engine.time_scale = 1.0
	_in_hit_stop = false

# ─── 释放 VFX（统一走 VFXLibrary） ─────────────────────────────────────

func _spawn_release_vfx(skill: ActiveSkillData, dir: Vector2, caster: Player) -> void:
	if skill.vfx_id.is_empty():
		return
	var rot := 0.0 if skill.shape == "circle" else dir.angle()
	VFXLibrary.spawn(skill.vfx_id, caster.get_parent(), caster.global_position, rot, skill.vfx_color)
