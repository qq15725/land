class_name Player
extends CharacterBody2D

const SPEED := 150.0
const COMBO_TIMEOUT := 1.5

const SPRITE_ID := "player"
const FRAME_W := 128
const FRAME_H := 256
const FRAME_COLS := 4
const ANIM_FPS := 12.0

# 2.5D 视觉增强参数
const VISUAL_BASE_Y := -16.0
const WALK_BOB_AMP := 1.2        # 走路 Y 轴起伏振幅
const WALK_BOB_FREQ := 12.0      # 走路起伏频率
const IDLE_FLOAT_AMP := 0.5
const IDLE_FLOAT_FREQ := 2.5
const SHADOW_ALPHA := 0.55
const CAM_SHAKE_DECAY := 8.0     # 攻击命中屏幕震动衰减速度

@onready var inventory: InventoryComponent = $InventoryComponent
@onready var health: HealthComponent = $HealthComponent
@onready var interaction_area: Area2D = $InteractionArea
@onready var visual: AnimatedSprite2D = $Visual
@onready var camera: Camera2D = $Camera2D

var _shadow: Node2D
var _bob_time: float = 0.0
var _is_moving: bool = false
var _cam_shake_amp: float = 0.0

var skills: PlayerSkills
var active_skills: PlayerActiveSkills
var mana: ManaComponent
var skill_executor: SkillExecutor
var anim_state: PlayerAnimState
var peer_id: int = Network.SERVER_PEER_ID
var display_name: String = "冒险者"

# 5 个技能槽：index 0 = J（基础攻击），1 = Q，2 = E，3 = R，4 = G
# 未来"技能装配"UI 写入此数组即可
var equipped_skills: Array = ["basic_swing", "triple_slash", "fireball", "whirlwind", ""]

# 显式同步：position / hp / velocity / current_anim
# 用 MultiplayerSynchronizer 自动 30Hz 广播
var _sync: MultiplayerSynchronizer
var _sync_anim: String = "walk_down"

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
	active_skills = PlayerActiveSkills.new()
	active_skills.name = "PlayerActiveSkills"
	add_child(active_skills)
	mana = ManaComponent.new()
	mana.name = "ManaComponent"
	add_child(mana)
	skill_executor = SkillExecutor.new()
	skill_executor.name = "SkillExecutor"
	add_child(skill_executor)
	anim_state = PlayerAnimState.new()
	anim_state.name = "AnimState"
	add_child(anim_state)
	_setup_synchronizer()
	_setup_shadow()
	_setup_camera()
	health.died.connect(_on_died)
	health.damaged.connect(func(amount): EventBus.player_damaged.emit(amount))
	health.died.connect(func(): EventBus.player_died.emit())
	health.damaged.connect(func(_a):
		_camera_shake(2.0)
		if anim_state:
			anim_state.play_state("hit", 0.25)
	)
	inventory.equipment_changed.connect(_on_equipment_changed)
	add_to_group("player")
	_setup_sprite_frames()
	_on_equipment_changed("")

# 脚下椭圆软阴影：Y-sort 不参与，z_index 低于 visual
func _setup_shadow() -> void:
	_shadow = Node2D.new()
	_shadow.name = "Shadow"
	_shadow.z_index = ZLayer.SHADOW
	_shadow.position = Vector2(0, -2)
	add_child(_shadow)
	move_child(_shadow, 0)
	# 用 Polygon2D 画椭圆（足够顺滑的近似多边形）
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	var rx := 11.0
	var ry := 4.5
	var n := 20
	for i in n:
		var a := float(i) / n * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	poly.polygon = pts
	poly.color = Color(0, 0, 0, SHADOW_ALPHA)
	_shadow.add_child(poly)

func _setup_camera() -> void:
	if not camera:
		return
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.08
	camera.drag_right_margin = 0.08
	camera.drag_top_margin = 0.08
	camera.drag_bottom_margin = 0.08

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
	var tex := load(AssetPaths.character_sprite(SPRITE_ID)) as Texture2D
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
	_update_bobbing(delta, move_dir)


