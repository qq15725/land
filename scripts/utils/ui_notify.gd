class_name UINotify

# 统一的 toast 通知入口：找到场景中的 HUD（hud 组）并显示一条提示。
# 替代各处重复的"遍历 hud group → 调 show_toast"样板。
static func toast(tree: SceneTree, msg: String, duration: float = 2.0) -> void:
	if tree == null:
		return
	for n in tree.get_nodes_in_group("hud"):
		if n.has_method("show_toast"):
			n.show_toast(msg, duration)
			return
