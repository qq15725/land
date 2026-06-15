extends Node2D

# 角色预览调试场景：显示 player.png 原图布局 + 4 方向动画，用于美术接入时自查。
# 用 run_project scene=res://scenes/debug/char_preview.tscn 单独运行。

func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.35, 0.55, 0.25)
	bg.z_index = -10
	add_child(bg)

	var tex := load("res://assets/sprites/characters/player.png") as Texture2D
	if tex == null:
		_label("player.png 加载失败", Vector2(40, 40))
		return

	# 原图整张放大（诊断 4 行×4 列布局）
	var raw := Sprite2D.new()
	raw.texture = tex
	raw.centered = false
	raw.position = Vector2(40, 60)
	raw.scale = Vector2(3, 3)
	raw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(raw)
	_label("原图 %dx%d" % [tex.get_width(), tex.get_height()], Vector2(40, 30))

	# 4 方向动画
	var sf := SpriteFrameBuilder.build_4way(tex, 4.0, 4, 4, [0, 1, 2, 3])
	var dirs := ["walk_down", "walk_up", "walk_left", "walk_right"]
	var x := 560
	for d in dirs:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = sf
		s.scale = Vector2(5, 5)
		s.position = Vector2(x, 280)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.play(d)
		add_child(s)
		_label(d, Vector2(x - 45, 440))
		x += 175

	# Godot 内部截图：只存游戏画面到文件，不碰系统屏幕
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/godot_preview.png")
	print("PREVIEW_SAVED /tmp/godot_preview.png")
	get_tree().quit()

func _label(t: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", 18)
	add_child(l)
