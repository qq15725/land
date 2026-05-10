extends Node

const VERSION := "v0.1.0"

enum State { PLAYING, PAUSED, DEAD }

var state: State = State.PLAYING
var current_save_slot: int = 0
var world_type: String = "random"   # "random" | "preset"

func pause() -> void:
	state = State.PAUSED
	get_tree().paused = true

func resume() -> void:
	state = State.PLAYING
	get_tree().paused = false
