class_name AnimalPen
extends BuildingBase

@export var animal_data: AnimalResource = null

const AnimalScene := preload("res://scenes/farm/animal.tscn")

func interact(_player: Player) -> void:
	pass

func on_placed() -> void:
	if not animal_data:
		return
	var animal: Animal = AnimalScene.instantiate()
	animal.data = animal_data
	get_parent().add_child(animal)
	animal.global_position = global_position + Vector2(0.0, 25.0)
