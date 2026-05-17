class_name Anvil
extends BuildingBase

func _ready() -> void:
	super._ready()
	if hint_label:
		hint_label.text = "[E] 铁砧"

func interact(_player: Player) -> void:
	EventBus.open_crafting.emit("anvil")
