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

func _ready() -> void:
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
	_grow_timer -= delta
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
			player.inventory.add_item(_current_crop.output_item, _current_crop.output_amount)
			HitParticles.spawn(get_parent(), global_position, Color(1.0, 0.85, 0.1))
			_current_crop = null
			_state = State.EMPTY
			_apply_state_visual()
			hint_label.text = "[E] 播种"

func _apply_state_visual() -> void:
	match _state:
		State.EMPTY:
			visual.modulate = Color.WHITE
		State.GROWING:
			visual.modulate = Color(0.7, 1.1, 0.6)
		State.READY:
			visual.modulate = Color(1.3, 1.15, 0.4)

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
	_state = s
	_apply_state_visual()
