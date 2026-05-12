class_name InventoryComponent
extends Node

signal changed
signal selection_changed(slot_index: int)
signal equipment_changed(slot_type: String)

@export var slot_count: int = 20

var slots: Array[Dictionary] = []
var selected_slot: int = -1

# 装备槽：slot_type → ItemData。slot_type 取自 ItemData.equip_slot
# 常见值："weapon" / "armor" / "accessory"
var equipped: Dictionary = {}

func _ready() -> void:
	slots.resize(slot_count)
	for i in slot_count:
		slots[i] = {item = null, amount = 0}

func add_item(item: ItemData, amount: int = 1) -> int:
	for slot in slots:
		if slot.item == item and slot.amount < item.max_stack:
			var space: int = item.max_stack - slot.amount
			var add: int = mini(amount, space)
			slot.amount += add
			amount -= add
			changed.emit()
			if amount == 0:
				return 0
	for slot in slots:
		if slot.item == null:
			var add: int = mini(amount, item.max_stack)
			slot.item = item
			slot.amount = add
			amount -= add
			changed.emit()
			if amount == 0:
				return 0
	return amount

func remove_item(item: ItemData, amount: int = 1) -> bool:
	if not has_item(item, amount):
		return false
	for slot in slots:
		if slot.item == item:
			var remove: int = mini(amount, slot.amount)
			slot.amount -= remove
			amount -= remove
			if slot.amount == 0:
				slot.item = null
			changed.emit()
			if amount == 0:
				return true
	return true

func has_item(item: ItemData, amount: int = 1) -> bool:
	var total := 0
	for slot in slots:
		if slot.item == item:
			total += slot.amount
	return total >= amount

func select_slot(index: int) -> void:
	if index == selected_slot:
		selected_slot = -1
	else:
		selected_slot = index
	selection_changed.emit(selected_slot)

func get_selected_item() -> ItemData:
	if selected_slot < 0 or selected_slot >= slots.size():
		return null
	return slots[selected_slot].item

# ─── 装备 ────────────────────────────────────────────────────────────────────

func equip_from_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var item: ItemData = slots[slot_index].item
	if item == null or item.equip_slot.is_empty():
		return false
	var st: String = item.equip_slot
	# 先卸下旧装备到背包
	var old: ItemData = equipped.get(st)
	slots[slot_index] = {item = null, amount = 0}
	equipped[st] = item
	if old != null:
		add_item(old, 1)
	equipment_changed.emit(st)
	changed.emit()
	return true

func unequip(slot_type: String) -> bool:
	var old: ItemData = equipped.get(slot_type)
	if old == null:
		return false
	equipped.erase(slot_type)
	# 塞回背包；如果背包满则掉在地上的逻辑交给调用者
	var leftover := add_item(old, 1)
	equipment_changed.emit(slot_type)
	changed.emit()
	return leftover == 0

func get_equipped(slot_type: String) -> ItemData:
	return equipped.get(slot_type)

func total_damage_bonus() -> float:
	var v := 0.0
	for it in equipped.values():
		if it:
			v += it.damage
	return v

func total_defense() -> float:
	var v := 0.0
	for it in equipped.values():
		if it:
			v += it.defense
	return v

func get_contents() -> String:
	var parts: PackedStringArray = []
	for slot in slots:
		if slot.item != null:
			parts.append("%s x%d" % [slot.item.display_name, slot.amount])
	return ", ".join(parts) if parts.size() > 0 else "空"
