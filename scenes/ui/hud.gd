extends Control

# HUD 按 docs/references/hud.png 分区，美术接入 docs/art/hud.md 中描述的各 png：
#   ① 左上    hud_charinfo.png        角色信息条（头像 + Lv + 3 条）
#   ② ③ ④ 顶部居中  hud_buff_slot / hud_envinfo / hud_event
#   ⑤ ⑥ 右上    hud_minimap + hud_coord + hud_quest_header + hud_quest_row
#   ⑦  底部居中  hud_hotbar + hud_hotbar_selected
#   ⑩  右下    hud_skillslot
#   ⑪  底部    hud_infoslot ×3
#   ⑫  屏幕边缘  hud_danger_edge
#
# 美术图作为 TextureRect 背景，内部元素用代码 absolute position 叠加。

const HOTBAR_SIZE := 9
const SKILL_SLOTS := 4
const ART := "res://assets/sprites/ui/"

# ─── 状态引用 ────────────────────────────────────────────────────────────

var _player: Node = null
var _inventory: InventoryComponent
var _health: HealthComponent

# 进度条字典：{bg, fill, label, max_w}
# 左上角色条：HP / MP / FP（经验条在底部 hotbar 上方，由 _hotbar_xp_bar 显示）
var _hp_bar: Dictionary = {}
var _mp_bar: Dictionary = {}
var _fp_bar: Dictionary = {}
var _hotbar_xp_bar: Dictionary = {}

# ① 角色信息
var _name_lbl: Label
var _level_lbl: Label

# ② Buff
var _buff_row: HBoxContainer

# ③ 环境
var _phase_icon: TextureRect
var _time_lbl: Label
var _weather_icon: TextureRect

# ④ 事件
var _event_panel: Control
var _event_lbl: Label

# ⑤ ⑥ 小地图 + 任务
var _coord_lbl: Label
var _minimap: Minimap
var _quest_box: VBoxContainer

# ⑦ Hotbar
var _hotbar_level_lbl: Label
var _hotbar_icons: Array[ItemIcon] = []
var _hotbar_selected_overlays: Array[NinePatchRect] = []

# ⑩ Skill —— 每格 {root, icon: TextureRect, cd_overlay: ColorRect, cd_lbl: Label, skill: ActiveSkillData}
# 4 个槽对应 player.equipped_skills 的 index 1..4（J=0 不在技能栏，由底部 hotbar 视觉之外的左下另存）
var _skill_slots: Array[Dictionary] = []

# ⑪ Bottom info
var _gold_lbl: Label
var _selected_icon: TextureRect
var _selected_lbl: Label
var _base_defense_lbl: Label

# ⑫ Danger edge
var _danger_edge: TextureRect
var _danger_t: float = 0.0
var _danger_active: bool = false

# Overlay (toast + 建造模式)
var _mode_label: Label
var _toast_label: Label
var _toast_timer: float = 0.0

# ─── 生命周期 ────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIStyle.theme

	_build_danger_edge()
	_build_char_info()
	_build_top_center()
	_build_top_right()
	_build_skill_bar()
	_build_bottom_info_row()
	_build_hotbar()
	_build_center_overlay()

