extends Node

# 玩家动作分发器（G3 输入抽象）。
#
# 设计：所有玩家发起的"破坏性"动作（修改 server 权威状态：背包、HP、伤害怪物、
# 拾取、交互、选中槽位）走这里。
#
# 调用约定：
# - 业务代码（Player.gd / HUD / UI）调 `request_xxx(...)`
# - 在 server 端直接本地执行；在 client 端通过 rpc_id(1, ...) 发给 server 校验
# - server 执行后通过 EventBus / Synchronizer 把状态变化反向同步到所有 client
# - 单机模式 `Network.is_server() == true`，所有 request 在本地直接生效
#
# 移动暂不走这里（client-predicted），G8 才加移动同步层。

func request_select_hotbar(slot: int) -> void:
	if Network.is_server():
		_do_select_hotbar(Network.local_peer_id(), slot)
	else:
		_rpc_select_hotbar.rpc_id(Network.SERVER_PEER_ID, slot)

func request_use_selected_item() -> void:
	if Network.is_server():
		_do_use_selected_item(Network.local_peer_id())
	else:
		_rpc_use_selected_item.rpc_id(Network.SERVER_PEER_ID)

func request_attack() -> void:
	if Network.is_server():
		_do_attack(Network.local_peer_id())
	else:
		_rpc_attack.rpc_id(Network.SERVER_PEER_ID)

func request_cast_skill(skill_id: String, target_pos: Vector2) -> void:
	if Network.is_server():
		_do_cast_skill(Network.local_peer_id(), skill_id, target_pos)
	else:
		_rpc_cast_skill.rpc_id(Network.SERVER_PEER_ID, skill_id, target_pos)

func request_learn_skill(skill_id: String) -> void:
	if Network.is_server():
		_do_learn_skill(Network.local_peer_id(), skill_id)
	else:
		_rpc_learn_skill.rpc_id(Network.SERVER_PEER_ID, skill_id)

func request_set_class(class_id: String) -> void:
	if Network.is_server():
		_do_set_class(Network.local_peer_id(), class_id)
	else:
		_rpc_set_class.rpc_id(Network.SERVER_PEER_ID, class_id)

func request_equip_skill(slot: int, skill_id: String) -> void:
	if Network.is_server():
		_do_equip_skill(Network.local_peer_id(), slot, skill_id)
	else:
		_rpc_equip_skill.rpc_id(Network.SERVER_PEER_ID, slot, skill_id)

func request_interact() -> void:
	if Network.is_server():
		_do_interact(Network.local_peer_id())
	else:
		_rpc_interact.rpc_id(Network.SERVER_PEER_ID)

# 拾取（DropItem 主动碰撞时也走这里，避免 client 自行加物品）
func request_pickup(drop_id: int) -> void:
	if Network.is_server():
		_do_pickup(Network.local_peer_id(), drop_id)
	else:
		_rpc_pickup.rpc_id(Network.SERVER_PEER_ID, drop_id)

func request_craft(recipe_id: String) -> void:
	if Network.is_server():
		_do_craft(Network.local_peer_id(), recipe_id)
	else:
		_rpc_craft.rpc_id(Network.SERVER_PEER_ID, recipe_id)

func request_place_building(pos: Vector2) -> void:
	if Network.is_server():
		_do_place_building(Network.local_peer_id(), pos)
	else:
		_rpc_place_building.rpc_id(Network.SERVER_PEER_ID, pos)

func request_trade(merchant_id: String, trade_index: int) -> void:
	if Network.is_server():
		_do_trade(Network.local_peer_id(), merchant_id, trade_index)
	else:
		_rpc_trade.rpc_id(Network.SERVER_PEER_ID, merchant_id, trade_index)

func request_sell(item_id: String, amount: int) -> void:
	if Network.is_server():
		_do_sell(Network.local_peer_id(), item_id, amount)
	else:
		_rpc_sell.rpc_id(Network.SERVER_PEER_ID, item_id, amount)

# ─── RPC 入口（client → server） ────────────────────────────────────────

@rpc("any_peer", "call_remote", "reliable")
func _rpc_select_hotbar(slot: int) -> void:
	if not Network.is_server():
		return
	_do_select_hotbar(_sender_peer_id(), slot)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_use_selected_item() -> void:
	if not Network.is_server():
		return
	_do_use_selected_item(_sender_peer_id())

@rpc("any_peer", "call_remote", "reliable")
func _rpc_attack() -> void:
	if not Network.is_server():
		return
	_do_attack(_sender_peer_id())

