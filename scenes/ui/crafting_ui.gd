extends DraggablePanel

var _inventory: InventoryComponent
var _recipe_list: VBoxContainer
var _current_station: String = ""

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(360, 440)
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

func _add_recipe_entry(recipe: RecipeData) -> void:
	var accessible := recipe.required_station == "" or recipe.required_station == _current_station
	var craftable := accessible and CraftingSystem.can_craft(recipe, _inventory)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.modulate = Color.WHITE if craftable else Color(0.6, 0.6, 0.6)
	_recipe_list.add_child(row)

	row.add_child(_make_chip(recipe.output_item, recipe.output_amount, 44))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = recipe.output_item.display_name
	info.add_child(name_lbl)

	var ing_box := HBoxContainer.new()
	ing_box.add_theme_constant_override("separation", 2)
	for ing in recipe.ingredients:
		ing_box.add_child(_make_chip(ing["item"], ing["amount"], 28))
	info.add_child(ing_box)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 0)
	btn.disabled = not craftable
	if not accessible:
		btn.text = _station_name(recipe.required_station)
	else:
		btn.text = "合成"
		btn.pressed.connect(func(): _on_craft(recipe))
	row.add_child(btn)

	_recipe_list.add_child(HSeparator.new())

func _make_chip(item: ItemData, amount: int, size: int) -> Control:
	var chip := ItemIcon.new()
	chip.custom_minimum_size = Vector2(size, size)
	chip.show_item(item, amount)
	return chip

func _station_name(station: String) -> String:
	match station:
		"workbench": return "需要工作台"
		"cooking_pot": return "需要烹饪锅"
		_: return "需要 " + station

func _on_craft(recipe: RecipeData) -> void:
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
