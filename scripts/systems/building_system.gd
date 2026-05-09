extends Node

signal build_mode_entered(building: BuildingData)
signal build_mode_exited
signal building_placed(building: BuildingData, pos: Vector2)

var current_building: BuildingData = null
var is_building: bool = false

func _ready() -> void:
	pass

func get_all_buildings() -> Array:
	return ItemDatabase.get_all_buildings()

func can_afford(building: BuildingData, inventory: InventoryComponent) -> bool:
	for cost in building.cost:
		if not inventory.has_item(cost["item"], cost["amount"]):
			return false
	return true

func enter_build_mode(building: BuildingData) -> void:
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
	for cost in current_building.cost:
		inventory.remove_item(cost["item"], cost["amount"])
	building_placed.emit(current_building, pos)
	exit_build_mode()
	return true