func setup(health: HealthComponent, inventory: InventoryComponent) -> void:
	_health = health
	_inventory = inventory
	_player = inventory.get_parent()

	_set_bar(_hp_bar, health.current_health, health.max_health)
	health.health_changed.connect(func(cur, m): _set_bar(_hp_bar, cur, m))

	# MP 接通 ManaComponent
	if _player and _player is Player and (_player as Player).mana:
		var mana_c: ManaComponent = (_player as Player).mana
		_set_bar(_mp_bar, mana_c.current_mana, mana_c.max_mana)
		mana_c.mana_changed.connect(func(cur, m): _set_bar(_mp_bar, cur, m))

	# SP 接通 PlayerActiveSkills
	if _player is Player and (_player as Player).active_skills:
		var act: PlayerActiveSkills = (_player as Player).active_skills
		_base_defense_lbl.text = "SP %d" % act.skill_points
		var local_pid := NetworkRegistry.get_id(_player)
		EventBus.skill_points_changed.connect(func(pid, total):
			if pid == local_pid:
				_base_defense_lbl.text = "SP %d" % total
		)

	BuildingSystem.build_mode_entered.connect(func(_b): _mode_label.text = "[建造模式]  左键放置  右键/ESC取消")
	BuildingSystem.build_mode_exited.connect(func(): _mode_label.text = "")

	inventory.selection_changed.connect(func(_i): _refresh_hotbar(); _refresh_selected())
	inventory.changed.connect(func(): _refresh_hotbar(); _refresh_selected())
	inventory.gold_changed.connect(func(g): _gold_lbl.text = str(g))
	inventory.equipment_changed.connect(func(_t): _refresh_durability())
	EventBus.item_sold.connect(_on_item_sold)
	EventBus.skill_leveled_up.connect(func(_id, _lv): _refresh_xp())
	EventBus.combo_hit.connect(_on_combo_hit)

	_refresh_hotbar()
	_refresh_xp()
	_refresh_durability()
	# MP 由上方 mana_changed 接通；FP 系统未实现，固定占位 100/100
	if not (_player is Player and (_player as Player).mana):
		_set_bar(_mp_bar, 100, 100)
	_set_bar(_fp_bar, 100, 100)
	_gold_lbl.text = str(inventory.gold)
	_refresh_skill_bar()
	if _minimap and _player is Node2D:
		_minimap.setup(_player as Node2D)

# ─── ① 角色信息条 hud_charinfo.png 320×128 ──────────────────────────────

func _build_char_info() -> void:
	var tex := _texture(ART + "hud_charinfo.png", Vector2(320, 128))
	tex.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tex.position = Vector2(12, 12)
	add_child(tex)

	# 名字 + Lv（顶部空位）
	_name_lbl = Label.new()
	_name_lbl.text = "冒险者"
	_name_lbl.position = Vector2(132, 12)
	_name_lbl.size = Vector2(120, 20)
	_name_lbl.add_theme_font_size_override("font_size", 13)
	_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	tex.add_child(_name_lbl)

	_level_lbl = Label.new()
	_level_lbl.text = "Lv. 1"
	_level_lbl.position = Vector2(252, 12)
	_level_lbl.size = Vector2(54, 20)
	_level_lbl.add_theme_font_size_override("font_size", 12)
	_level_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tex.add_child(_level_lbl)

	# 3 条进度条：HP（红）/ MP（蓝）/ FP（橙）。坐标对应 hud_charinfo.png 底图凹陷槽位。
	# 经验条不在此处，只在底部 hotbar 上方显示。
	_hp_bar = _bar_overlay(tex, 130, 44, 174, 12, Color(0.92, 0.22, 0.22))
	_mp_bar = _bar_overlay(tex, 130, 66, 174, 12, Color(0.30, 0.55, 1.00))
	_fp_bar = _bar_overlay(tex, 130, 88, 174, 12, Color(1.00, 0.70, 0.20))

# ─── ② ③ ④ 顶部居中 ────────────────────────────────────────────────────

