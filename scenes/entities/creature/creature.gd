class_name Creature
extends CharacterBody2D

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

@export var data: CreatureResource

@onready var health: HealthComponent = $HealthComponent
@onready var visual: Sprite2D = $Visual
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

enum State { WANDER, CHASE, ATTACK, DEAD }

var _state: State = State.WANDER
var _target: Player = null
var _wander_target: Vector2 = Vector2.ZERO
var _spawn_pos: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0
var _wander_timer: float = 0.0

func _ready() -> void:
	if not data:
		return
	health.max_health = data.max_health
	health.current_health = data.max_health
	if data.texture:
		visual.texture = data.texture
		visual.scale = Vector2.ONE * data.sprite_scale
		visual.position.y = -(data.texture.get_height() * data.sprite_scale) / 2.0

	var det_circle := detection_shape.shape as CircleShape2D
	if det_circle:
		det_circle.radius = data.detection_radius
	var atk_circle := attack_shape.shape as CircleShape2D
	if atk_circle:
		atk_circle.radius = data.attack_range

	_spawn_pos = global_position
	_pick_wander_target()

	health.died.connect(_on_died)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)

	match _state:
		State.WANDER:
			_do_wander(delta)
		State.CHASE:
			_do_chase(delta)
		State.ATTACK:
			_do_attack(delta)

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	var dist := global_position.distance_to(_wander_target)
	if dist < 8.0 or _wander_timer <= 0.0:
		_pick_wander_target()
		return
	velocity = global_position.direction_to(_wander_target) * data.move_speed * 0.5
	move_and_slide()
	_update_facing()

func _do_chase(delta: float) -> void:
	if not is_instance_valid(_target):
		_state = State.WANDER
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist <= data.attack_range:
		_state = State.ATTACK
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(_target.global_position) * data.move_speed
	move_and_slide()
	_update_facing()

func _do_attack(_delta: float) -> void:
	if not is_instance_valid(_target):
		_state = State.WANDER
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist > data.attack_range * 1.3:
		_state = State.CHASE
		return
	if _attack_timer <= 0.0:
		_target.health.take_damage(data.attack_damage)
		_attack_timer = data.attack_cooldown
		_flash_attack()

func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(40.0, data.wander_radius)
	_wander_target = _spawn_pos + Vector2(cos(angle), sin(angle)) * dist
	_wander_timer = randf_range(3.0, 7.0)

func _update_facing() -> void:
	if velocity.x != 0.0:
		visual.scale.x = sign(velocity.x) * absf(visual.scale.x)

func _flash_attack() -> void:
	visual.modulate = Color(2.0, 0.5, 0.5)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and _state != State.DEAD:
		visual.modulate = Color.WHITE

func _on_body_entered(body: Node2D) -> void:
	if body is Player and _state != State.DEAD:
		_target = body as Player
		_state = State.CHASE

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _state == State.CHASE or _state == State.ATTACK:
			_state = State.WANDER
		_target = null

func _on_died() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	set_physics_process(false)
	_spawn_drops()
	visual.modulate = Color(0.4, 0.4, 0.4, 0.5)
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _spawn_drops() -> void:
	if not data:
		return
	for entry in data.drop_table:
		var chance: float = entry.get("chance", 1.0)
		if randf() > chance:
			continue
		var item_id: String = entry.get("item_id", "")
		var item := ItemDatabase.get_item(item_id)
		if not item:
			continue
		var amount: int = randi_range(entry.get("min", 1), entry.get("max", 1))
		var drop: DropItem = DropItemScene.instantiate()
		drop.position = global_position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
		get_parent().add_child(drop)
		drop.setup(item, amount)

func aggro() -> void:
	if _state == State.DEAD:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	_target = players[0] as Player
	_state = State.CHASE
