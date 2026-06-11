class_name SpriteFrameBuilder

# 统一构建 4 方向（下/上/左/右）行走动画的 SpriteFrames。
# 帧尺寸自动从贴图推导（width/cols, height/rows），所以任何源尺寸都自适应。
# row_order 指定「下/上/左/右」各自取贴图第几行——不同美术包行序不同，改这里即可。
static func build_4way(tex: Texture2D, fps: float = 6.0, cols: int = 4, rows: int = 4, row_order: Array = [0, 1, 2, 3]) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var fw := tex.get_width() / cols
	var fh := tex.get_height() / rows
	var names := ["walk_down", "walk_up", "walk_left", "walk_right"]
	for i in 4:
		var anim_name: String = names[i]
		var row: int = int(row_order[i]) if i < row_order.size() else i
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, true)
		for col in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	return frames
