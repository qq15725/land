class_name AutoCrafter
extends AutomationNode

# 自动合成机：任意相邻传送带把材料推进输入缓冲，凑齐某配方即自动合成，
# 成品从朝向(front)输出。配方自动匹配（玩家通过控制输入材料决定产出）。

const INPUT_CAP := 30
const CRAFT_SECONDS := 2.0

var _input: Dictionary = {}     # item_id → count
var _output_item: ItemData = null
var _output_amount: int = 0
var _craft_timer: float = 0.0
var _recipe: RecipeData = null

func _node_color() -> Color:
	return Color(0.46, 0.4, 0.56, 0.95)

func _build_node_visual() -> void:
	super._build_node_visual()
	# 合成机更大一点的方块叠加，区分于传送带
	var box := Polygon2D.new()
	box.polygon = PackedVector2Array([Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)])
	box.color = Color(0.85, 0.75, 0.4, 0.7)
	box.position = Vector2(0, -8)
	add_child(box)

# 任意方向都可送入材料
func can_accept(_item: ItemData) -> bool:
	return _total_input() < INPUT_CAP

func push_item(item: ItemData) -> bool:
	if not can_accept(item):
		return false
	_input[item.id] = int(_input.get(item.id, 0)) + 1
	return true

func tick() -> void:
	# 1) 有成品 → 推给 front
	if _output_item != null:
		var front = AutomationSystem.node_at(front_cell())
		if front and front.can_accept(_output_item) and front.push_item(_output_item):
			_output_amount -= 1
			if _output_amount <= 0:
				_output_item = null
		return
	# 2) 合成中 → 计时
	if _recipe != null:
		_craft_timer -= AutomationSystem.TICK_INTERVAL
		if _craft_timer <= 0.0:
			_output_item = _recipe.output_item
			_output_amount = maxi(1, _recipe.output_amount)
			_recipe = null
		return
	# 3) 空闲 → 找可合成配方并扣料
	var r := _find_craftable()
	if r != null:
		for ing in r.ingredients:
			_input[ing.item_id] = int(_input.get(ing.item_id, 0)) - int(ing.amount)
		_recipe = r
		_craft_timer = CRAFT_SECONDS

func _find_craftable() -> RecipeData:
	for r in ItemDatabase.get_all_recipes():
		if r.output_item == null:
			continue
		var ok := true
		for ing in r.ingredients:
			if int(_input.get(ing.item_id, 0)) < int(ing.amount):
				ok = false
				break
		if ok:
			return r
	return null

func _total_input() -> int:
	var t := 0
	for v in _input.values():
		t += int(v)
	return t

# 输出端供 front 抽取
func peek_item() -> ItemData:
	return _output_item

func take_item() -> ItemData:
	var i := _output_item
	if i != null:
		_output_amount -= 1
		if _output_amount <= 0:
			_output_item = null
	return i

func get_save_state() -> Dictionary:
	var d := super.get_save_state()
	d["input"] = _input.duplicate()
	d["out_id"] = _output_item.id if _output_item else ""
	d["out_amt"] = _output_amount
	return d

func load_save_state(data: Dictionary) -> void:
	super.load_save_state(data)
	_input = (data.get("input", {}) as Dictionary).duplicate()
	var oid: String = data.get("out_id", "")
	_output_item = ItemDatabase.get_item(oid) if not oid.is_empty() else null
	_output_amount = int(data.get("out_amt", 0))
	# 合成中状态不持久化，读档后按输入缓冲重新匹配
