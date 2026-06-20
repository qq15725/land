class_name VisualEffects

# 受击闪白（冒险岛风格"打到了"反馈）。玩家与怪物共用。
const HitFlashShader := preload("res://scenes/effects/hit_flash.gdshader")
const HIT_FLASH_DURATION := 0.05

# 给 visual 挂上闪白材质（在 _ready 调一次）
static func setup_hit_flash(visual: CanvasItem) -> void:
	if visual == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = HitFlashShader
	visual.material = mat

# 触发一次闪白（需先 setup_hit_flash）
static func flash_hit(visual: CanvasItem, duration: float = HIT_FLASH_DURATION) -> void:
	if not is_instance_valid(visual):
		return
	var mat := visual.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_amount", 1.0)
	await visual.get_tree().create_timer(duration).timeout
	if is_instance_valid(visual):
		var m2 := visual.material as ShaderMaterial
		if m2:
			m2.set_shader_parameter("flash_amount", 0.0)

# 淡入：置 alpha=0 再 tween 到 1（资源重生 / 建筑放置等平滑出现）
static func fade_in(node: CanvasItem, dur: float = 0.3) -> void:
	if node == null:
		return
	var c := node.modulate
	node.modulate = Color(c.r, c.g, c.b, 0.0)
	node.create_tween().tween_property(node, "modulate:a", 1.0, dur)
