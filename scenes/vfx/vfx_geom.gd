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

@export_enum("fan", "circle", "rect", "spark", "trail") var shape: String = "circle"
@export var size_a: float = 40.0
@export var size_b: float = 90.0
@export var lifetime: float = 0.25
@export var base_color: Color = Color(1, 1, 1, 0.7)
@export var grow_scale: float = 1.12

var _poly: Polygon2D

func _ready() -> void:
	z_index = ZLayer.VFX_GROUND if shape != "spark" else ZLayer.VFX_HIT
	_build()
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

func _play() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, lifetime)
	var target_scale: Vector2 = scale * grow_scale
	tw.tween_property(self, "scale", target_scale, lifetime)
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
