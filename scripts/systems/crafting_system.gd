extends Node

var recipes: Array = []

func _ready() -> void:
	_load_recipes()

func _load_recipes() -> void:
	var dir := DirAccess.open("res://resources/recipes/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe := load("res://resources/recipes/" + file_name) as RecipeResource
			if recipe:
				recipes.append(recipe)
		file_name = dir.get_next()

func can_craft(recipe: RecipeResource, inventory: InventoryComponent) -> bool:
	for ingredient in recipe.ingredients:
		var ing := ingredient as RecipeIngredient
		if not inventory.has_item(ing.item, ing.amount):
			return false
	return true

func craft(recipe: RecipeResource, inventory: InventoryComponent) -> bool:
	if not can_craft(recipe, inventory):
		return false
	for ingredient in recipe.ingredients:
		var ing := ingredient as RecipeIngredient
		inventory.remove_item(ing.item, ing.amount)
	inventory.add_item(recipe.output_item, recipe.output_amount)
	return true
