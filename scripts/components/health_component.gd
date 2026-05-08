class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	var owner_node := get_parent()
	if owner_node is Node2D:
		HitParticles.spawn(owner_node.get_parent(), (owner_node as Node2D).global_position, Color(0.9, 0.1, 0.1))
	if current_health == 0.0:
		died.emit()

func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0.0