func _build_top_center() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_top = 12
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	# ② Buff 条容器（动态填充 56×56 单格）
	_buff_row = HBoxContainer.new()
	_buff_row.add_theme_constant_override("separation", 4)
	row.add_child(_buff_row)
	_set_buffs([])

	# ③ 环境信息条
	var env := _texture(ART + "hud_envinfo.png", Vector2(256, 56))
	row.add_child(env)

	_phase_icon = TextureRect.new()
	_phase_icon.position = Vector2(8, 12)
	_phase_icon.size = Vector2(32, 32)
	_phase_icon.texture = _weather_atlas_region(0)  # 太阳
	_phase_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_phase_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	env.add_child(_phase_icon)

	_time_lbl = Label.new()
	_time_lbl.text = "12:00"
	_time_lbl.position = Vector2(48, 12)
	_time_lbl.size = Vector2(160, 32)
	_time_lbl.add_theme_font_size_override("font_size", 14)
	_time_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	_time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	env.add_child(_time_lbl)

	_weather_icon = TextureRect.new()
	_weather_icon.position = Vector2(216, 12)
	_weather_icon.size = Vector2(32, 32)
	_weather_icon.texture = _weather_atlas_region(0)
	_weather_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weather_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	env.add_child(_weather_icon)

	# ④ 事件提示
	_event_panel = _texture(ART + "hud_event.png", Vector2(320, 56))
	_event_panel.visible = false
	row.add_child(_event_panel)

	_event_lbl = Label.new()
	_event_lbl.position = Vector2(48, 12)
	_event_lbl.size = Vector2(264, 32)
	_event_lbl.add_theme_font_size_override("font_size", 12)
	_event_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	_event_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_event_panel.add_child(_event_lbl)

# 提取 hud_weather.png 中第 i 个 32×32 块（0=太阳/晴, 1=水滴/雨）
func _weather_atlas_region(index: int) -> Texture2D:
	var sheet := load(ART + "hud_weather.png") as Texture2D
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(index * 32, 0, 32, 32)
	return atlas

func _set_buffs(buffs: Array) -> void:
	for c in _buff_row.get_children():
		c.queue_free()
	for b in buffs:
		var slot := _texture(ART + "hud_buff_slot.png", Vector2(56, 56))
		_buff_row.add_child(slot)
		# TODO: 在 slot 内放 32×32 buff 图标 + 24×8 倒计时条

func show_event(text: String) -> void:
	_event_lbl.text = text
	_event_panel.visible = not text.is_empty()

# ─── ⑤ ⑥ 右上：小地图 + 任务追踪 ─────────────────────────────────────────

func _build_top_right() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.position = Vector2(-204, 12)
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	# 顶部菜单按钮组：角色 / 地图 / 设置
	var menu_row := HBoxContainer.new()
	menu_row.alignment = BoxContainer.ALIGNMENT_END
	menu_row.add_theme_constant_override("separation", 6)
	menu_row.custom_minimum_size = Vector2(192, 44)
	col.add_child(menu_row)
	menu_row.add_child(_make_menu_btn("👤", "角色", _on_menu_inventory))
	menu_row.add_child(_make_menu_btn("🗺", "地图", _on_menu_map))
	menu_row.add_child(_make_menu_btn("⚙", "设置", _on_menu_settings))

	# ⑤ 小地图
	var map := _texture(ART + "hud_minimap.png", Vector2(192, 192))
	col.add_child(map)

	_minimap = Minimap.new()
	_minimap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.add_child(_minimap)

	# 坐标条
	var coord := _texture(ART + "hud_coord.png", Vector2(160, 24))
	coord.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(coord)
	_coord_lbl = Label.new()
	_coord_lbl.text = "0, 0"
	_coord_lbl.position = Vector2(8, 0)
	_coord_lbl.size = Vector2(144, 24)
	_coord_lbl.add_theme_font_size_override("font_size", 11)
	_coord_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	_coord_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coord_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coord.add_child(_coord_lbl)

	# 与坐标条之间留 6px 间距
	var quest_spacer := Control.new()
	quest_spacer.custom_minimum_size = Vector2(0, 6)
	col.add_child(quest_spacer)

	# ⑥ 任务追踪 header + rows
	var quest_col := VBoxContainer.new()
	quest_col.add_theme_constant_override("separation", 0)
	col.add_child(quest_col)

	var header := _texture(ART + "hud_quest_header.png", Vector2(256, 24))
	quest_col.add_child(header)
	var header_lbl := Label.new()
	header_lbl.text = "任务"
	header_lbl.position = Vector2(12, 0)
	header_lbl.size = Vector2(220, 24)
	header_lbl.add_theme_font_size_override("font_size", 11)
	header_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	header_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(header_lbl)

	_quest_box = VBoxContainer.new()
	_quest_box.add_theme_constant_override("separation", 0)
	quest_col.add_child(_quest_box)
	set_quests([])

