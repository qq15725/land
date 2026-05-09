extends Node

signal merchant_arriving(merchant: MerchantData)
signal merchant_departed

const MerchantScene := preload("res://scenes/entities/merchant/merchant.tscn")

var _trade_post: Node2D = null
var _current_merchant_node: Node2D = null
var _visit_timer: float = 0.0
var _next_interval: float = 0.0
var _active: bool = false

func _process(delta: float) -> void:
	if not _active:
		return
	if is_instance_valid(_current_merchant_node):
		return
	_visit_timer += delta
	if _visit_timer >= _next_interval:
		_visit_timer = 0.0
		_spawn_merchant()

func activate(trade_post: Node2D) -> void:
	_trade_post = trade_post
	_active = true
	_schedule_next_visit()

func deactivate() -> void:
	_active = false
	_trade_post = null
	if is_instance_valid(_current_merchant_node):
		_current_merchant_node.queue_free()
		_current_merchant_node = null

func _spawn_merchant() -> void:
	if not is_instance_valid(_trade_post):
		return
	var merchants := ItemDatabase.get_all_merchants()
	if merchants.is_empty():
		return
	var data: MerchantData = merchants[randi() % merchants.size()]
	var node: Node2D = MerchantScene.instantiate()
	node.setup(data, _trade_post.global_position)
	_trade_post.get_parent().add_child(node)
	_current_merchant_node = node
	merchant_arriving.emit(data)
	node.departed.connect(_on_merchant_departed)

func _on_merchant_departed() -> void:
	_current_merchant_node = null
	merchant_departed.emit()
	_schedule_next_visit()

func _schedule_next_visit() -> void:
	var merchants := ItemDatabase.get_all_merchants()
	if merchants.is_empty():
		return
	var data: MerchantData = merchants[randi() % merchants.size()]
	_next_interval = data.visit_interval
	_visit_timer = 0.0

func get_current_merchant() -> Node2D:
	return _current_merchant_node
