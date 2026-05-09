class_name TreeNode
extends ResourceNode

func _ready() -> void:
	item = ItemDatabase.get_item("wood")
	super._ready()