func set_quests(quests: Array) -> void:
	for c in _quest_box.get_children():
		c.queue_free()
	if quests.is_empty():
		var empty_row := _texture(ART + "hud_quest_row.png", Vector2(256, 40))
		var empty_lbl := Label.new()
		empty_lbl.text = "(暂无任务)"
		empty_lbl.position = Vector2(40, 8)
		empty_lbl.size = Vector2(180, 24)
		empty_lbl.add_theme_font_size_override("font_size", 10)
		empty_lbl.modulate = Color(0.55, 0.55, 0.55)
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_row.add_child(empty_lbl)
		_quest_box.add_child(empty_row)
		return
	for q in quests:
		var row := _texture(ART + "hud_quest_row.png", Vector2(256, 40))
		var name_lbl := Label.new()
		name_lbl.text = q.get("name", "?")
		name_lbl.position = Vector2(40, 8)
		name_lbl.size = Vector2(168, 24)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_lbl)

		var prog_lbl := Label.new()
		prog_lbl.text = "%d/%d" % [q.get("cur", 0), q.get("goal", 1)]
		prog_lbl.position = Vector2(212, 8)
		prog_lbl.size = Vector2(40, 24)
		prog_lbl.add_theme_font_size_override("font_size", 11)
		prog_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		prog_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(prog_lbl)

		_quest_box.add_child(row)

# ─── ⑦ 快捷栏 hud_hotbar.png 640×128 ────────────────────────────────────

func _build_hotbar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)

	var tex := _texture(ART + "hud_hotbar.png", Vector2(640, 128))
	center.add_child(tex)

	# 经验条：反向遮罩。坐标对应 hud_hotbar.png 底图原画的绿条区域。
	_hotbar_xp_bar = _bar_overlay(tex, 28, 16, 584, 20, Color.GREEN)
	# 等级徽章位（中央，覆盖底图深色方块）
	var lvl_holder := ColorRect.new()
	lvl_holder.color = Color(0.06, 0.06, 0.08)
	lvl_holder.position = Vector2(296, 12)
	lvl_holder.size = Vector2(48, 32)
	tex.add_child(lvl_holder)
	_hotbar_level_lbl = Label.new()
	_hotbar_level_lbl.text = "1"
	_hotbar_level_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hotbar_level_lbl.add_theme_font_size_override("font_size", 18)
	_hotbar_level_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hotbar_level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hotbar_level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl_holder.add_child(_hotbar_level_lbl)

	# 9 格：从 x=24 起，每格 64×56，y=56
	const SLOT_X0 := 24
	const SLOT_W := 64
	const SLOT_Y := 56
	const SLOT_H := 56
	for i in HOTBAR_SIZE:
		var slot_root := Control.new()
		slot_root.position = Vector2(SLOT_X0 + i * SLOT_W, SLOT_Y)
		slot_root.size = Vector2(SLOT_W, SLOT_H)
		tex.add_child(slot_root)

		# 数字键标记（左下角）
		var key_lbl := Label.new()
		key_lbl.text = str(i + 1)
		key_lbl.position = Vector2(2, SLOT_H - 14)
		key_lbl.size = Vector2(14, 14)
		key_lbl.add_theme_font_size_override("font_size", 9)
		key_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		slot_root.add_child(key_lbl)

		# 物品图标（用 ItemIcon，但不显示背景槽）
		var icon := ItemIcon.new(false)
		icon.position = Vector2(8, 4)
		icon.size = Vector2(48, 48)
		icon.custom_minimum_size = Vector2(48, 48)
		_hotbar_icons.append(icon)
		slot_root.add_child(icon)

		# 选中态边框（NinePatch，叠在格子外延）
		var sel := NinePatchRect.new()
		sel.texture = load(ART + "hud_hotbar_selected.png")
		sel.position = Vector2(-4, -4)
		sel.size = Vector2(SLOT_W + 8, SLOT_H + 8)
		sel.patch_margin_left = 16
		sel.patch_margin_right = 16
		sel.patch_margin_top = 16
		sel.patch_margin_bottom = 16
		sel.visible = false
		sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hotbar_selected_overlays.append(sel)
		slot_root.add_child(sel)

