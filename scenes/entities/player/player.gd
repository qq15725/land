class_name Player
extends CharacterBody2D

const SPEED := 150.0
const ATTACK_DAMAGE := 15.0
const ATTACK_COOLDOWN := 0.5
const KNOCKBACK_FORCE := 180.0

const SPRITE_PATH := "res://assets/sprites/characters/player.png"
const FRAME_W := 128
const FRAME_H := 256
const FRAME_COLS := 4
const ANIM_FPS := 8.0

@onready var inventory: InventoryComponent = $InventoryComponent
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_area: Area2D = $InteractionArea
@onready var visual: AnimatedSprite2D = $Visual
@onready var attack_area: Area2D = $AttackArea

var _attack_timer: float = 0.0
var _is_dead: bool = false
var _click_target: Vector2 = Vector2.ZERO
var _click_moving: bool = false
var _last_anim: String = "walk_down"

const CLICK_STOP_DIST := 6.0


func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(func(amount): EventBus.player_damaged.emit(amount))
	health.died.connect(func(): EventBus.player_died.emit())
	inventory.equipment_changed.connect(_on_equipment_changed)
	add_to_group("player")
	_setup_sprite_frames()
	_on_equipment_changed("")


func _on_equipment_changed(_slot_type: String) -> void:
	health.damage_reduction = inventory.total_defense()


func _setup_sprite_frames() -> void:
	var tex := load(SPRITE_PATH) as Texture2D
	if tex == null:
		return
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	# 行序：0=下 1=上 2=左 3=右
	var anims := [["walk_down", 0], ["walk_up", 1], ["walk_left", 2], ["walk_right", 3]]
	for entry in anims:
		var anim_name: String = entry[0]
		var row: int = entry[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, ANIM_FPS)
		frames.set_animation_loop(anim_name, true)
		for col in FRAME_COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			frames.add_frame(anim_name, atlas)
	visual.sprite_frames = frames
	visual.play(_last_anim)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	var key_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir: Vector2
	if key_dir.length() > 0.0:
		_click_moving = false
		move_dir = key_dir
	elif _click_moving:
		var to_target := _click_target - global_position
		if to_target.length() <= CLICK_STOP_DIST:
			_click_moving = false
			move_dir = Vector2.ZERO
		else:
			move_dir = to_target.normalized()
	velocity = move_dir * SPEED
	move_and_slide()
	_update_animation(move_dir)


func _update_animation(move_dir: Vector2) -> void:
	if move_dir.length() < 0.01:
		visual.stop()
		visual.frame = 0
		return
	var anim: String
	if abs(move_dir.x) >= abs(move_dir.y):
		anim = "walk_right" if move_dir.x > 0 else "walk_left"
	else:
		anim = "walk_down" if move_dir.y > 0 else "walk_up"
	if anim != _last_anim:
		_last_anim = anim
		visual.play(anim)
	elif not visual.is_playing():
		visual.play(anim)


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return
	# 数字键 1-9 直接选 hotbar 槽位
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode
		if code >= KEY_1 and code <= KEY_9:
			inventory.set_selected_slot(code - KEY_1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_click_target = get_global_mouse_position()
		_click_moving = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("use_item"):
		_use_selected_item()
	elif event.is_action_pressed("attack"):
		_try_attack()
	elif OS.get_name() == "Android" and event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var half_w := get_viewport().get_visible_rect().size.x * 0.5
			if touch.position.x >= half_w:
				_click_target = get_canvas_transform().affine_inverse() * touch.position
				_click_moving = true
				get_viewport().set_input_as_handled()


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
		EventBus.item_used.emit(item)


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	var weapon := inventory.get_equipped("weapon")
	# 远程武器需要消耗弹药
	if weapon and weapon.ranged:
		var ammo_item := ItemDatabase.get_item(weapon.ammo_item_id) if not weapon.ammo_item_id.is_empty() else null
		if ammo_item == null or not inventory.has_item(ammo_item, 1):
			return
		inventory.remove_item(ammo_item, 1)

	var speed_mod := weapon.attack_speed if weapon else 0.0
	_attack_timer = ATTACK_COOLDOWN * maxf(0.2, 1.0 - speed_mod)
	_flash_attack()

	var total_damage := ATTACK_DAMAGE + inventory.total_damage_bonus()
	for body in attack_area.get_overlapping_bodies():
		if body is Creature:
			var creature := body as Creature
			creature.health.take_damage(total_damage)
			var kb_dir := (creature.global_position - global_position).normalized()
			creature.velocity += kb_dir * KNOCKBACK_FORCE


func _flash_attack() -> void:
	visual.modulate = Color(1.5, 1.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not _is_dead:
		visual.modulate = Color.WHITE


const DropItemScene := preload("res://scenes/entities/drop_item/drop_item.tscn")

func _on_died() -> void:
	_is_dead = true
	var death_pos := global_position
	visible = false
	set_physics_process(false)
	_drop_inventory_on_death(death_pos)
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
	health.heal(health.max_health)
	global_position = _find_respawn_position()
	visible = true
	_is_dead = false
	set_physics_process(true)

func _find_respawn_position() -> Vector2:
	var beds := get_tree().get_nodes_in_group("bed")
	if beds.is_empty():
		return Vector2.ZERO
	var best: Node2D = beds[0]
	var best_d := global_position.distance_to(best.global_position)
	for b in beds:
		var d: float = global_position.distance_to((b as Node2D).global_position)
		if d < best_d:
			best = b
			best_d = d
	return best.global_position + Vector2(0, 16)  # 床下方一格出生

# 死亡时背包非装备物品掉一半数量；装备类（equip_slot 非空）不掉。
func _drop_inventory_on_death(pos: Vector2) -> void:
	var parent := get_parent()
	for slot in inventory.slots:
		if slot.item == null or slot.amount <= 0:
			continue
		if not slot.item.equip_slot.is_empty():
			continue
		var drop_amount: int = int(slot.amount) / 2
		if drop_amount <= 0:
			continue
		var drop: DropItem = DropItemScene.instantiate()
		drop.position = pos + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		parent.add_child(drop)
		drop.setup(slot.item, drop_amount)
		inventory.remove_item(slot.item, drop_amount)
