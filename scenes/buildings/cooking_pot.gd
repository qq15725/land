class_name CookingPot
extends BuildingBase

func interact(_player: Player) -> void:
	EventBus.open_crafting.emit("cooking_pot")
