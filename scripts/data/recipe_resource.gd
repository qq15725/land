class_name RecipeResource
extends Resource

@export var id: String = ""
@export var output_item: ItemResource
@export var output_amount: int = 1
@export var ingredients: Array[RecipeIngredient] = []
@export var requires_workbench: bool = false
