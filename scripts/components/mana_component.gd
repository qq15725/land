class_name ManaComponent
extends Node

signal mana_changed(current: float, maximum: float)

@export var max_mana: float = 100.0
@export var regen_per_sec: float = 0.5

var current_mana: float

func _ready() -> void:
	current_mana = max_mana
	set_process(true)

func _process(delta: float) -> void:
	if current_mana >= max_mana:
		return
	current_mana = minf(max_mana, current_mana + regen_per_sec * delta)
	mana_changed.emit(current_mana, max_mana)

func has(amount: float) -> bool:
	return current_mana >= amount

func consume(amount: float) -> bool:
	if not has(amount):
		return false
	current_mana = maxf(0.0, current_mana - amount)
	mana_changed.emit(current_mana, max_mana)
	return true

func restore(amount: float) -> void:
	current_mana = minf(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)
