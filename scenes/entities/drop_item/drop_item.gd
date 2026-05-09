class_name DropItem
extends Area2D

var item: ItemData
var amount: int = 1

@onready var visual: Polygon2D = $Visual
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(p_item: ItemData, p_amount: int) -> void:
	item = p_item
	amount = p_amount
	visual.color = item.color
	count_label.text = str(amount) if amount > 1 else ""

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	var leftover: int = player.inventory.add_item(item, amount)
	if leftover == 0:
		queue_free()
	else:
		amount = leftover
		count_label.text = str(amount)
