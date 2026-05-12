class_name Bed
extends BuildingBase

# 床建筑：玩家死亡时复活到最近的床位置。
# 通过 group "bed" 让 player.gd 快速查找。

func _ready() -> void:
	super._ready()
	add_to_group("bed")
