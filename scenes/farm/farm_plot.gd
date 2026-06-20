class_name FarmPlot
extends Node2D

enum State { EMPTY, GROWING, READY }

@onready var visual: Sprite2D = $Visual
@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

var building_data: BuildingData = null
var _state: State = State.EMPTY
var _current_crop: CropData = null
var _grow_timer: float = 0.0
var _ready_marker: Label = null

func _ready() -> void:
	NetworkRegistry.attach(self)
	add_to_group("farm_plot")
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_apply_state_visual()

func setup_preview(data: BuildingData) -> void:
	building_data = data

func on_placed(data: BuildingData = null) -> void:
	setup_preview(data)

func _process(delta: float) -> void:
	if _state != State.GROWING:
		return
	_grow_timer -= delta * WeatherSystem.growth_multiplier() * FestivalSystem.growth_bonus()
	if _grow_timer <= 0.0:
		_state = State.READY
		_apply_state_visual()
		hint_label.text = "[E] 收获"

func interact(player: Player) -> void:
	match _state:
		State.EMPTY:
			var crop := _find_plantable_seed(player.inventory)
			if crop == null:
				hint_label.text = "没有种子"
				return
			if not TimeSystem.is_season_allowed(crop.allowed_seasons):
				hint_label.text = "不是 %s 的种植季节" % crop.display_name
				return
			player.inventory.remove_item(crop.seed_item, 1)
			_current_crop = crop
			_state = State.GROWING
			_grow_timer = crop.growth_time
			_apply_state_visual()
			hint_label.text = "生长中..."
		State.GROWING:
			pass
		State.READY:
			# 秋收节：收获 +50%
			var bonus_mul := 1.5 if FestivalSystem.is_active("autumn_harvest") else 1.0
			var harvest_amt: int = int(ceil(_current_crop.output_amount * bonus_mul))
			player.inventory.add_item(_current_crop.output_item, harvest_amt)
			HitParticles.spawn(get_parent(), global_position, Color(1.0, 0.85, 0.1))
			EventBus.crop_harvested.emit(_current_crop, NetworkRegistry.get_id(player))
			_current_crop = null
			_state = State.EMPTY
			_apply_state_visual()
			hint_label.text = "[E] 播种"

func _apply_state_visual() -> void:
	match _state:
		State.EMPTY:
			visual.modulate = Color.WHITE
			_set_ready_marker(false)
		State.GROWING:
			visual.modulate = Color(0.7, 1.1, 0.6)
			_set_ready_marker(false)
		State.READY:
			visual.modulate = Color(1.3, 1.15, 0.4)
			_set_ready_marker(true)

# 成熟提示：READY 时农田上方跳动的金色 ✦，远处也能一眼看到可收的作物。
func _set_ready_marker(show_it: bool) -> void:
	if show_it and _ready_marker == null:
		_ready_marker = BounceMarker.create(self, "✦", Color(1.0, 0.95, 0.3), -30.0)
	if _ready_marker:
		_ready_marker.visible = show_it

func _find_plantable_seed(inventory: InventoryComponent) -> CropData:
	for slot in inventory.slots:
		if slot.item == null:
			continue
		var crop := ItemDatabase.get_crop_for_seed(slot.item)
		if crop:
			return crop
	return null

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	match _state:
		State.EMPTY:
			hint_label.text = "[E] 播种"
		State.GROWING:
			hint_label.text = "生长中..."
		State.READY:
			hint_label.text = "[E] 收获"
	hint_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		hint_label.hide()

# ─── 自动化接口（抽取器/放入器调用，无需 player） ───
func is_ready() -> bool:
	return _state == State.READY

func is_empty() -> bool:
	return _state == State.EMPTY

func auto_harvest() -> Dictionary:
	if _state != State.READY or _current_crop == null:
		return {}
	var bonus_mul := 1.5 if FestivalSystem.is_active("autumn_harvest") else 1.0
	var amt: int = int(ceil(_current_crop.output_amount * bonus_mul))
	var item: ItemData = _current_crop.output_item
	EventBus.crop_harvested.emit(_current_crop, 0)
	_current_crop = null
	_state = State.EMPTY
	_apply_state_visual()
	return {"item": item, "amount": amt}

func auto_plant(seed_item: ItemData) -> bool:
	if _state != State.EMPTY:
		return false
	var crop := ItemDatabase.get_crop_for_seed(seed_item)
	if crop == null or not TimeSystem.is_season_allowed(crop.allowed_seasons):
		return false
	_current_crop = crop
	_state = State.GROWING
	_grow_timer = crop.growth_time
	_apply_state_visual()
	return true

func get_save_state() -> Dictionary:
	return {
		"state": _state,
		"crop_id": _current_crop.id if _current_crop else "",
		"grow_timer": _grow_timer,
	}

func load_save_state(data: Dictionary) -> void:
	var s: int = data.get("state", State.EMPTY)
	var crop_id: String = data.get("crop_id", "")
	_grow_timer = data.get("grow_timer", 0.0)
	_current_crop = ItemDatabase.get_crop_by_id(crop_id) if crop_id != "" else null
	_state = s as State
	_apply_state_visual()
