class_name SpriteFrameBuilder

# 统一构建 4 方向（下/上/左/右）行走动画的 SpriteFrames。
# 源贴图约定：4 列（帧）× 4 行（方向，顺序 下/上/左/右）。
# 玩家 / 怪物 / 动物 / 商人共用，差异仅在帧率。
static func build_4way(tex: Texture2D, fps: float = 6.0, cols: int = 4) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var fw := tex.get_width() / cols
	var fh := tex.get_height() / 4
	for entry in [["walk_down", 0], ["walk_up", 1], ["walk_left", 2], ["walk_right", 3]]:
		var anim_name: String = entry[0]
		var row: int = entry[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		for col in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	return frames
