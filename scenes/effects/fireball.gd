class_name Fireball
extends Area2D

# 火球弹道。直线飞行，命中 Creature 造成伤害后消失。
# 撞墙/超出射程也消失。

const SPEED := 360.0

var _direction: Vector2 = Vector2.RIGHT
var _damage: float = 25.0
var _max_distance: float = 240.0
var _traveled: float = 0.0
var _owner_player: Player = null
var _consumed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 火球本体视觉：橙色实心圆，加暖色 modulate
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var r := 6.0
	for i in 16:
		var a := float(i) / 16 * TAU
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	poly.polygon = pts
	poly.color = Color(1.0, 0.55, 0.15, 1.0)
	add_child(poly)
	# 内层亮黄
	var core := Polygon2D.new()
	var pts2 := PackedVector2Array()
	for i in 16:
		var a := float(i) / 16 * TAU
		pts2.append(Vector2(cos(a) * 3.0, sin(a) * 3.0))
	core.polygon = pts2
	core.color = Color(1.0, 0.9, 0.5, 1.0)
	add_child(core)

# server 创建后调用：传入方向、伤害、射程、施法者。
func setup(direction: Vector2, damage: float, max_distance: float, caster: Player) -> void:
	_direction = direction.normalized()
	_damage = damage
	_max_distance = max_distance
	_owner_player = caster
	rotation = _direction.angle()

func _physics_process(delta: float) -> void:
	if _consumed:
		return
	var step := _direction * SPEED * delta
	position += step
	_traveled += step.length()
	if _traveled >= _max_distance:
		_explode(false)

func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	if body is Creature:
		var c := body as Creature
		c.take_damage_from(_owner_player, _damage)
		var kb := _direction * 200.0
		c.velocity += kb
		DamageNumber.spawn(get_parent(), c.global_position + Vector2(0, -16), _damage, false, Color(1.0, 0.7, 0.3))
		_explode(true)

func _explode(_hit: bool) -> void:
	_consumed = true
	# 命中火花 + HitParticles 暖色粒子，统一走 VFXLibrary 与既有粒子系统
	if get_parent() != null:
		VFXLibrary.spawn("hit_spark", get_parent(), global_position, 0.0, Color(1.0, 0.7, 0.3, 1.0))
		HitParticles.spawn(get_parent(), global_position, Color(1.0, 0.5, 0.1))
	queue_free()
