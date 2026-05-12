class_name StorageChest
extends BuildingBase

@onready var storage: InventoryComponent = $InventoryComponent

func interact(_player: Player) -> void:
	EventBus.open_storage.emit(NetworkRegistry.get_id(self))
