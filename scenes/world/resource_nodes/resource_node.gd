class_name ResourceNode
extends StaticBody2D

signal depleted
signal respawned

@export var item: ItemResource
@export var drop_amount: int = 3
@export var respawn_time: float = 30.0

@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

var is_depleted := false

func _ready() -> void:
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func interact(player: Player) -> void:
	if is_depleted or item == null:
		return
	var leftover := player.inventory.add_item(item, drop_amount)
	if leftover > 0:
		_spawn_drops(leftover)
	_deplete()

func _deplete() -> void:
	is_depleted = true
	hint_label.hide()
	modulate = Color(0.5, 0.5, 0.5)
	depleted.emit()
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	is_depleted = false
	modulate = Color.WHITE
	respawned.emit()

func _spawn_drops(amount: int) -> void:
	var drop: DropItem = DropItemScene.instantiate()
	drop.position = global_position + Vector2(randf_range(-20.0, 20.0), -10.0)
	get_parent().add_child(drop)
	drop.setup(item, amount)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_depleted:
		hint_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		hint_label.hide()

