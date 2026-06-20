class_name Bed
extends BuildingBase

# 床建筑：
# - 死亡复活点（group "bed"，player.gd 查找最近的床）
# - 夜晚 E 睡觉：跳到次日清晨 + 回满 HP/MP/FP（经典 farming 机制，跳过夜晚威胁）

func _ready() -> void:
	super._ready()
	add_to_group("bed")
	var area := get_node_or_null("InteractArea") as Area2D
	var hint := get_node_or_null("HintLabel") as Label
	if area and hint:
		hint.text = "[E] 睡觉"
		hint.hide()
		area.body_entered.connect(func(b): if b is Player: hint.show())
		area.body_exited.connect(func(b): if b is Player: hint.hide())

func interact(player: Player) -> void:
	if not TimeSystem.sleep_to_morning():
		UINotify.toast(get_tree(), "现在是白天，不困")
		return
	if player.health:
		player.health.heal(player.health.max_health)
	if player.mana and player.mana.has_method("restore"):
		player.mana.restore(player.mana.max_mana)
	if player.focus:
		player.focus.restore(player.focus.max_focus)
	_disperse_hostiles()
	UINotify.toast(get_tree(), "睡了一觉，神清气爽 ☀")

# 睡觉天亮后驱散场上的敌对夜晚怪（安全过夜，避免醒来被怪围）。passive 野生动物 / Boss 保留。
func _disperse_hostiles() -> void:
	var layer := get_parent()
	if layer == null:
		return
	for c in layer.get_children():
		if c is Creature:
			var cr := c as Creature
			if cr.data and not cr.data.passive and not cr.data.is_boss:
				cr.queue_free()
