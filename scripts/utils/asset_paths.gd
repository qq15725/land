class_name AssetPaths
extends RefCounted

# 资源路径约定。所有"按 id 找文件"的逻辑统一走这里。
# JSON 数据可显式 override，否则按约定路径自动拼接。
# 文件缺失时由调用方自行回退到占位（如 _make_color_icon）。

# ─── 路径模板 ──────────────────────────────────────────────────────────

static func creature_sprite(id: String) -> String:
	return "res://assets/creatures/%s.png" % id

static func animal_sprite(id: String) -> String:
	return "res://assets/animals/%s.png" % id

static func building_sprite(id: String) -> String:
	return "res://assets/sprites/buildings/%s.png" % id

static func resource_sprite(id: String) -> String:
	return "res://assets/resources/%s.png" % id

static func character_sprite(id: String) -> String:
	return "res://assets/sprites/characters/%s.png" % id

static func item_icon(id: String) -> String:
	return "res://assets/sprites/items/icons/%s.png" % id

static func skill_icon(id: String) -> String:
	return "res://assets/sprites/skills/%s.png" % id

static func vfx_scene(id: String) -> String:
	return "res://scenes/vfx/%s.tscn" % id

static func projectile_scene(id: String) -> String:
	return "res://scenes/effects/%s.tscn" % id

# ─── 通用 resolve：JSON override 优先 ──────────────────────────────────

static func resolve(override: String, default_fn: Callable, id: String) -> String:
	if not override.is_empty():
		return override
	return default_fn.call(id)
