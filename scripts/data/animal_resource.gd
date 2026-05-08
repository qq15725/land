class_name AnimalResource
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var feed_item: ItemResource
@export var produce_item: ItemResource
@export var produce_amount: int = 1
@export var produce_time: float = 30.0
@export var wander_radius: float = 80.0
@export var color: Color = Color.WHITE
