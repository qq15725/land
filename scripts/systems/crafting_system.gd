extends Node

var recipes: Array:
	get:
		return ItemDatabase.get_all_recipes()

func get_recipes() -> Array:
	return ItemDatabase.get_all_recipes()

func can_craft(recipe: RecipeData, inventory: InventoryComponent) -> bool:
	for ing in recipe.ingredients:
		if not inventory.has_item(ing["item"], ing["amount"]):
			return false
	return true

func craft(recipe: RecipeData, inventory: InventoryComponent) -> bool:
	if not can_craft(recipe, inventory):
		return false
	for ing in recipe.ingredients:
		inventory.remove_item(ing["item"], ing["amount"])
	inventory.add_item(recipe.output_item, recipe.output_amount)
	return true