func _update_animation(move_dir: Vector2) -> void:
	# 施法 / 受击 / 死亡锁定期间，不切换 walk 动画
	if anim_state and anim_state.is_locked():
		return
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

# 远程同步动画 + 摄像机震动衰减（每帧跑）
func _process(delta: float) -> void:
	# 摄像机抖动衰减（只对 authority 玩家有效，因为 camera 是 player 的子节点）
	if is_multiplayer_authority() and camera:
		if _cam_shake_amp > 0.01:
			camera.offset = Vector2(randf_range(-_cam_shake_amp, _cam_shake_amp), randf_range(-_cam_shake_amp, _cam_shake_amp))
			_cam_shake_amp = move_toward(_cam_shake_amp, 0.0, CAM_SHAKE_DECAY * delta)
		else:
			camera.offset = Vector2.ZERO

	if is_multiplayer_authority():
		return
	if _sync_anim != _last_anim:
		_last_anim = _sync_anim
		if visual.sprite_frames and visual.sprite_frames.has_animation(_sync_anim):
			visual.play(_sync_anim)

# 走路时身体 Y 轴 sin 浮动；静止时改慢呼吸
func _update_bobbing(delta: float, move_dir: Vector2) -> void:
	_bob_time += delta
	_is_moving = move_dir.length() > 0.01
	var y_off: float
	if _is_moving:
		y_off = sin(_bob_time * WALK_BOB_FREQ) * WALK_BOB_AMP
	else:
		y_off = sin(_bob_time * IDLE_FLOAT_FREQ) * IDLE_FLOAT_AMP
	visual.position.y = VISUAL_BASE_Y + y_off

func _camera_shake(amplitude: float) -> void:
	_cam_shake_amp = maxf(_cam_shake_amp, amplitude)


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
		_cast_equipped(0)
	elif event.is_action_pressed("skill_q"):
		_cast_equipped(1)
	elif event.is_action_pressed("skill_e"):
		_cast_equipped(2)
	elif event.is_action_pressed("skill_r"):
		_cast_equipped(3)
	elif event.is_action_pressed("skill_f2"):
		_cast_equipped(4)
	elif OS.get_name() == "Android" and event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var half_w := get_viewport().get_visible_rect().size.x * 0.5
			if touch.position.x >= half_w:
				_click_target = get_canvas_transform().affine_inverse() * touch.position
				_click_moving = true
				get_viewport().set_input_as_handled()


func _cast_equipped(slot: int) -> void:
	if slot < 0 or slot >= equipped_skills.size():
		return
	var sid: String = equipped_skills[slot]
	if sid.is_empty():
		return
	PlayerActions.request_cast_skill(sid, get_global_mouse_position())

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


func do_cast_skill(skill_id: String, target_pos: Vector2) -> void:
	var skill := ItemDatabase.get_active_skill(skill_id)
	if skill == null:
		return
	# 远程武器（弓）保留弹药消耗逻辑：当 skill 是弹道且玩家装备的是 ranged 武器时扣弹药
	var weapon := inventory.get_equipped("weapon")
	if skill.shape == "projectile" and weapon and weapon.ranged:
		var ammo_item := ItemDatabase.get_item(weapon.ammo_item_id) if not weapon.ammo_item_id.is_empty() else null
		if ammo_item == null or not inventory.has_item(ammo_item, 1):
			return
		inventory.remove_item(ammo_item, 1)
	if not active_skills.try_cast(skill, mana):
		return
	if anim_state and not skill.anim_state.is_empty():
		anim_state.play_state(skill.anim_state, skill.anim_duration)
	skill_executor.cast(skill, target_pos, self)

# 由 SkillExecutor 在每段命中后通知，处理 combo 等需要玩家上下文的状态
func on_skill_hit_landed(_skill: ActiveSkillData) -> void:
	_combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	if _combo_count >= 2:
		EventBus.combo_hit.emit(_combo_count)



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
