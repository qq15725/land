extends Node2D

const TreeScene := preload("res://scenes/world/resource_nodes/tree_node.tscn")
const StoneScene := preload("res://scenes/world/resource_nodes/stone_node.tscn")

const RESOURCE_COUNT := 40
const SPAWN_RADIUS := 600.0
const MIN_SPAWN_DIST := 80.0

@onready var y_sort_layer: Node2D = $YSortLayer
@onready var inventory_label: Label = $DebugUI/InventoryLabel
@onready var player: Player = $YSortLayer/Player

func _ready() -> void:
	_scatter_resources()
	player.inventory.changed.connect(_update_debug)
	_update_debug()

func _scatter_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in RESOURCE_COUNT:
		var scene := TreeScene if rng.randf() > 0.35 else StoneScene
		var node: ResourceNode = scene.instantiate()
		node.position = _random_pos(rng)
		y_sort_layer.add_child(node)

func _random_pos(rng: RandomNumberGenerator) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(MIN_SPAWN_DIST, SPAWN_RADIUS)
	return Vector2(cos(angle), sin(angle)) * dist

func _update_debug() -> void:
	inventory_label.text = "背包：" + player.inventory.get_contents()
