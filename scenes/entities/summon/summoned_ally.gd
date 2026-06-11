class_name SummonedAlly
extends CharacterBody2D

# 召唤协战单位（summon 技能生成）。自包含：占位菱形视觉 + 索敌 AI + 限时存活。
# 攻击归属记给召唤者（take_damage_from(owner)），击杀经验 / 掉落正确归玩家。
# collision_layer/mask = 0：不被玩家 AOE 误伤，也不阻挡任何东西。

const SPEED := 95.0
const ATTACK_RANGE := 30.0
const ATTACK_CD := 1.0
const DAMAGE := 14.0
const SEEK_RADIUS := 240.0
const FOLLOW_DIST := 72.0
const QUERY_MASK := 4  # layer 3 = creature

var _owner_player: Player
var _life := 30.0
var _atk_timer := 0.0
var _color := Color(0.6, 0.8, 1.0, 0.85)
var _body_poly: Polygon2D

func setup(owner: Player, color: Color, duration: float) -> void:
	_owner_player = owner
	_life = duration
	_color = color
	if _body_poly:
		_body_poly.color = color

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	var shadow := Polygon2D.new()
	var spts := PackedVector2Array()
	for k in 16:
		var a := float(k) / 16 * TAU
		spts.append(Vector2(cos(a) * 7.0, sin(a) * 3.0))
	shadow.polygon = spts
	shadow.color = Color(0, 0, 0, 0.4)
	shadow.position = Vector2(0, -2)
	shadow.z_index = -1
	add_child(shadow)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([Vector2(0, -20), Vector2(8, -10), Vector2(0, 0), Vector2(-8, -10)])
	_body_poly.color = _color
	add_child(_body_poly)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -14), Vector2(3, -11), Vector2(0, -8), Vector2(-3, -11)])
	core.color = Color(1, 1, 1, 0.85)
	add_child(core)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_expire()
		return
	if _life < 2.0 and _body_poly:  # 临消失闪烁提示
		_body_poly.visible = int(_life * 8) % 2 == 0
	_atk_timer = maxf(0.0, _atk_timer - delta)
	var target := _nearest_enemy()
	if target != null:
		var d := global_position.distance_to(target.global_position)
		if d > ATTACK_RANGE:
			velocity = global_position.direction_to(target.global_position) * SPEED
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			if _atk_timer <= 0.0 and is_instance_valid(_owner_player):
				target.take_damage_from(_owner_player, DAMAGE)
				VFXLibrary.spawn("hit_spark", get_parent(), target.global_position + Vector2(0, -12), 0.0, _color)
				_atk_timer = ATTACK_CD
	elif is_instance_valid(_owner_player):
		if global_position.distance_to(_owner_player.global_position) > FOLLOW_DIST:
			velocity = global_position.direction_to(_owner_player.global_position) * SPEED
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	else:
		_expire()

func _nearest_enemy() -> Creature:
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = SEEK_RADIUS
	q.shape = c
	q.transform = Transform2D(0.0, global_position)
	q.collision_mask = QUERY_MASK
	q.collide_with_bodies = true
	var hits := get_world_2d().direct_space_state.intersect_shape(q, 24)
	var best: Creature = null
	var best_d := INF
	for h in hits:
		var col: Object = h.get("collider")
		if col is Creature and is_instance_valid(col) and not (col as Node).is_queued_for_deletion():
			var d := global_position.distance_to((col as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = col as Creature
	return best

func _expire() -> void:
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
