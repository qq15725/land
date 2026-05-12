class_name TradingPost
extends BuildingBase

var _activated: bool = false

func interact(_player: Player) -> void:
	if not _activated:
		_activated = true
		TradeSystem.activate(self)

func get_save_state() -> Dictionary:
	return {"activated": _activated}

func load_save_state(state: Dictionary) -> void:
	_activated = bool(state.get("activated", false))
	if _activated:
		TradeSystem.activate(self)
