extends Node

# 全局事件总线（G6 后所有 Node 引用改成 int network_id；ItemData/CreatureData
# /CropData/RecipeData/MerchantData 等数据对象保持原对象引用，因为它们有
# string id，多人 RPC 时可以用 id 重新查 ItemDatabase）。

signal item_picked_up(item: ItemData, amount: int)
signal player_damaged(amount: float)
signal player_died
signal resource_depleted(resource_id: int, player_id: int)
signal resource_respawned(resource_id: int)
signal open_crafting(station: String)
signal open_storage(storage_id: int)
signal open_trade(merchant: MerchantData, player_id: int)
signal item_crafted(recipe: RecipeData)
signal item_used(item: ItemData)
signal trade_completed(give_item: ItemData, receive_item: ItemData)
signal item_sold(item: ItemData, amount: int, gold_received: int)
signal creature_killed(creature: CreatureData, player_id: int)
signal crop_harvested(crop: CropData, player_id: int)
signal skill_leveled_up(skill_id: String, new_level: int)
