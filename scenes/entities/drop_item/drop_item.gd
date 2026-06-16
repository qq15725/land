class_name DropItem
extends Area2D

var item: ItemData
var amount: int = 1

@onready var visual: Sprite2D = $Visual
@onready var count_label: Label = $CountLabel

# 吸附：玩家进入半径内时掉落物飞向玩家，减少捡东西的走位精度要求
const MAGNET_RADIUS := 52.0
const MAGNET_SPEED := 200.0
var _spawn_time: float = 0.0

func _ready() -> void:
	NetworkRegistry.attach(self)
	FogSystem.register_dynamic(self)
	body_entered.connect(_on_body_entered)
	_refresh_visual()

func _physics_process(delta: float) -> void:
	# 吸附只在权威端（单机即 server）计算；多人下客户端通过同步接收位置
	if not Network.is_server():
		return
	# 刚掉落的前 0.4s 不吸附，让掉落物有自然散开的瞬间
	_spawn_time += delta
	if _spawn_time < 0.4:
		return
	var players := get_tree().get_nodes_in_group("player")
	var nearest: Node2D = null
	var nearest_d := MAGNET_RADIUS
	for pl in players:
		if not pl is Node2D:
			continue
		var d := global_position.distance_to((pl as Node2D).global_position)
		if d < nearest_d:
			nearest_d = d
			nearest = pl as Node2D
	if nearest:
		global_position = global_position.move_toward(nearest.global_position, MAGNET_SPEED * delta)

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
