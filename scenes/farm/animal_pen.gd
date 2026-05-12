class_name AnimalPen
extends BuildingBase

const AnimalScene := preload("res://scenes/farm/animal.tscn")

var _spawned_animal: Animal = null

func interact(_player: Player) -> void:
	pass

func on_placed(data: BuildingData = null) -> void:
	super.on_placed(data)
	var animal_id := ""
	if data != null:
		animal_id = data.animal_id
	else:
		var bd := ItemDatabase.get_building("animal_pen")
		if bd:
			animal_id = bd.animal_id
	if animal_id.is_empty():
		return
	var animal_data := ItemDatabase.get_animal(animal_id)
	if not animal_data:
		return
	var animal: Animal = AnimalScene.instantiate()
	animal.data = animal_data
	get_parent().add_child(animal)
	animal.global_position = global_position + Vector2(0.0, 25.0)
	_spawned_animal = animal

func get_save_state() -> Dictionary:
	if _spawned_animal and is_instance_valid(_spawned_animal):
		return {"animal": _spawned_animal.get_save_state()}
	return {}

func load_save_state(state: Dictionary) -> void:
	var a_state: Dictionary = state.get("animal", {})
	if a_state.is_empty():
		return
	# 等 on_placed 中 add_child 的 animal 完成 _ready
	await get_tree().process_frame
	if _spawned_animal and is_instance_valid(_spawned_animal):
		_spawned_animal.load_save_state(a_state)
