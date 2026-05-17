class_name Lamppost
extends BuildingBase

# 路灯：夜晚自动点亮 PointLight2D，给玩家提供照明氛围。
# Lamppost 没有交互，仅是装饰 + 光源。

@onready var _light: PointLight2D = $PointLight2D

func _ready() -> void:
	super._ready()
	if _light:
		_light.energy = 0.0

func _process(_delta: float) -> void:
	if _light == null:
		return
	var target := 1.2 if TimeSystem.is_night() else 0.0
	_light.energy = lerpf(_light.energy, target, 0.05)
