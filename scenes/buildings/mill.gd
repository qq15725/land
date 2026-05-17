class_name Mill
extends BuildingBase

# 磨坊：交互一次，将背包内所有小麦转换为面粉（1:1）。
const WHEAT_ID := "wheat"
const FLOUR_ID := "flour"

func _ready() -> void:
	super._ready()
	if hint_label:
		hint_label.text = "[E] 磨面粉"

func interact(player: Player) -> void:
	var wheat := ItemDatabase.get_item(WHEAT_ID)
	var flour := ItemDatabase.get_item(FLOUR_ID)
	if wheat == null or flour == null:
		return
	# 统计小麦总数
	var total := 0
	for slot in player.inventory.slots:
		if slot.item == wheat:
			total += int(slot.amount)
	if total <= 0:
		if hint_label:
			hint_label.text = "没有小麦"
		return
	player.inventory.remove_item(wheat, total)
	player.inventory.add_item(flour, total)
	if hint_label:
		hint_label.text = "磨成 %d 面粉" % total
