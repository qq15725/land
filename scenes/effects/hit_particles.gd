class_name HitParticles
extends CPUParticles2D

func _ready() -> void:
	emitting = false
	amount = 8
	lifetime = 0.4
	one_shot = true
	explosiveness = 0.9
	direction = Vector2(0, -1)
	spread = 60.0
	gravity = Vector2(0, 200)
	initial_velocity_min = 40.0
	initial_velocity_max = 90.0
	scale_amount_min = 2.0
	scale_amount_max = 4.0

func burst(color: Color = Color.WHITE) -> void:
	self.color = color
	emitting = true
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()

static func spawn(parent: Node, pos: Vector2, color: Color = Color.WHITE) -> void:
	var p := HitParticles.new()
	parent.add_child(p)
	p.global_position = pos
	p.burst(color)
