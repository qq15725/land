class_name ProjectedShadow
extends Node2D

# 方向性投影阴影：复制实体 visual 的当前帧，以脚部为锚翻折压扁到地面，
# 由 TimeSystem 太阳方位驱动 skew（早晚左右长倒、正午短居中）。
# 取代旧的静态椭圆 blob，所有会动的实体（player/creature/animal/merchant/summon）共用。
#
# 数学：影子 sprite offset.y = -h/2 把纹理底边(脚)移到节点原点 →
#       scale.y 取负绕脚翻折到屏幕下方 → skew 水平斜切模拟光源方位。

const MAX_SKEW := 0.55          # 早晚最大斜切（弧度，约 31°）
const LEN_SHORT := 0.42         # 正午影子长度系数（太阳最高）
const LEN_LONG := 0.95          # 日出/日落影子长度系数（太阳最低）
const DAY_ALPHA := 0.42
const NIGHT_ALPHA := 0.16       # 夜晚仅月光，淡而长
const NIGHT_SKEW := -0.3
const FOLLOW_FRAME := true      # 是否每帧跟随源动画帧（角色用 true，静态物件可关）
const SOFT_SHADOW_SHADER := preload("res://scenes/effects/soft_shadow.gdshader")

var _src: CanvasItem            # 源 visual（AnimatedSprite2D 或 Sprite2D）
var _spr: Sprite2D
var _last_anim := ""
var _last_frame := -1


# 便捷接入：创建影子节点挂到实体子节点最前（z 在 visual 之下），返回实例。
static func attach_to(entity: Node, src_visual: CanvasItem, follow_frame: bool = true) -> ProjectedShadow:
	var s := ProjectedShadow.new()
	s.name = "Shadow"
	entity.add_child(s)
	entity.move_child(s, 0)
	s.setup(src_visual, follow_frame)
	return s


func setup(src_visual: CanvasItem, follow_frame: bool = true) -> void:
	_src = src_visual
	_spr = Sprite2D.new()
	_spr.centered = true
	_spr.z_index = 0
	# linear filter 让缩放后边缘平滑；soft shadow shader 做 alpha 羽化
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = SOFT_SHADOW_SHADER
	_spr.material = mat
	add_child(_spr)
	z_index = ZLayer.SHADOW
	set_meta("follow_frame", follow_frame)
	_refresh_frame(true)
	_update_projection()


func _process(_delta: float) -> void:
	if not is_instance_valid(_src):
		return
	if get_meta("follow_frame", true):
		_refresh_frame(false)
	_update_projection()


# 同步源纹理 + 翻转；force=true 时无条件刷新（初始化）。
func _refresh_frame(force: bool) -> void:
	if _src is AnimatedSprite2D:
		var anim: AnimatedSprite2D = _src
		if force or anim.animation != _last_anim or anim.frame != _last_frame:
			_last_anim = anim.animation
			_last_frame = anim.frame
			var sf := anim.sprite_frames
			if sf and sf.has_animation(anim.animation):
				_spr.texture = sf.get_frame_texture(anim.animation, anim.frame)
		_spr.flip_h = anim.flip_h
	elif _src is Sprite2D:
		var s: Sprite2D = _src
		if force or _spr.texture != s.texture:
			_spr.texture = s.texture
		_spr.flip_h = s.flip_h


func _update_projection() -> void:
	if _spr.texture == null:
		return
	# 脚部锚点：把纹理底边移到节点原点（offset 为缩放前的局部坐标）
	_spr.offset = Vector2(0, -_spr.texture.get_height() * 0.5)

	var src_scale: Vector2 = _src.scale if _src is Node2D else Vector2.ONE
	var skew_amt: float
	var length: float
	var alpha: float
	if TimeSystem.is_night():
		skew_amt = NIGHT_SKEW
		length = LEN_LONG
		alpha = NIGHT_ALPHA
	else:
		# r: 0=日出(太阳东) → 0.5=正午 → 1=日落(太阳西)
		var r := TimeSystem.get_phase_ratio()
		var sun := (r - 0.5) * 2.0           # -1 → 0 → +1
		skew_amt = sun * MAX_SKEW             # 影子朝光源反方向倾倒
		length = lerpf(LEN_SHORT, LEN_LONG, absf(sun))
		alpha = DAY_ALPHA

	# scale.y 取负 → 绕脚部翻折到屏幕下方；length 控制拉伸
	_spr.scale = Vector2(src_scale.x, -src_scale.y * length)
	_spr.skew = skew_amt
	_spr.modulate = Color(0, 0, 0, alpha)
