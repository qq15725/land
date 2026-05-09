class_name ResourceNode
extends StaticBody2D

signal depleted
signal respawned

var item: ItemData
@export var drop_amount: int = 3
@export var respawn_time: float = 30.0

@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

var depleted_flag := false
var _regen_elapsed: float = 0.0

func _ready() -> void:
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

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
	_regen_elapsed = 0.0
	hint_label.hide()
	modulate = Color(0.5, 0.5, 0.5)
	depleted.emit()
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	depleted_flag = false
	_regen_elapsed = 0.0
	modulate = Color.WHITE
	respawned.emit()

func is_depleted() -> bool:
	return depleted_flag

func get_regen_timer() -> float:
	return _regen_elapsed

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
