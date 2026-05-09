class_name MerchantData

var id: String = ""
var display_name: String = "商人"
var color: Color = Color(0.4, 0.6, 0.9)
var visit_interval: float = 180.0
var stay_duration: float = 90.0
var trades: Array = []
# trades 元素: {give_item_id, give_amount, receive_item_id, receive_amount, give_item: ItemData, receive_item: ItemData}
