class_name VFXGeom
extends Node2D

# 通用几何 VFX。所有"代码画形状 + tween 淡出"的场景都共享此脚本，
# 不同 vfx 类型只在 .tscn 里改 shape / size_a / size_b / lifetime 参数。
#
# shape 含义：
#   fan    — size_a = 半径，size_b = 张角(deg)
#   circle — size_a = 半径
#   rect   — size_a = 长度，size_b = 宽度
#   spark  — size_a = 外圈半径（绘制为内圈实心 + 外圈空心闪光）
#   trail  — size_a = 半径（弹道拖尾用，简单小圆）
#
# 冒险岛风格增强（升级版）：
# - flash_intensity：0~1，>0 时 spawn 第一帧叠一个白色高亮 polygon（核心爆点）
# - emit_particles：true 时附加 CPUParticles2D 飞溅粒子
# - secondary_color：粒子末段颜色（默认 base_color × 0.4）

@export_enum("fan", "circle", "rect", "spark", "trail") var shape: String = "circle"
@export var size_a: float = 40.0
@export var size_b: float = 90.0
@export var lifetime: float = 0.25
@export var base_color: Color = Color(1, 1, 1, 0.7)
@export var grow_scale: float = 1.12

# ── 冒险岛风格增强参数 ──────────────────────────────────────────────────────
# 中心闪白核（0 关闭）。值越大越显眼（最高 1.0）
@export_range(0.0, 1.0) var flash_intensity: float = 0.0
# 飞溅粒子开关 + 配置
@export var emit_particles: bool = false
@export var particle_count: int = 18
@export var particle_speed_min: float = 60.0
@export var particle_speed_max: float = 140.0
@export var particle_spread_deg: float = 60.0
@export var particle_lifetime: float = 0.5
@export var particle_color_core: Color = Color(1, 1, 1, 1)
@export var particle_color_mid: Color = Color(1, 1, 1, 0.8)
@export var particle_color_end: Color = Color(1, 1, 1, 0)
@export var particle_scale: float = 4.0

var _poly: Polygon2D
var _flash: Polygon2D = null

func _ready() -> void:
	z_index = ZLayer.VFX_GROUND if shape != "spark" else ZLayer.VFX_HIT
	_build()
	if emit_particles:
		_build_particles()
	_play()

# VFXLibrary.spawn() 调用：覆盖颜色 / 缩放
func setup(color: Color, scale_v: Vector2) -> void:
	base_color = color
	scale = scale_v
	if _poly != null:
		_poly.color = base_color

func _build() -> void:
	_poly = Polygon2D.new()
	_poly.color = base_color
	add_child(_poly)
	var pts: PackedVector2Array
	match shape:
		"fan":    pts = _build_fan(size_a, size_b)
		"circle": pts = _build_circle(size_a)
		"rect":   pts = _build_rect(size_a, size_b)
		"spark":  pts = _build_circle(size_a * 0.45)
		"trail":  pts = _build_circle(size_a * 0.5)
		_:        pts = _build_circle(size_a)
	_poly.polygon = pts

	# 中心闪白核（冒险岛"击中瞬间发白"风）
	if flash_intensity > 0.0:
		_flash = Polygon2D.new()
		_flash.color = Color(1, 1, 1, flash_intensity)
		_flash.polygon = _build_circle(size_a * 0.35)
		add_child(_flash)

func _build_particles() -> void:
	var p := CPUParticles2D.new()
	p.amount = particle_count
	p.lifetime = particle_lifetime
	p.one_shot = true
	p.explosiveness = 0.85
	p.local_coords = false
	# 发射形状：按 shape 决定
	match shape:
		"fan":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			p.direction = Vector2(1, 0)
			p.spread = clampf(size_b * 0.5, 10.0, 180.0)
		"circle", "spark":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			p.direction = Vector2(0, -1)
			p.spread = 180.0  # 全向
		"rect":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			p.direction = Vector2(1, 0)
			p.spread = particle_spread_deg
		"trail":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			p.direction = Vector2(-1, 0)
			p.spread = 25.0
		_:
			p.direction = Vector2(0, -1)
			p.spread = 180.0
	p.initial_velocity_min = particle_speed_min
	p.initial_velocity_max = particle_speed_max
	p.gravity = Vector2(0, 60)
	# 颜色渐变
	var grad := Gradient.new()
	grad.set_color(0, particle_color_core)
	grad.add_point(0.4, particle_color_mid)
	grad.set_color(1, particle_color_end)
	p.color_ramp = grad
	# 大小渐变
	p.scale_amount_min = particle_scale * 0.6
	p.scale_amount_max = particle_scale
	var size_curve := Curve.new()
	size_curve.add_point(Vector2(0, 1.0))
	size_curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = size_curve
	add_child(p)

func _play() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, lifetime)
	var target_scale: Vector2 = scale * grow_scale
	tw.tween_property(self, "scale", target_scale, lifetime)
	# 闪白核单独快速淡出（前 0.06s 内消失）
	if _flash != null:
		tw.tween_property(_flash, "modulate:a", 0.0, minf(0.08, lifetime * 0.4))
	tw.chain().tween_callback(queue_free)

func _build_fan(r: float, angle_deg: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var half := deg_to_rad(angle_deg * 0.5)
	var segments := 16
	for i in segments + 1:
		var a := -half + (half * 2.0) * (float(i) / float(segments))
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _build_circle(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var segments := 24
	for i in segments:
		var a := float(i) / float(segments) * TAU
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _build_rect(length: float, width: float) -> PackedVector2Array:
	var hw := width * 0.5
	var pts := PackedVector2Array()
	pts.append(Vector2(0, -hw))
	pts.append(Vector2(length, -hw))
	pts.append(Vector2(length, hw))
	pts.append(Vector2(0, hw))
	return pts
