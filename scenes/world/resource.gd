class_name ResourceNode
extends StaticBody2D

signal depleted
signal respawned

var resource_id: String = ""
var item: ItemData
var drop_amount: int = 3
var respawn_time: float = 30.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Visual
@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

var depleted_flag := false

func _ready() -> void:
	if not resource_id.is_empty():
		var data: ResourceNodeData = ItemDatabase.get_resource_node(resource_id)
		if data:
			item = data.drop_item
			drop_amount = data.drop_amount
			respawn_time = data.respawn_time
			_apply_data(data)
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _apply_data(data: ResourceNodeData) -> void:
	var rect := RectangleShape2D.new()
	rect.size = data.collision_size
	_collision.shape = rect
	_collision.position.y = data.collision_offset_y

	var tex: Texture2D
	var sprite_path := "res://assets/resources/%s.png" % resource_id
	if ResourceLoader.exists(sprite_path):
		tex = load(sprite_path) as Texture2D
	if tex == null:
		tex = _make_fallback_texture(data)

	visual.texture = tex
	visual.position.y = data.visual_offset_y
	visual.region_enabled = true
	visual.region_rect = Rect2(0, 0, tex.get_width(), data.frame_height)

func _make_fallback_texture(data: ResourceNodeData) -> ImageTexture:
	var w := 128
	var h := data.frame_height
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hue := absf(float(resource_id.hash() % 1000) / 1000.0)
	img.fill(Color.from_hsv(hue, 0.5, 0.7))
	var edge := Color.from_hsv(hue, 0.8, 0.3)
	for px in w:
		img.set_pixel(px, 0, edge)
		img.set_pixel(px, h - 1, edge)
	for py in h:
		img.set_pixel(0, py, edge)
		img.set_pixel(w - 1, py, edge)
	return ImageTexture.create_from_image(img)

func interact(player: Player) -> void:
	if depleted_flag or item == null:
		return
	var leftover := player.inventory.add_item(item, drop_amount)
	if leftover > 0:
		_spawn_drops(leftover)
	HitParticles.spawn(get_parent(), global_position, item.color)
	_deplete()

func _deplete() -> void:
	depleted_flag = true
	hint_label.hide()
	modulate = Color(0.5, 0.5, 0.5)
	depleted.emit()
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	depleted_flag = false
	modulate = Color.WHITE
	respawned.emit()

func is_depleted() -> bool:
	return depleted_flag

func get_regen_timer() -> float:
	return 0.0

func restore_from_save(elapsed: float) -> void:
	depleted_flag = true
	modulate = Color(0.5, 0.5, 0.5)
	var remaining := maxf(respawn_time - elapsed, 0.1)
	get_tree().create_timer(remaining).timeout.connect(_respawn)

func _spawn_drops(amount: int) -> void:
	var drop: DropItem = DropItemScene.instantiate()
	drop.position = global_position + Vector2(randf_range(-20.0, 20.0), -10.0)
	get_parent().add_child(drop)
	drop.setup(item, amount)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not depleted_flag:
		hint_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		hint_label.hide()
