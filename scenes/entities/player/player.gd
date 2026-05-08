class_name Player
extends CharacterBody2D

const SPEED := 150.0

@onready var inventory: InventoryComponent = $InventoryComponent
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_area: Area2D = $InteractionArea
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	health.died.connect(_on_died)

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if dir.x != 0.0:
		visual.scale.x = sign(dir.x)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("use_item"):
		_use_selected_item()

func _try_interact() -> void:
	var areas := interaction_area.get_overlapping_areas()
	if areas.is_empty():
		return
	var closest: Area2D = areas[0]
	var min_dist := global_position.distance_to(closest.global_position)
	for area in areas:
		var d := global_position.distance_to(area.global_position)
		if d < min_dist:
			min_dist = d
			closest = area
	var parent := closest.get_parent()
	if parent.has_method("interact"):
		parent.interact(self)

func _use_selected_item() -> void:
	var item := inventory.get_selected_item()
	if not item:
		return
	if item.heal_amount > 0.0 and health.current_health < health.max_health:
		health.heal(item.heal_amount)
		inventory.remove_item(item, 1)

func _on_died() -> void:
	visible = false
	set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	health.heal(health.max_health)
	global_position = Vector2.ZERO
	visible = true
	set_physics_process(true)
