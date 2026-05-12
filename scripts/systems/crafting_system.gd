extends Node

# 合成系统（G5 后接受 Player 参数，UI 不再直接改 InventoryComponent）。

var recipes: Array:
	get:
		return ItemDatabase.get_all_recipes()

func get_recipes() -> Array:
	return ItemDatabase.get_all_recipes()

func can_craft(recipe: RecipeData, player: Player) -> bool:
	if player == null or player.inventory == null:
		return false
	for ing in recipe.ingredients:
		if not player.inventory.has_item(ing["item"], ing["amount"]):
			return false
	return true

# 仅 server 应该调用（PlayerActions 已经做权威性判断）。
func craft(recipe: RecipeData, player: Player) -> bool:
	if not can_craft(recipe, player):
		return false
	for ing in recipe.ingredients:
		player.inventory.remove_item(ing["item"], ing["amount"])
	player.inventory.add_item(recipe.output_item, recipe.output_amount)
	EventBus.item_crafted.emit(recipe)
	return true
