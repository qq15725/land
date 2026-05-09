class_name StoneNode
extends ResourceNode

func _ready() -> void:
	item = ItemDatabase.get_item("stone")
	super._ready()