func _refresh_hotbar() -> void:
	if not _inventory:
		return
	for i in HOTBAR_SIZE:
		var icon: ItemIcon = _hotbar_icons[i]
		var sel: NinePatchRect = _hotbar_selected_overlays[i]
		if i >= _inventory.slots.size():
			icon.clear()
			sel.visible = false
			continue
		var slot: Dictionary = _inventory.slots[i]
		if slot.item:
			icon.show_item(slot.item, slot.amount)
		else:
			icon.clear()
		sel.visible = i == _inventory.selected_slot

# 玩家总等级 = 4 个技能等级之和（从本地 player.skills 组件读取）
func _refresh_xp() -> void:
	var total_level := 0
	var total_into := 0
	var total_span := 0
	var total_xp := 0
	if _player and _player is Player and (_player as Player).skills:
		var ps: PlayerSkills = (_player as Player).skills
		for sd in SkillSystem.get_all_skills():
			var p: Dictionary = ps.get_progress(sd.id)
			total_level += int(p.get("level", 0))
			total_xp += int(p.get("xp", 0))
			total_into += int(p.get("into_level", 0))
			total_span += int(p.get("span", 1))
	var lv := maxi(1, total_level)
	_level_lbl.text = "Lv. %d" % lv
	_hotbar_level_lbl.text = str(lv)
	var ratio: float = float(total_into) / float(maxi(1, total_span))
	# 经验条只在底部 hotbar 上方显示，左上角色条不再显 xp
	_set_bar(_hotbar_xp_bar, ratio, 1.0, "%d xp" % total_xp)

# ─── ⑩ 技能栏 hud_skillslot.png 80×80 ───────────────────────────────────

func _build_skill_bar() -> void:
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.position = Vector2(-364, -104)
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	const KEYS := ["Q", "E", "R", "G"]
	for i in SKILL_SLOTS:
		var slot := _texture(ART + "hud_skillslot.png", Vector2(80, 80))
		box.add_child(slot)

		var key := Label.new()
		key.text = KEYS[i] if i < KEYS.size() else ""
		key.position = Vector2(8, 8)
		key.size = Vector2(16, 16)
		key.add_theme_font_size_override("font_size", 12)
		key.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
		key.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		key.add_theme_constant_override("shadow_offset_x", 1)
		key.add_theme_constant_override("shadow_offset_y", 1)
		slot.add_child(key)

		# 中央图标（绑定技能时填充，未绑定时显示"—"）
		var icon := TextureRect.new()
		icon.position = Vector2(16, 16)
		icon.size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.add_child(icon)

		var empty := Label.new()
		empty.text = "—"
		empty.modulate = Color(0.55, 0.55, 0.55)
		empty.add_theme_font_size_override("font_size", 24)
		empty.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		slot.add_child(empty)

		# 冷却遮罩 + 冷却数字（默认隐藏）
		var cd_overlay := ColorRect.new()
		cd_overlay.color = Color(0, 0, 0, 0.55)
		cd_overlay.position = Vector2(0, 0)
		cd_overlay.size = Vector2(80, 80)
		cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_overlay.visible = false
		slot.add_child(cd_overlay)

		var cd_lbl := Label.new()
		cd_lbl.position = Vector2(0, 28)
		cd_lbl.size = Vector2(80, 24)
		cd_lbl.add_theme_font_size_override("font_size", 16)
		cd_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		cd_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		cd_lbl.add_theme_constant_override("shadow_offset_x", 1)
		cd_lbl.add_theme_constant_override("shadow_offset_y", 1)
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_lbl.visible = false
		slot.add_child(cd_lbl)

		_skill_slots.append({
			"root": slot,
			"icon": icon,
			"empty": empty,
			"cd_overlay": cd_overlay,
			"cd_lbl": cd_lbl,
			"skill": null,
		})

