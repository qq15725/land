extends Node2D

const TreeScene := preload("res://scenes/world/resource_nodes/tree_node.tscn")
const StoneScene := preload("res://scenes/world/resource_nodes/stone_node.tscn")
const CreatureScene := preload("res://scenes/entities/creature/creature.tscn")
const HUDScene := preload("res://scenes/ui/hud.tscn")
const InventoryUIScene := preload("res://scenes/ui/inventory_ui.tscn")
const CraftingUIScene := preload("res://scenes/ui/crafting_ui.tscn")
const BuildMenuUIScene := preload("res://scenes/ui/build_menu_ui.tscn")
const StorageUIScene := preload("res://scenes/ui/storage_ui.tscn")

const RESOURCE_COUNT := 40
const SPAWN_RADIUS := 600.0
const MIN_SPAWN_DIST := 80.0
const CREATURE_SPAWN_RADIUS := 500.0
const CREATURE_MIN_DIST := 200.0

@onready var y_sort_layer: Node2D = $YSortLayer
@onready var player: Player = $YSortLayer/Player

var _build_preview: Node2D = null
var _hud: Control = null
var _day_overlay: ColorRect = null

var _slime_data: CreatureResource = preload("res://resources/creatures/slime.tres")
var _skeleton_data: CreatureResource = preload("res://resources/creatures/skeleton.tres")

func _ready() -> void:
	_setup_ui()
	_scatter_resources()
	BuildingSystem.build_mode_entered.connect(_on_build_mode_entered)
	BuildingSystem.build_mode_exited.connect(_on_build_mode_exited)
	BuildingSystem.building_placed.connect(_on_building_placed)
	TimeSystem.night_started.connect(_on_night_started)
	TimeSystem.day_started.connect(_on_day_started)

func _setup_ui() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)

	_day_overlay = ColorRect.new()
	_day_overlay.color = Color(0.0, 0.0, 0.1, 0.0)
	_day_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_day_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(_day_overlay)

	_hud = HUDScene.instantiate()
	hud_layer.add_child(_hud)
	_hud.setup(player.health, player.inventory)

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	var inventory_ui := InventoryUIScene.instantiate()
	ui_layer.add_child(inventory_ui)
	inventory_ui.setup(player.inventory)

	var crafting_ui := CraftingUIScene.instantiate()
	ui_layer.add_child(crafting_ui)
	crafting_ui.setup(player.inventory)

	var build_menu := BuildMenuUIScene.instantiate()
	ui_layer.add_child(build_menu)
	build_menu.setup(player.inventory)

	var storage_ui := StorageUIScene.instantiate()
	ui_layer.add_child(storage_ui)
	storage_ui.setup(player.inventory)

func _process(_delta: float) -> void:
	if _build_preview:
		_build_preview.global_position = get_global_mouse_position()
	_update_day_overlay()

func _update_day_overlay() -> void:
	if TimeSystem.is_night():
		var ratio := TimeSystem.get_phase_ratio()
		var alpha := 0.0
		if ratio < 0.15:
			alpha = ratio / 0.15 * 0.55
		elif ratio > 0.85:
			alpha = (1.0 - ratio) / 0.15 * 0.55
		else:
			alpha = 0.55
		_day_overlay.color = Color(0.0, 0.0, 0.12, alpha)
	else:
		_day_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if not BuildingSystem.is_building:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			BuildingSystem.place_building(get_global_mouse_position(), player.inventory)
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			BuildingSystem.exit_build_mode()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		BuildingSystem.exit_build_mode()
		get_viewport().set_input_as_handled()

func _on_build_mode_entered(building: BuildingResource) -> void:
	if building.scene == null:
		return
	_build_preview = building.scene.instantiate()
	_build_preview.modulate = Color(0.4, 1.0, 0.4, 0.55)
	for child in _build_preview.get_children():
		if child is CollisionShape2D or child is CollisionObject2D:
			child.set_deferred("disabled", true)
	y_sort_layer.add_child(_build_preview)

func _on_build_mode_exited() -> void:
	if _build_preview:
		_build_preview.queue_free()
		_build_preview = null

func _on_building_placed(building: BuildingResource, pos: Vector2) -> void:
	var node := building.scene.instantiate() as Node2D
	node.global_position = pos
	y_sort_layer.add_child(node)
	if node.has_method("on_placed"):
		node.on_placed()

func _on_night_started(_day: int) -> void:
	_spawn_night_creatures()

func _on_day_started(_day: int) -> void:
	pass

func _scatter_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in RESOURCE_COUNT:
		var scene := TreeScene if rng.randf() > 0.35 else StoneScene
		var node: ResourceNode = scene.instantiate()
		node.position = _random_pos(rng, MIN_SPAWN_DIST, SPAWN_RADIUS)
		y_sort_layer.add_child(node)

func _spawn_night_creatures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var count := rng.randi_range(3, 6)
	for i in count:
		var creature: Creature = CreatureScene.instantiate()
		creature.data = _slime_data if rng.randf() > 0.4 else _skeleton_data
		creature.position = _random_pos(rng, CREATURE_MIN_DIST, CREATURE_SPAWN_RADIUS)
		y_sort_layer.add_child(creature)

func _random_pos(rng: RandomNumberGenerator, min_dist: float, max_dist: float) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(min_dist, max_dist)
	return Vector2(cos(angle), sin(angle)) * dist
