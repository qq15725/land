extends Node

var _items: Dictionary = {}

func _ready() -> void:
	_load_items()

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

func get_item(id: String) -> ItemResource:
	return _items.get(id, null)
