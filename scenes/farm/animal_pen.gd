class_name AnimalPen
extends BuildingBase

const AnimalScene := preload("res://scenes/farm/animal.tscn")

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
