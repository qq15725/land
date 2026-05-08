extends Node

var _items: Dictionary = {}
var _crops: Array = []

func _ready() -> void:
	_load_items()
	_load_crops()

func _load_items() -> void:
	var dir := DirAccess.open("res://resources/items/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var item := load("res://resources/items/" + file_name) as ItemResource
			if item:
				_items[item.id] = item
		file_name = dir.get_next()

func _load_crops() -> void:
	var dir := DirAccess.open("res://resources/crops/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var crop := load("res://resources/crops/" + file_name) as CropResource
			if crop:
				_crops.append(crop)
		file_name = dir.get_next()

func get_item(id: String) -> ItemResource:
	return _items.get(id, null)

func get_crop_for_seed(item: ItemResource) -> CropResource:
	for crop in _crops:
		var c := crop as CropResource
		if c and c.seed_item == item:
			return c
	return null

func get_crop_by_id(id: String) -> CropResource:
	for crop in _crops:
		var c := crop as CropResource
		if c and c.id == id:
			return c
	return null
