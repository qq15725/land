extends DraggablePanel

var _inventory: InventoryComponent
var _recipe_list: VBoxContainer
var _current_station: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(320, 420)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()
	EventBus.open_crafting.connect(_on_open_crafting)

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "合成"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.pressed.connect(hide)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 340)
	vbox.add_child(scroll)

	_recipe_list = VBoxContainer.new()
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_list)

func setup(inventory: InventoryComponent) -> void:
	_inventory = inventory
	_inventory.changed.connect(func(): if visible: _refresh())

func _on_open_crafting(station: String) -> void:
	_current_station = station
	_refresh()
	show()

func _refresh() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()
	for recipe in CraftingSystem.recipes:
		_add_recipe_entry(recipe)

func _add_recipe_entry(recipe: RecipeResource) -> void:
	var accessible := recipe.required_station == "" or recipe.required_station == _current_station
	var craftable := accessible and CraftingSystem.can_craft(recipe, _inventory)

	var row := HBoxContainer.new()
	row.modulate = Color.WHITE if craftable else Color(0.6, 0.6, 0.6)
	_recipe_list.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = "%s  ×%d" % [recipe.output_item.display_name, recipe.output_amount]
	info.add_child(name_lbl)

	var ing_lbl := Label.new()
	ing_lbl.text = _format_ingredients(recipe.ingredients)
	ing_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(ing_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 0)
	btn.disabled = not craftable
	if not accessible:
		btn.text = "需要：" + _station_name(recipe.required_station)
	else:
		btn.text = "合成"
		btn.pressed.connect(func(): _on_craft(recipe))
	row.add_child(btn)

	_recipe_list.add_child(HSeparator.new())

func _station_name(station: String) -> String:
	match station:
		"workbench": return "工作台"
		"cooking_pot": return "烹饪锅"
		_: return station

func _format_ingredients(ingredients: Array[RecipeIngredient]) -> String:
	var parts: PackedStringArray = []
	for ing in ingredients:
		parts.append("%s ×%d" % [ing.item.display_name, ing.amount])
	return "需要：" + ", ".join(parts)

func _on_craft(recipe: RecipeResource) -> void:
	if CraftingSystem.craft(recipe, _inventory):
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft"):
		if visible:
			hide()
		else:
			_on_open_crafting("")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
