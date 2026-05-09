class_name RecipeData

var id: String = ""
var output_item_id: String = ""
var output_item: ItemData = null
var output_amount: int = 1
var ingredients: Array = []
# ingredients 元素: {item_id: String, amount: int, item: ItemData}
var required_station: String = ""
