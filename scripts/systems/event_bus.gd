extends Node

signal item_picked_up(item: ItemResource, amount: int)
signal player_damaged(amount: float)
signal player_died
signal resource_depleted(node: Node)
signal resource_respawned(node: Node)
signal open_crafting(station: String)
signal open_storage(storage: Node)
signal open_trade(merchant: MerchantResource, player_inventory: InventoryComponent)
