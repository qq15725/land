class_name Player
extends CharacterBody2D

const SPEED := 150.0
const ATTACK_DAMAGE := 15.0
const ATTACK_COOLDOWN := 0.5
const ATTACK_RANGE := 50.0
const KNOCKBACK_FORCE := 180.0

@onready var inventory: InventoryComponent = $InventoryComponent
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_area: Area2D = $InteractionArea
@onready var visual: Polygon2D = $Visual
@onready var attack_area: Area2D = $AttackArea

var _attack_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	health.died.connect(_on_died)
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if dir.x != 0.0:
		visual.scale.x = sign(dir.x)

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("use_item"):
		_use_selected_item()
	elif event.is_action_pressed("attack"):
		_try_attack()

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

func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = ATTACK_COOLDOWN
	_flash_attack()
	for body in attack_area.get_overlapping_bodies():
		if body is Creature:
			var creature := body as Creature
			creature.health.take_damage(ATTACK_DAMAGE)
			var kb_dir := (creature.global_position - global_position).normalized()
			creature.velocity += kb_dir * KNOCKBACK_FORCE

func _flash_attack() -> void:
	visual.modulate = Color(1.5, 1.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not _is_dead:
		visual.modulate = Color.WHITE

func _on_died() -> void:
	_is_dead = true
	visible = false
	set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	health.heal(health.max_health)
	global_position = Vector2.ZERO
	visible = true
	_is_dead = false
	set_physics_process(true)
