extends Node

enum State { PLAYING, PAUSED, DEAD }

var state: State = State.PLAYING
var current_save_slot: int = 0

func pause() -> void:
	state = State.PAUSED
	get_tree().paused = true

func resume() -> void:
	state = State.PLAYING
	get_tree().paused = false
