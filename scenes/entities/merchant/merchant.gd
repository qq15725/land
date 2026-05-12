class_name Merchant
extends CharacterBody2D

signal departed

@onready var visual: AnimatedSprite2D = $Visual
@onready var interact_area: Area2D = $InteractArea
@onready var hint_label: Label = $HintLabel

var data: MerchantData
var _target_pos: Vector2 = Vector2.ZERO
var _arrived: bool = false
var _stay_timer: float = 0.0

func _ready() -> void:
	hint_label.hide()
	_setup_sprite_frames()
	interact_area.body_entered.connect(func(b): if b is Player: hint_label.show())
	interact_area.body_exited.connect(func(b): if b is Player: hint_label.hide())


func _setup_sprite_frames() -> void:
	var tex := load("res://assets/sprites/characters/merchant.png") as Texture2D
	if tex == null:
		return
	var fw := tex.get_width() / 4
	var fh := tex.get_height() / 4
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for entry in [["walk_down", 0], ["walk_up", 1], ["walk_left", 2], ["walk_right", 3]]:
		var anim_name: String = entry[0]
		var row: int = entry[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 6.0)
		frames.set_animation_loop(anim_name, true)
		for col in 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	visual.sprite_frames = frames
	visual.play("walk_down")

func setup(merchant_data: MerchantData, post_pos: Vector2) -> void:
	data = merchant_data
	_target_pos = post_pos
	var offset := Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0))
	_target_pos += offset
	global_position = post_pos + Vector2(randf_range(-200.0, 200.0), randf_range(80.0, 160.0))
	pass

func _physics_process(delta: float) -> void:
	if not _arrived:
		var dist := global_position.distance_to(_target_pos)
		if dist < 6.0:
			_arrived = true
			velocity = Vector2.ZERO
		else:
			velocity = global_position.direction_to(_target_pos) * 80.0
			move_and_slide()
		return

	_stay_timer += delta
	if _stay_timer >= data.stay_duration:
		_depart()

func interact(player: Player) -> void:
	if not _arrived:
		return
	EventBus.open_trade.emit(data, NetworkRegistry.get_id(player))

func _depart() -> void:
	set_physics_process(false)
	hint_label.hide()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		departed.emit()
		queue_free()
	)
