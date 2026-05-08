class_name FarmPlot
extends Node2D

enum State { EMPTY, GROWING, READY }

@onready var visual: Polygon2D = $Visual
@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

var _state: State = State.EMPTY
var _current_crop: CropResource = null
var _grow_timer: float = 0.0

func _ready() -> void:
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if _state != State.GROWING:
		return
	_grow_timer -= delta
	if _grow_timer <= 0.0:
		_state = State.READY
		visual.color = Color(1.0, 0.85, 0.1)
		hint_label.text = "[E] 收获"

func interact(player: Player) -> void:
	match _state:
		State.EMPTY:
			var crop := _find_plantable_seed(player.inventory)
			if crop:
				player.inventory.remove_item(crop.seed_item, 1)
				_current_crop = crop
				_state = State.GROWING
				_grow_timer = crop.growth_time
				visual.color = Color(0.3, 0.55, 0.25)
				hint_label.text = "生长中..."
			else:
				hint_label.text = "没有种子"
		State.GROWING:
			pass
		State.READY:
			player.inventory.add_item(_current_crop.output_item, _current_crop.output_amount)
			_current_crop = null
			_state = State.EMPTY
			visual.color = Color(0.45, 0.3, 0.15)
			hint_label.text = "[E] 播种"

func _find_plantable_seed(inventory: InventoryComponent) -> CropResource:
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