func _update_skill_bar_state() -> void:
	if not (_player is Player):
		return
	var pl := _player as Player
	var act_skills: PlayerActiveSkills = pl.active_skills
	var mana_c: ManaComponent = pl.mana
	if act_skills == null:
		return
	for entry in _skill_slots:
		var sd: ActiveSkillData = entry.get("skill")
		var icon: TextureRect = entry["icon"]
		var cd_overlay: ColorRect = entry["cd_overlay"]
		var cd_lbl: Label = entry["cd_lbl"]
		if sd == null:
			cd_overlay.visible = false
			cd_lbl.visible = false
			icon.modulate = Color.WHITE
			continue
		var cd := act_skills.cooldown_remaining(sd.id)
		var locked := not act_skills.is_unlocked(sd)
		var mp_low := mana_c != null and mana_c.current_mana < sd.mp_cost
		if cd > 0.0:
			var ratio := clampf(cd / maxf(0.01, sd.cooldown), 0.0, 1.0)
			cd_overlay.visible = true
			cd_overlay.size = Vector2(80, 80 * ratio)
			cd_overlay.position = Vector2(0, 80 - 80 * ratio)
			cd_lbl.visible = true
			cd_lbl.text = "%.1f" % cd
			icon.modulate = Color(0.5, 0.5, 0.5)
		elif locked:
			cd_overlay.visible = true
			cd_overlay.size = Vector2(80, 80)
			cd_overlay.position = Vector2(0, 0)
			cd_lbl.visible = false
			icon.modulate = Color(0.3, 0.3, 0.3)
		elif mp_low:
			cd_overlay.visible = false
			cd_lbl.visible = false
			icon.modulate = Color(0.5, 0.5, 0.9)  # 蓝灰提示 MP 不足
		else:
			cd_overlay.visible = false
			cd_lbl.visible = false
			icon.modulate = Color.WHITE

func _refresh_skill_bar() -> void:
	var bindings: Array = []
	if _player is Player:
		var eq: Array = (_player as Player).equipped_skills
		# 跳过 index 0 (J 基础攻击)，技能栏只显示 1..4
		for i in range(1, eq.size()):
			bindings.append(eq[i])
	for i in SKILL_SLOTS:
		var entry: Dictionary = _skill_slots[i]
		var binding: String = bindings[i] if i < bindings.size() else ""
		if binding.is_empty():
			entry["skill"] = null
			(entry["icon"] as TextureRect).texture = null
			(entry["empty"] as Label).visible = true
			continue
		var sd: ActiveSkillData = ItemDatabase.get_active_skill(binding)
		entry["skill"] = sd
		if sd == null:
			(entry["empty"] as Label).visible = true
			continue
		(entry["icon"] as TextureRect).texture = ItemDatabase.get_icon_at_grid(sd.icon_grid)
		(entry["empty"] as Label).visible = false

# ─── ⑪ 底部信息行 hud_infoslot.png 192×48 ───────────────────────────────

