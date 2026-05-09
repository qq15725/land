class_name TreeNode
extends ResourceNode

func _ready() -> void:
	var data := ItemDatabase.get_resource_node("tree")
	if data:
		item = data.drop_item
		drop_amount = data.drop_amount
		respawn_time = data.respawn_time
	super._ready()
