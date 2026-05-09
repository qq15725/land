class_name InventoryComponent
extends Node

signal changed
signal selection_changed(slot_index: int)

@export var slot_count: int = 20

var slots: Array[Dictionary] = []
var selected_slot: int = -1

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

func get_contents() -> String:
	var parts: PackedStringArray = []
	for slot in slots:
		if slot.item != null:
			parts.append("%s x%d" % [slot.item.display_name, slot.amount])
	return ", ".join(parts) if parts.size() > 0 else "空"