func _build_bottom_info_row() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_bottom = -8
	row.offset_top = -56
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	# 资源/货币
	var coin := _texture(ART + "hud_infoslot.png", Vector2(192, 48))
	row.add_child(coin)
	var coin_icon := Label.new()
	coin_icon.text = "⛂"
	coin_icon.position = Vector2(12, 8)
	coin_icon.size = Vector2(32, 32)
	coin_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	coin_icon.add_theme_font_size_override("font_size", 18)
	coin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.add_child(coin_icon)
	_gold_lbl = Label.new()
	_gold_lbl.text = "0"
	_gold_lbl.position = Vector2(48, 8)
	_gold_lbl.size = Vector2(136, 32)
	_gold_lbl.add_theme_font_size_override("font_size", 14)
	_gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_gold_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.add_child(_gold_lbl)

	# 选中物品（图标 + 名字 + 数量）
	var sel := _texture(ART + "hud_infoslot.png", Vector2(192, 48))
	row.add_child(sel)
	_selected_icon = TextureRect.new()
	_selected_icon.position = Vector2(12, 8)
	_selected_icon.size = Vector2(32, 32)
	_selected_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_selected_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_selected_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sel.add_child(_selected_icon)
	_selected_lbl = Label.new()
	_selected_lbl.text = "—"
	_selected_lbl.position = Vector2(48, 8)
	_selected_lbl.size = Vector2(136, 32)
	_selected_lbl.add_theme_font_size_override("font_size", 12)
	_selected_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	_selected_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sel.add_child(_selected_lbl)

	# 技能点 SP
	var sp := _texture(ART + "hud_infoslot.png", Vector2(192, 48))
	row.add_child(sp)
	var sp_icon := Label.new()
	sp_icon.text = "★"
	sp_icon.position = Vector2(12, 8)
	sp_icon.size = Vector2(32, 32)
	sp_icon.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	sp_icon.add_theme_font_size_override("font_size", 18)
	sp_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp.add_child(sp_icon)
	_base_defense_lbl = Label.new()
	_base_defense_lbl.text = "SP 0"
	_base_defense_lbl.position = Vector2(48, 8)
	_base_defense_lbl.size = Vector2(136, 32)
	_base_defense_lbl.add_theme_font_size_override("font_size", 12)
	_base_defense_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.78))
	_base_defense_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp.add_child(_base_defense_lbl)

func _refresh_durability() -> void:
	# 兼容旧调用：刷新选中物品信息
	_refresh_selected()

func _refresh_selected() -> void:
	if not _inventory or not _selected_lbl:
		return
	var item: ItemData = _inventory.get_selected_item()
	if item == null:
		_selected_icon.texture = null
		_selected_lbl.text = "— 未选 —"
		return
	_selected_icon.texture = ItemDatabase.get_item_icon(item)
	var slot_idx: int = _inventory.selected_slot
	var amount: int = _inventory.slots[slot_idx].amount if slot_idx >= 0 and slot_idx < _inventory.slots.size() else 0
	_selected_lbl.text = "%s  ×%d" % [item.display_name, amount]

# ─── ⑫ 危险边框 hud_danger_edge.png ─────────────────────────────────────

func _build_danger_edge() -> void:
	_danger_edge = TextureRect.new()
	_danger_edge.texture = load(ART + "hud_danger_edge.png")
	_danger_edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_danger_edge.stretch_mode = TextureRect.STRETCH_SCALE
	_danger_edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_danger_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_danger_edge.modulate = Color(1, 1, 1, 0)
	add_child(_danger_edge)

func show_danger(active: bool) -> void:
	_danger_active = active

# ─── Center overlay：建造模式提示 + toast ──────────────────────────────

func _build_center_overlay() -> void:
	var top_box := VBoxContainer.new()
	top_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_box.offset_top = 80
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.add_theme_constant_override("separation", 4)
	add_child(top_box)

	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_font_size_override("font_size", 13)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(_mode_label)

	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.add_theme_font_size_override("font_size", 12)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.modulate = Color(1.0, 0.95, 0.7, 0.0)
	top_box.add_child(_toast_label)

# ─── 公共 helper ──────────────────────────────────────────────────────────

