class_name FenceGate
extends FenceWood

var is_open: bool = false

func _ready() -> void:
	super._ready()

func interact(_player: Player) -> void:
	is_open = not is_open
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", is_open)
	if hint_label:
		hint_label.text = "[E] 关闸" if is_open else "[E] 开门"
	queue_redraw()

func _draw() -> void:
	var color := Color(0.65, 0.45, 0.22, 0.5) if is_open else Color(0.55, 0.38, 0.22)
	_draw_fence(color)

	# 在门中间画斜线表示可交互
	if not is_open:
		draw_line(Vector2(-5, -3), Vector2(5, 3), color.lightened(0.3), 1.5)
