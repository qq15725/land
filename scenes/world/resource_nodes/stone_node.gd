class_name StoneNode
extends ResourceNode

func _ready() -> void:
	var data := ItemDatabase.get_resource_node("stone_node")
	if data:
		item = data.drop_item
		drop_amount = data.drop_amount
		respawn_time = data.respawn_time
	super._ready()
