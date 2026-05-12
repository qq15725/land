class_name DropItem
extends Area2D

var item: ItemData
var amount: int = 1

@onready var visual: Sprite2D = $Visual
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	NetworkRegistry.attach(self)
	body_entered.connect(_on_body_entered)
	_refresh_visual()

func setup(p_item: ItemData, p_amount: int) -> void:
	item = p_item
	amount = p_amount
	if is_inside_tree():
		_refresh_visual()

func _refresh_visual() -> void:
	if item:
		visual.texture = ItemDatabase.get_item_icon(item)
		# 始终渲染为约 16 px 世界单位（1 格），让占位/正式版图标尺寸自适配
		var s := 16.0 / maxf(float(ItemDatabase.get_icon_size()), 1.0)
		visual.scale = Vector2(s, s)
	else:
		visual.texture = null
	count_label.text = str(amount) if amount > 1 else ""

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	# 客户端不直接改背包：把意图发给 server，由 server 走 try_pickup 仲裁
	PlayerActions.request_pickup(NetworkRegistry.get_id(self))

# server 上执行实际拾取逻辑。
func try_pickup(player: Player) -> void:
	if item == null or amount <= 0:
		return
	var before := amount
	var leftover: int = player.inventory.add_item(item, amount)
	var picked := before - leftover
	if picked > 0:
		EventBus.item_picked_up.emit(item, picked)
	if leftover == 0:
		queue_free()
	else:
		amount = leftover
		count_label.text = str(amount)
