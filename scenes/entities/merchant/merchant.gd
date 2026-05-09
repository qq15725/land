class_name Merchant
extends CharacterBody2D

signal departed

@onready var visual: Sprite2D = $Visual
@onready var interact_area: Area2D = $InteractArea
@onready var hint_label: Label = $HintLabel

var data: MerchantData
var _target_pos: Vector2 = Vector2.ZERO
var _arrived: bool = false
var _stay_timer: float = 0.0

func _ready() -> void:
	hint_label.hide()
	interact_area.body_entered.connect(func(b): if b is Player: hint_label.show())
	interact_area.body_exited.connect(func(b): if b is Player: hint_label.hide())

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
	EventBus.open_trade.emit(data, player.inventory)

func _depart() -> void:
	set_physics_process(false)
	hint_label.hide()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func():
		departed.emit()
		queue_free()
	)
