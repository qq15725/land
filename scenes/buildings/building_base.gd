class_name BuildingBase
extends StaticBody2D

@export var max_durability: float = 100.0

@onready var hint_label: Label = $HintLabel
@onready var interact_area: Area2D = $InteractArea

var durability: float

func _ready() -> void:
	durability = max_durability
	hint_label.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func interact(_player: Player) -> void:
	pass

func take_damage(amount: float) -> void:
	durability = maxf(0.0, durability - amount)
	if durability == 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hint_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		hint_label.hide()