func _make_menu_btn(icon_text: String, tooltip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = icon_text
	b.tooltip_text = tooltip
	b.custom_minimum_size = Vector2(40, 40)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	return b

func _on_menu_inventory() -> void:
	# 模拟 "inventory" 动作（Tab 键），让 InventoryUI 自己处理打开/关闭切换
	var ev := InputEventAction.new()
	ev.action = "inventory"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_menu_map() -> void:
	show_toast("大地图尚未实现", 1.5)

func _on_menu_settings() -> void:
	# 模拟 ESC（打开暂停菜单），暂停菜单内含设置入口
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)

func _texture(path: String, fixed_size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = fixed_size
	t.size = fixed_size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

# 代码绘制圆角胶囊进度条。要求底图槽位是"空槽"（不画填充色），代码 fill
# 完全控制颜色。fill 宽度由 _set_bar() 按 ratio 动态调整。
func _bar_overlay(parent: Control, x: int, y: int, w: int, h: int, fill_color: Color) -> Dictionary:
	var radius: int = h / 2
	var fill := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	fill.add_theme_stylebox_override("panel", sb)
	fill.position = Vector2(x, y)
	fill.size = Vector2(w, h)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)

	var lbl := Label.new()
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)

	return {"fill": fill, "label": lbl, "max_w": w}

func _set_bar(bar: Dictionary, cur: float, maximum: float, label_text: String = "") -> void:
	if bar.is_empty():
		return
	var ratio: float = clampf(cur / maxf(0.01, maximum), 0.0, 1.0)
	var fill: Panel = bar["fill"]
	# Panel + 圆角 stylebox 在 size.x = 0 时仍会渲染左圆头，需要显式隐藏
	if ratio <= 0.001:
		fill.visible = false
	else:
		fill.visible = true
		fill.size.x = float(bar["max_w"]) * ratio
	if label_text.is_empty():
		(bar["label"] as Label).text = "%d/%d" % [int(cur), int(maximum)]
	else:
		(bar["label"] as Label).text = label_text

# ─── 事件 ─────────────────────────────────────────────────────────────────

func _on_item_sold(item: ItemData, amount: int, gold_received: int) -> void:
	show_toast("+%d G  (%s ×%d)" % [gold_received, item.display_name, amount], 1.6)

func _on_combo_hit(count: int) -> void:
	show_toast("%d  COMBO!" % count, 1.0)

func show_toast(text: String, duration: float = 2.0) -> void:
	_toast_label.text = text
	_toast_timer = duration
	_toast_label.modulate = Color(1.0, 0.95, 0.7, 1.0)

# ─── 主循环 ───────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# 环境信息
	var is_night := TimeSystem.is_night()
	_phase_icon.texture = _weather_atlas_region(1 if is_night else 0)  # 占位：用雨滴当夜晚
	var ratio := TimeSystem.get_phase_ratio()
	var hours: float
	if is_night:
		hours = fposmod(18.0 + ratio * 12.0, 24.0)
	else:
		hours = 6.0 + ratio * 12.0
	var hh := int(hours) % 24
	var mm := int(fposmod(hours * 60.0, 60.0))
	_time_lbl.text = "%02d:%02d  第%d天 %s" % [hh, mm, TimeSystem.current_day, TimeSystem.current_season_label()]

	# 坐标
	if _player and _player is Node2D:
		var p: Vector2 = (_player as Node2D).global_position
		_coord_lbl.text = "%d, %d" % [int(p.x), int(p.y)]

	# toast 渐隐
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast_label.modulate.a = clampf(_toast_timer, 0.0, 1.0)
		if _toast_timer <= 0.0:
			_toast_label.text = ""

	# 技能栏冷却 / MP 状态
	_update_skill_bar_state()

	# 危险边框呼吸
	if _danger_active:
		_danger_t += delta
		_danger_edge.modulate.a = 0.35 + 0.25 * sin(_danger_t * 3.0)
	else:
		_danger_edge.modulate.a = move_toward(_danger_edge.modulate.a, 0.0, delta * 1.5)