@rpc("any_peer", "call_remote", "reliable")
func _rpc_cast_skill(skill_id: String, target_pos: Vector2) -> void:
	if not Network.is_server():
		return
	_do_cast_skill(_sender_peer_id(), skill_id, target_pos)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_learn_skill(skill_id: String) -> void:
	if not Network.is_server():
		return
	_do_learn_skill(_sender_peer_id(), skill_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_set_class(class_id: String) -> void:
	if not Network.is_server():
		return
	_do_set_class(_sender_peer_id(), class_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_equip_skill(slot: int, skill_id: String) -> void:
	if not Network.is_server():
		return
	_do_equip_skill(_sender_peer_id(), slot, skill_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_interact() -> void:
	if not Network.is_server():
		return
	_do_interact(_sender_peer_id())

@rpc("any_peer", "call_remote", "reliable")
func _rpc_pickup(drop_id: int) -> void:
	if not Network.is_server():
		return
	_do_pickup(_sender_peer_id(), drop_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_craft(recipe_id: String) -> void:
	if not Network.is_server():
		return
	_do_craft(_sender_peer_id(), recipe_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_place_building(pos: Vector2) -> void:
	if not Network.is_server():
		return
	_do_place_building(_sender_peer_id(), pos)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_trade(merchant_id: String, trade_index: int) -> void:
	if not Network.is_server():
		return
	_do_trade(_sender_peer_id(), merchant_id, trade_index)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_sell(item_id: String, amount: int) -> void:
	if not Network.is_server():
		return
	_do_sell(_sender_peer_id(), item_id, amount)

# ─── server 执行 ────────────────────────────────────────────────────────

func _do_select_hotbar(peer_id: int, slot: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.inventory.set_selected_slot(slot)

func _do_use_selected_item(peer_id: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.do_use_selected_item()

func _do_attack(peer_id: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.do_attack()

func _do_cast_skill(peer_id: int, skill_id: String, target_pos: Vector2) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.do_cast_skill(skill_id, target_pos)

func _do_learn_skill(peer_id: int, skill_id: String) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	var skill := ItemDatabase.get_active_skill(skill_id)
	if skill == null:
		return
	p.active_skills.try_learn(skill)

func _do_set_class(peer_id: int, class_id: String) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.active_skills.set_class(class_id)

func _do_equip_skill(peer_id: int, slot: int, skill_id: String) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	if slot < 0 or slot >= p.equipped_skills.size():
		return
	# 只允许装备已学技能（或空字符串清空）
	if not skill_id.is_empty() and not p.active_skills.is_learned(skill_id):
		return
	p.equipped_skills[slot] = skill_id

func _do_interact(peer_id: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	p.do_interact()

func _do_pickup(peer_id: int, drop_id: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	var drop := NetworkRegistry.get_node_by_id(drop_id) as DropItem
	if drop == null:
		return
	drop.try_pickup(p)

func _do_craft(peer_id: int, recipe_id: String) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	for r in CraftingSystem.get_recipes():
		if (r as RecipeData).id == recipe_id:
			CraftingSystem.craft(r, p)
			return

func _do_place_building(peer_id: int, pos: Vector2) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	BuildingSystem.place_building(pos, p)

func _do_trade(peer_id: int, merchant_id: String, trade_index: int) -> void:
	var p := _player_for(peer_id)
	if p == null:
		return
	var merchant: MerchantData = null
	for m in ItemDatabase.get_all_merchants():
		if (m as MerchantData).id == merchant_id:
			merchant = m
			break
	if merchant == null or trade_index < 0 or trade_index >= merchant.trades.size():
		return
	var entry: Dictionary = merchant.trades[trade_index]
	if not p.inventory.has_item(entry["give_item"], entry["give_amount"]):
		return
	var leftover := p.inventory.add_item(entry["receive_item"], entry["receive_amount"])
	if leftover > 0:
		return  # 背包满，回滚
	p.inventory.remove_item(entry["give_item"], entry["give_amount"])
	EventBus.trade_completed.emit(entry["give_item"], entry["receive_item"])

func _do_sell(peer_id: int, item_id: String, amount: int) -> void:
	var p := _player_for(peer_id)
	if p == null or amount <= 0:
		return
	var item := ItemDatabase.get_item(item_id)
	if item == null or item.sell_price <= 0:
		return
	if not p.inventory.has_item(item, amount):
		return
	p.inventory.remove_item(item, amount)
	var revenue: int = item.sell_price * amount
	p.inventory.add_gold(revenue)
	EventBus.item_sold.emit(item, amount, revenue)

# ─── helper ─────────────────────────────────────────────────────────────

func _sender_peer_id() -> int:
	var s := multiplayer.get_remote_sender_id()
	return s if s != 0 else Network.local_peer_id()

# 单机：唯一 Player；多人（G8 起）：按 peer_id meta 查找
func _player_for(peer_id: int) -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	if Network.is_singleplayer():
		return players[0] as Player
	for p in players:
		if int(p.get_meta("peer_id", 0)) == peer_id:
			return p as Player
	return null
