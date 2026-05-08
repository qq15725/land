class_name TradingPost
extends BuildingBase

var _activated: bool = false

func interact(_player: Player) -> void:
	if not _activated:
		_activated = true
		TradeSystem.activate(self)

func on_placed() -> void:
	pass
