extends Node

signal build_mode_entered(building: BuildingResource)
signal build_mode_exited
signal building_placed(building: BuildingResource, pos: Vector2)

var current_building: BuildingResource = null
var is_building: bool = false

var _buildings: Array = []

func _ready() -> void:
	_load_buildings()

func _load_buildings() -> void:
	var dir := DirAccess.open("res://resources/buildings/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var b := load("res://resources/buildings/" + file_name) as BuildingResource
			if b:
				_buildings.append(b)
		file_name = dir.get_next()

func get_all_buildings() -> Array:
	return _buildings

func can_afford(building: BuildingResource, inventory: InventoryComponent) -> bool:
	for ingredient in building.cost:
		var ing := ingredient as RecipeIngredient
		if not inventory.has_item(ing.item, ing.amount):
			return false
	return true

func enter_build_mode(building: BuildingResource) -> void:
	current_building = building
	is_building = true
	build_mode_entered.emit(building)

func exit_build_mode() -> void:
	current_building = null
	is_building = false
	build_mode_exited.emit()

func place_building(pos: Vector2, inventory: InventoryComponent) -> bool:
	if not is_building or current_building == null:
		return false
	if not can_afford(current_building, inventory):
		return false
	for ingredient in current_building.cost:
		var ing := ingredient as RecipeIngredient
		inventory.remove_item(ing.item, ing.amount)
	building_placed.emit(current_building, pos)
	exit_build_mode()
	return true
