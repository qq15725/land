class_name Well
extends BuildingBase

# 井：交互一次，加速半径内所有 farm_plot 生长 + 给玩家迅捷 buff。
# 内置 60s 冷却防止刷。

const WATER_RADIUS := 96.0
const COOLDOWN := 60.0
const TIMER_REDUCE := 8.0

var _cd_left: float = 0.0

func _ready() -> void:
	super._ready()
	if hint_label:
		hint_label.text = "[E] 取水"

func _process(delta: float) -> void:
	if _cd_left > 0.0:
		_cd_left -= delta

func interact(player: Player) -> void:
	if _cd_left > 0.0:
		if hint_label:
			hint_label.text = "井冷却中…%ds" % int(_cd_left)
		return
	_cd_left = COOLDOWN
	# 加速半径内的农田
	for fp in get_tree().get_nodes_in_group("farm_plot"):
		if (fp as Node2D).global_position.distance_to(global_position) <= WATER_RADIUS:
			_speed_up_plot(fp as FarmPlot)
	# 玩家获 swift
	if player and player.buffs:
		player.buffs.add_buff("swift")
	if hint_label:
		hint_label.text = "已浇水"

func _speed_up_plot(plot: FarmPlot) -> void:
	# 直接减少 _grow_timer（私有变量，用 set 反射）
	if "_grow_timer" in plot:
		plot._grow_timer = maxf(0.0, plot._grow_timer - TIMER_REDUCE)
