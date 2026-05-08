class_name Workbench
extends BuildingBase

func interact(_player: Player) -> void:
	EventBus.open_crafting.emit(true)
