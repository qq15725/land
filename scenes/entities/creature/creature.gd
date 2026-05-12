class_name Creature
extends CharacterBody2D

const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

var data: CreatureData

@onready var health: HealthComponent = $HealthComponent
@onready var visual: AnimatedSprite2D = $Visual
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
var _last_damager: Player = null

# 由攻击者（Player）调用。记录归属，再走 HealthComponent 扣血。
func take_damage_from(player: Player, amount: float) -> void:
	_last_damager = player
	health.take_damage(amount)

func _ready() -> void:
	NetworkRegistry.attach(self)
	if not data:
		return
	health.max_health = data.max_health
	health.current_health = data.max_health
	_setup_sprite_frames()

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

func _setup_sprite_frames() -> void:
	if not data:
		return
	var tex: Texture2D
	if not data.sprite_path.is_empty():
		tex = load(data.sprite_path) as Texture2D
	if tex == null:
		tex = _make_fallback_texture()
	var fw := tex.get_width() / 4
	var fh := tex.get_height() / 4
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for entry in [["walk_down", 0], ["walk_up", 1], ["walk_left", 2], ["walk_right", 3]]:
		var anim_name: String = entry[0]
		var row: int = entry[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 6.0)
		frames.set_animation_loop(anim_name, true)
		for col in 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	visual.sprite_frames = frames
	visual.play("walk_down")


func _make_fallback_texture() -> ImageTexture:
	const FW := 128
	const FH := 256
	var img := Image.create(FW * 4, FH * 4, false, Image.FORMAT_RGBA8)
	var hue := absf(float(data.id.hash() % 1000) / 1000.0)
	var fill_col := Color.from_hsv(hue, 0.55, 0.75)
	var edge_col := Color.from_hsv(hue, 0.80, 0.35)
	img.fill(fill_col)
	for row in 4:
		for ci in 4:
			var x0 := ci * FW
			var y0 := row * FH
			for px in FW:
				img.set_pixel(x0 + px, y0, edge_col)
				img.set_pixel(x0 + px, y0 + FH - 1, edge_col)
			for py in FH:
				img.set_pixel(x0, y0 + py, edge_col)
				img.set_pixel(x0 + FW - 1, y0 + py, edge_col)
	return ImageTexture.create_from_image(img)


func _update_facing() -> void:
	if velocity.length() < 1.0:
		return
	var anim: String
	if abs(velocity.x) >= abs(velocity.y):
		anim = "walk_right" if velocity.x > 0 else "walk_left"
	else:
		anim = "walk_down" if velocity.y > 0 else "walk_up"
	if visual.animation != anim or not visual.is_playing():
		visual.play(anim)

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
	EventBus.creature_killed.emit(data, NetworkRegistry.get_id(_last_damager) if _last_damager else 0)
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
