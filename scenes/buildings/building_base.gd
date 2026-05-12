class_name BuildingBase
extends StaticBody2D

@export var max_durability: float = 100.0

var building_data: BuildingData = null
var hint_label: Label = null
var interact_area: Area2D = null
var visual: Sprite2D = null
var durability: float

func _ready() -> void:
	NetworkRegistry.attach(self)
	durability = max_durability
	hint_label = get_node_or_null("HintLabel") as Label
	interact_area = get_node_or_null("InteractArea") as Area2D
	visual = get_node_or_null("Visual") as Sprite2D
	if hint_label:
		hint_label.hide()
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

# 仅设置视觉，不触发任何副作用（用于建造预览）。
func setup_preview(data: BuildingData) -> void:
	building_data = data
	_apply_visual()

# 放置/读档时调用。基类只负责 sprite，子类覆盖以添加副作用（生鸡、注册到系统等）。
func on_placed(data: BuildingData = null) -> void:
	setup_preview(data)

func _apply_visual() -> void:
	if building_data == null or building_data.custom_render:
		return
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "Visual"
		visual.scale = Vector2(0.25, 0.25)
		visual.position = Vector2(0, -20)
		add_child(visual)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if visual.texture == null and not building_data.sprite_path.is_empty() and ResourceLoader.exists(building_data.sprite_path):
		visual.texture = load(building_data.sprite_path)
	if visual.texture == null:
		visual.texture = _make_placeholder_texture()

func _make_placeholder_texture() -> ImageTexture:
	var w := 192
	var h := 192
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var seed_str: String = building_data.id if building_data else "fallback"
	var hue := absf(float(seed_str.hash() % 1000) / 1000.0)
	img.fill(Color.from_hsv(hue, 0.45, 0.65))
	var edge := Color.from_hsv(hue, 0.7, 0.35)
	for x in w:
		img.set_pixel(x, 0, edge)
		img.set_pixel(x, h - 1, edge)
	for y in h:
		img.set_pixel(0, y, edge)
		img.set_pixel(w - 1, y, edge)
	return ImageTexture.create_from_image(img)

func interact(_player: Player) -> void:
	pass

func take_damage(amount: float) -> void:
	durability = maxf(0.0, durability - amount)
	if durability == 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and hint_label:
		hint_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player and hint_label:
		hint_label.hide()
