class_name Animal
extends CharacterBody2D

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")
const SPEED := 35.0

var data: AnimalData = null

@onready var visual: AnimatedSprite2D = $Visual
@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

var _pen_center: Vector2 = Vector2.ZERO
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _is_fed: bool = false
var _produce_timer: float = 0.0

func _ready() -> void:
	NetworkRegistry.attach(self)
	_pen_center = global_position
	_wander_target = global_position
	hint_label.hide()
	interact_area.body_entered.connect(func(b): if b is Player: hint_label.show())
	interact_area.body_exited.connect(func(b): if b is Player: hint_label.hide())
	if data:
		hint_label.text = "[E] 喂食"
		_setup_sprite_frames()


func _setup_sprite_frames() -> void:
	var tex := load(data.sprite_path) as Texture2D
	if tex == null:
		return
	visual.sprite_frames = ArtProfile.character_frames(tex, ArtProfile.ANIMAL_FPS)
	visual.scale = Vector2.ONE * ArtProfile.scale_for(tex, ArtProfile.ANIMAL_TARGET_H)
	visual.play("walk_down")

func _physics_process(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_target()

	var dir := _wander_target - global_position
	if dir.length() > 8.0:
		velocity = dir.normalized() * SPEED
		_update_animation(velocity)
	else:
		velocity = Vector2.ZERO
		if visual.is_playing():
			visual.stop()
			visual.frame = 0
	move_and_slide()

	if _is_fed:
		_produce_timer -= delta
		if _produce_timer <= 0.0:
			_spawn_produce()
			_is_fed = false
			if data:
				hint_label.text = "[E] 喂食"

func interact(player: Player) -> void:
	if not data:
		return
	if _is_fed:
		return
	if player.inventory.has_item(data.feed_item, 1):
		player.inventory.remove_item(data.feed_item, 1)
		_is_fed = true
		_produce_timer = data.produce_time
		hint_label.text = "已喂食..."
	else:
		hint_label.text = "需要：" + data.feed_item.display_name

# 自动化喂食（放入器调用）
func auto_feed(item: ItemData) -> bool:
	if _is_fed or data == null or item != data.feed_item:
		return false
	_is_fed = true
	_produce_timer = data.produce_time
	hint_label.text = "已喂食..."
	return true

func _pick_wander_target() -> void:
	var radius := data.wander_radius if data else 60.0
	var angle := randf() * TAU
	var dist := randf() * radius
	_wander_target = _pen_center + Vector2(cos(angle), sin(angle)) * dist
	_wander_timer = randf_range(2.0, 5.0)

func _update_animation(vel: Vector2) -> void:
	var anim: String
	if abs(vel.x) >= abs(vel.y):
		anim = "walk_right" if vel.x > 0 else "walk_left"
	else:
		anim = "walk_down" if vel.y > 0 else "walk_up"
	if not visual.is_playing() or visual.animation != anim:
		visual.play(anim)


func _spawn_produce() -> void:
	if not data or not data.produce_item:
		return
	var drop := DropItemScene.instantiate()
	drop.item = data.produce_item
	drop.amount = data.produce_amount
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))

# ─── 存档 ────────────────────────────────────────────────────────────────

func get_save_state() -> Dictionary:
	return {
		"is_fed": _is_fed,
		"produce_timer": _produce_timer,
	}

func load_save_state(state: Dictionary) -> void:
	_is_fed = bool(state.get("is_fed", false))
	_produce_timer = float(state.get("produce_timer", 0.0))
	if data and is_inside_tree():
		hint_label.text = "已喂食..." if _is_fed else "[E] 喂食"
