class_name MerchantResource
extends Resource

@export var id: String = ""
@export var display_name: String = "商人"
@export var color: Color = Color(0.4, 0.6, 0.9)
@export var visit_interval: float = 180.0  # 每隔多少秒来访一次
@export var stay_duration: float = 90.0    # 停留时长
@export var trades: Array[TradeEntry] = []
