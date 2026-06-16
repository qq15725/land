class_name Conveyor
extends AutomationNode

# 传送带：容量 1 的物品槽，每 tick 把物品推给朝向的下一个节点。

var _item: ItemData = null
var _item_sprite: Sprite2D

func _node_color() -> Color:
	return Color(0.32, 0.38, 0.5, 0.95)

func tick() -> void:
	if _item == null or _moved_this_tick:
		return
	var front = AutomationSystem.node_at(front_cell())
	if front and front.can_accept(_item):
		if front.push_item(_item):
			_item = null
			_update_item_visual()

func can_accept(_item_in: ItemData) -> bool:  # 基类标注 ItemData，子类 super 调用可推断类型
	return _item == null and not _moved_this_tick

func push_item(item: ItemData) -> bool:
	if _item != null or _moved_this_tick:
		return false
	_item = item
	_moved_this_tick = true
	_update_item_visual()
	return true

func peek_item() -> ItemData:
	return _item

func take_item() -> ItemData:
	var i := _item
	_item = null
	_update_item_visual()
	return i

func _update_item_visual() -> void:
	if _item == null:
		if _item_sprite:
			_item_sprite.visible = false
		return
	if _item_sprite == null:
		_item_sprite = Sprite2D.new()
		_item_sprite.position = Vector2(0, -8)
		_item_sprite.z_index = 1
		_item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_item_sprite)
	_item_sprite.visible = true
	_item_sprite.texture = ItemDatabase.get_item_icon(_item)
	var s := 10.0 / maxf(float(ItemDatabase.get_icon_size()), 1.0)
	_item_sprite.scale = Vector2(s, s)

func get_save_state() -> Dictionary:
	var d := super.get_save_state()
	d["item_id"] = _item.id if _item else ""
	return d

func load_save_state(data: Dictionary) -> void:
	super.load_save_state(data)
	var iid: String = data.get("item_id", "")
	_item = ItemDatabase.get_item(iid) if not iid.is_empty() else null
	_update_item_visual()
