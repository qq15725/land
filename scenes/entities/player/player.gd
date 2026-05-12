class_name Player
extends CharacterBody2D

const SPEED := 150.0
const ATTACK_DAMAGE := 15.0
const ATTACK_COOLDOWN := 0.5
const KNOCKBACK_FORCE := 280.0
const HIT_STOP_DURATION := 0.06
const HIT_STOP_SCALE := 0.05
const COMBO_TIMEOUT := 1.5
const CRIT_CHANCE := 0.15
const CRIT_MULT := 2.0

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

var skills: PlayerSkills
var peer_id: int = Network.SERVER_PEER_ID
var display_name: String = "冒险者"

# 显式同步：position / hp / velocity / current_anim
# 用 MultiplayerSynchronizer 自动 30Hz 广播
var _sync: MultiplayerSynchronizer
var _sync_anim: String = "walk_down"

var _attack_timer: float = 0.0
var _is_dead: bool = false
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _click_target: Vector2 = Vector2.ZERO
var _click_moving: bool = false
var _last_anim: String = "walk_down"

const CLICK_STOP_DIST := 6.0


func _ready() -> void:
	NetworkRegistry.attach(self)
	set_meta("peer_id", peer_id)
	# authority = 该玩家的 peer：自己控制移动/输入，其他人接收同步
	set_multiplayer_authority(peer_id)
	skills = PlayerSkills.new()
	skills.name = "PlayerSkills"
	add_child(skills)
	_setup_synchronizer()
	health.died.connect(_on_died)
	health.damaged.connect(func(amount): EventBus.player_damaged.emit(amount))
	health.died.connect(func(): EventBus.player_died.emit())
	inventory.equipment_changed.connect(_on_equipment_changed)
	add_to_group("player")
	_setup_sprite_frames()
	_on_equipment_changed("")

func _setup_synchronizer() -> void:
	# 多人下：远程玩家头顶显示名字标签
	if not is_multiplayer_authority():
		var name_lbl := Label.new()
		name_lbl.text = display_name + " #%d" % peer_id
		name_lbl.position = Vector2(-30, -40)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
		name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		add_child(name_lbl)

	if Network.is_singleplayer():
		return
	_sync = MultiplayerSynchronizer.new()
	_sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	# 同步路径：相对于挂载点（Player）
	cfg.add_property(NodePath(":global_position"))
	cfg.property_set_replication_mode(NodePath(":global_position"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	cfg.add_property(NodePath(":_sync_anim"))
	cfg.property_set_replication_mode(NodePath(":_sync_anim"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	cfg.add_property(NodePath("HealthComponent:current_health"))
	cfg.property_set_replication_mode(NodePath("HealthComponent:current_health"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	_sync.replication_config = cfg
	add_child(_sync)


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
	# 仅 authority（拥有该玩家的 peer）跑物理；其他人通过 sync 接收位置
	if not is_multiplayer_authority():
		return
	if _is_dead:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
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
		_sync_anim = anim
		visual.play(anim)
	elif not visual.is_playing():
		visual.play(anim)

# 远程同步动画：非 authority 端从 _sync_anim 收到更新后切换动画
func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		return
	if _sync_anim != _last_anim:
		_last_anim = _sync_anim
		if visual.sprite_frames and visual.sprite_frames.has_animation(_sync_anim):
			visual.play(_sync_anim)


func _unhandled_input(event: InputEvent) -> void:
	# 只有 local（authority）玩家响应输入
	if not is_multiplayer_authority():
		return
	if _is_dead:
		return
	# 数字键 1-9 直接选 hotbar 槽位
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode
		if code >= KEY_1 and code <= KEY_9:
			PlayerActions.request_select_hotbar(code - KEY_1)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_click_target = get_global_mouse_position()
		_click_moving = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		PlayerActions.request_interact()
	elif event.is_action_pressed("use_item"):
		PlayerActions.request_use_selected_item()
	elif event.is_action_pressed("attack"):
		PlayerActions.request_attack()
	elif OS.get_name() == "Android" and event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var half_w := get_viewport().get_visible_rect().size.x * 0.5
			if touch.position.x >= half_w:
				_click_target = get_canvas_transform().affine_inverse() * touch.position
				_click_moving = true
				get_viewport().set_input_as_handled()


# 由 PlayerActions 在 server 上调用（单机时也走相同路径）。
func do_interact() -> void:
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


func do_use_selected_item() -> void:
	var item := inventory.get_selected_item()
	if not item:
		return
	if item.heal_amount > 0.0 and health.current_health < health.max_health:
		health.heal(item.heal_amount)
		inventory.remove_item(item, 1)
		EventBus.item_used.emit(item)


func do_attack() -> void:
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

	var base_damage := ATTACK_DAMAGE + inventory.total_damage_bonus()
	var hit_any := false
	for body in attack_area.get_overlapping_bodies():
		if body is Creature:
			var creature := body as Creature
			var is_crit := randf() < CRIT_CHANCE
			var dmg: float = base_damage * (CRIT_MULT if is_crit else 1.0)
			creature.take_damage_from(self, dmg)
			var kb_dir := (creature.global_position - global_position).normalized()
			creature.velocity += kb_dir * KNOCKBACK_FORCE * (1.5 if is_crit else 1.0)
			DamageNumber.spawn(get_parent(), creature.global_position + Vector2(0, -16), dmg, is_crit)
			hit_any = true
	if hit_any:
		_on_hit_landed()


func _flash_attack() -> void:
	visual.modulate = Color(1.5, 1.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not _is_dead:
		visual.modulate = Color.WHITE

func _on_hit_landed() -> void:
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	if _combo_count >= 2:
		EventBus.combo_hit.emit(_combo_count)
	_hit_stop()

func _hit_stop() -> void:
	Engine.time_scale = HIT_STOP_SCALE
	# ignore_time_scale=true 让 timer 按真实时间走，不受减速影响
	await get_tree().create_timer(HIT_STOP_DURATION, true, false, true).timeout
	Engine.time_scale = 1.0


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
