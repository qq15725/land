extends Node

# 稀有事件：流星雨 + 神秘旅人。
# 每晚 night_started 时按概率触发；同夜最多一种事件。

signal meteor_shower_started
signal mystery_traveler_arrived

const METEOR_CHANCE := 0.12          # 12%
const TRAVELER_CHANCE := 0.10        # 10%（与流星雨互斥）
const METEOR_COUNT_MIN := 5
const METEOR_COUNT_MAX := 9
const METEOR_RADIUS := 360.0
const METEOR_MIN_DIST := 120.0
const TRAVELER_DIST := 200.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	TimeSystem.night_started.connect(_on_night)

func _on_night(_d: int) -> void:
	var roll := _rng.randf()
	if roll < METEOR_CHANCE:
		call_deferred("trigger_meteor_shower")
	elif roll < METEOR_CHANCE + TRAVELER_CHANCE:
		call_deferred("trigger_mystery_traveler")

func trigger_meteor_shower() -> void:
	var world := _world()
	if world == null:
		return
	var player := _local_player(world)
	if player == null:
		return
	var layer := world.get_node_or_null("YSortLayer") as Node2D
	if layer == null:
		return
	var count := _rng.randi_range(METEOR_COUNT_MIN, METEOR_COUNT_MAX)
	var ResourceScene: PackedScene = load("res://scenes/world/resource.tscn")
	for i in count:
		var pos := player.global_position + _random_ring(METEOR_MIN_DIST, METEOR_RADIUS)
		var node: ResourceNode = ResourceScene.instantiate()
		node.resource_id = "meteorite"
		node.position = pos
		layer.add_child(node)
	meteor_shower_started.emit()
	_announce("🌠 流星雨！附近出现陨石。")

func trigger_mystery_traveler() -> void:
	var world := _world()
	if world == null:
		return
	var player := _local_player(world)
	if player == null:
		return
	var data: MerchantData = null
	for m in ItemDatabase.get_all_merchants():
		if (m as MerchantData).id == "mystery_traveler":
			data = m
			break
	if data == null:
		return
	var MerchantScene: PackedScene = load("res://scenes/entities/merchant/merchant.tscn")
	var node: Node2D = MerchantScene.instantiate()
	var pos := player.global_position + _random_ring(TRAVELER_DIST, TRAVELER_DIST + 80.0)
	node.setup(data, pos)
	world.get_node("YSortLayer").add_child(node)
	mystery_traveler_arrived.emit()
	_announce("✨ 神秘旅人出现在附近...")

func _random_ring(min_d: float, max_d: float) -> Vector2:
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(min_d, max_d)
	return Vector2(cos(a), sin(a)) * r

func _world() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for w in tree.get_nodes_in_group("world"):
		return w
	return null

func _local_player(_world: Node) -> Player:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for p in tree.get_nodes_in_group("player"):
		var pl := p as Player
		if pl.peer_id == Network.local_peer_id():
			return pl
	return null

func _announce(msg: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for n in tree.get_nodes_in_group("hud"):
		if n.has_method("show_toast"):
			n.show_toast(msg, 4.0)
			return
	# fallback: 找 HUD 节点
	var root := tree.current_scene
	if root:
		var hud := root.find_child("HUD", true, false)
		if hud == null:
			# HUD 是 scene 顶节点，try class
			for child in root.get_children():
				if child is CanvasLayer:
					for c in child.get_children():
						if c.has_method("show_toast"):
							c.show_toast(msg, 4.0)
							return
