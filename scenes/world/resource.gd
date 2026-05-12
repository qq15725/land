class_name ResourceNode
extends StaticBody2D

signal depleted
signal respawned

const HIT_FLASH_TIME := 0.08
const BREAK_FADE_TIME := 0.25

var resource_id: String = ""
var item: ItemData
var drop_amount: int = 3
var respawn_time: float = 30.0
var tool_required: String = ""

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Visual
@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

var depleted_flag := false
var _frame_height: int = 0
var _frame_count: int = 1  # sprite 是否真的有 3 帧

func _ready() -> void:
	if not resource_id.is_empty():
		var data: ResourceNodeData = ItemDatabase.get_resource_node(resource_id)
		if data:
			item = data.drop_item
			drop_amount = data.drop_amount
			respawn_time = data.respawn_time
			tool_required = data.tool_required
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
	_frame_height = data.frame_height
	_frame_count = maxi(1, tex.get_height() / maxi(_frame_height, 1))
	_show_frame(0)

func _show_frame(idx: int) -> void:
	var clamped := clampi(idx, 0, _frame_count - 1)
	visual.region_rect = Rect2(0, clamped * _frame_height, visual.texture.get_width(), _frame_height)

# 单帧占位时用 modulate 模拟「受击/破坏」状态。
func _flash_hit() -> void:
	if _frame_count >= 2:
		_show_frame(1)
		await get_tree().create_timer(HIT_FLASH_TIME).timeout
		if depleted_flag or not is_inside_tree():
			return
		_show_frame(0)
	else:
		visual.modulate = Color(1.6, 1.6, 1.6)
		await get_tree().create_timer(HIT_FLASH_TIME).timeout
		if is_inside_tree():
			visual.modulate = Color.WHITE

func _make_fallback_texture(data: ResourceNodeData) -> ImageTexture:
	# 占位时输出 3 帧（正常 / 受击 / 破坏），整体高度 = frame_height * 3。
	var w := 128
	var fh := data.frame_height
	var img := Image.create(w, fh * 3, false, Image.FORMAT_RGBA8)
	var hue := absf(float(resource_id.hash() % 1000) / 1000.0)
	var base := Color.from_hsv(hue, 0.5, 0.7)
	var bright := Color.from_hsv(hue, 0.3, 0.95)
	var dark := Color.from_hsv(hue, 0.55, 0.4)
	var edge := Color.from_hsv(hue, 0.8, 0.3)
	# 帧 0：正常
	img.fill_rect(Rect2i(0, 0, w, fh), base)
	# 帧 1：受击（整体偏亮）
	img.fill_rect(Rect2i(0, fh, w, fh), bright)
	# 帧 2：破坏（整体偏暗 + 裂纹）
	img.fill_rect(Rect2i(0, fh * 2, w, fh), dark)
	for x in w:
		img.set_pixel(x, fh * 2 + fh / 2, edge)
	# 三帧统一加边
	for f in 3:
		var y0 := f * fh
		for x in w:
			img.set_pixel(x, y0, edge)
			img.set_pixel(x, y0 + fh - 1, edge)
		for y in fh:
			img.set_pixel(0, y0 + y, edge)
			img.set_pixel(w - 1, y0 + y, edge)
	return ImageTexture.create_from_image(img)

func interact(player: Player) -> void:
	if depleted_flag or item == null:
		return
	if not tool_required.is_empty():
		var held := player.inventory.get_selected_item()
		if held == null or held.tool_type != tool_required:
			hint_label.text = "需要 %s" % _tool_label(tool_required)
			return
	# 等级额外掉落概率（按资源对应技能）
	var bonus := 0
	var skill_id: String = SkillSystem.RESOURCE_TO_SKILL.get(resource_id, "")
	if not skill_id.is_empty() and randf() < SkillSystem.bonus_drop_chance(skill_id):
		bonus = 1
	var leftover := player.inventory.add_item(item, drop_amount + bonus)
	if leftover > 0:
		_spawn_drops(leftover)
	HitParticles.spawn(get_parent(), global_position, item.color)
	_play_break_and_deplete()

func _tool_label(tool: String) -> String:
	match tool:
		"axe": return "斧子"
		"pickaxe": return "镐子"
		_: return tool

func _play_break_and_deplete() -> void:
	depleted_flag = true
	hint_label.hide()
	depleted.emit()

	await _flash_hit()
	if not is_inside_tree():
		return
	if _frame_count >= 3:
		_show_frame(2)
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, BREAK_FADE_TIME)
	tween.tween_callback(_on_break_fade_done)

func _on_break_fade_done() -> void:
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	depleted_flag = false
	visual.modulate = Color.WHITE
	_show_frame(0)
	respawned.emit()

func is_depleted() -> bool:
	return depleted_flag

func get_regen_timer() -> float:
	return 0.0

func restore_from_save(elapsed: float) -> void:
	depleted_flag = true
	visual.modulate = Color(1, 1, 1, 0)
	if _frame_count >= 3:
		_show_frame(2)
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
