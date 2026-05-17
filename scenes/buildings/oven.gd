class_name Oven
extends BuildingBase

func _ready() -> void:
	super._ready()
	if hint_label:
		hint_label.text = "[E] 烤炉"

func interact(_player: Player) -> void:
	EventBus.open_crafting.emit("oven")
