extends DraggablePanel

var _inventory: InventoryComponent
var _list: VBoxContainer

func _ready() -> void:
	super()
	custom_minimum_size = Vector2(320, 400)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false
	_build_layout()

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
	title.text = "建造"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	header.add_child(make_close_button())

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func setup(inventory: InventoryComponent) -> void:
	_inventory = inventory
	_inventory.changed.connect(func(): if visible: _refresh())

const _CATEGORY_LABELS := {
	"building": "建筑",
	"farm": "农场",
	"fence": "围栏",
	"decoration": "装饰",
}

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var by_category: Dictionary = {}
	for building in BuildingSystem.get_all_buildings():
		var cat: String = building.category
		if not by_category.has(cat):
			by_category[cat] = []
		by_category[cat].append(building)
	for cat in ["building", "farm", "fence", "decoration"]:
		if not by_category.has(cat):
			continue
		var header := Label.new()
		header.text = _CATEGORY_LABELS.get(cat, cat)
		header.add_theme_font_size_override("font_size", 11)
		header.modulate = Color(0.75, 0.75, 0.75)
		_list.add_child(header)
		for building in by_category[cat]:
			_add_building_entry(building)

func _add_building_entry(building: BuildingData) -> void:
	var can_afford := BuildingSystem.can_afford(building, _inventory.get_parent() as Player)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.modulate = Color.WHITE if can_afford else Color(0.6, 0.6, 0.6)
	_list.add_child(row)

	row.add_child(_make_building_thumb(building))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = building.display_name
	info.add_child(name_lbl)

	var cost_box := HBoxContainer.new()
	cost_box.add_theme_constant_override("separation", 2)
	for c in building.cost:
		var chip := ItemIcon.new()
		chip.custom_minimum_size = Vector2(28, 28)
		chip.show_item(c["item"], c["amount"])
		cost_box.add_child(chip)
	info.add_child(cost_box)

	var btn := Button.new()
	btn.text = "放置"
	btn.disabled = not can_afford
	btn.pressed.connect(func(): _on_place(building))
	row.add_child(btn)

	_list.add_child(HSeparator.new())

func _make_building_thumb(building: BuildingData) -> Control:
	var box := Panel.new()
	box.custom_minimum_size = Vector2(48, 48)
	box.add_theme_stylebox_override("panel", UIStyle.make_slot_style(false))
	var tex := BuildingSystem.get_thumb_texture(building)
	if tex:
		var rect := TextureRect.new()
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.offset_left = 6
		rect.offset_top = 6
		rect.offset_right = -6
		rect.offset_bottom = -6
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(rect)
	return box

func _on_place(building: BuildingData) -> void:
	hide()
	BuildingSystem.enter_build_mode(building)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		if visible:
			hide()
		else:
			_refresh()
			show()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
