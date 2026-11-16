extends Node
## Db — справочник: предметы, культуры, рыба, рецепты, жители. Загружается из data/*.json.

const SEASONS := ["Весна", "Лето", "Осень", "Зима"]
const SEASON_KEYS := ["spring", "summer", "fall", "winter"]
const WEEKDAYS := ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
const NPC_IDS := ["timofey", "marfa", "ilya", "anna"]

var items := {}
var crops := {}
var fish := {}
var recipes := []
var bundles := []
var npcs := {}
var _tex := {}
var _icons := {}


func _ready() -> void:
	items = _json("res://data/items.json")
	var frames: Dictionary = _json("res://data/item_frames.json")
	for id in items:
		items[id]["frame"] = int(frames.get(id, 0))
	crops = _json("res://data/crops.json")
	fish = _json("res://data/fish.json")
	recipes = _json("res://data/recipes.json")
	bundles = _json("res://data/bundles.json")
	for n in NPC_IDS:
		npcs[n] = _json("res://data/npcs/%s.json" % n)
	_setup_input()


func _json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Нет файла данных: " + path)
		return {}
	return JSON.parse_string(f.get_as_text())


func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/sprites/%s.png" % name)
	return _tex[name]


func icon(id: String) -> AtlasTexture:
	if not _icons.has(id):
		var a := AtlasTexture.new()
		a.atlas = tex("items")
		var f: int = item(id).get("frame", 0)
		a.region = Rect2((f % 8) * 16, (f / 8) * 16, 16, 16)
		_icons[id] = a
	return _icons[id]


func region(texname: String, r: Rect2) -> AtlasTexture:
	var key := "%s:%s" % [texname, r]
	if not _icons.has(key):
		var a := AtlasTexture.new()
		a.atlas = tex(texname)
		a.region = r
		_icons[key] = a
	return _icons[key]


func item(id: String) -> Dictionary:
	return items.get(id, {"name": id, "cat": "misc", "price": 0, "desc": ""})


func item_name(id: String) -> String:
	return item(id).get("name", id)


func is_tool(id: String) -> bool:
	return item(id).get("cat", "") == "tool"


func stackable(id: String) -> bool:
	return not is_tool(id)


func _setup_input() -> void:
	var keys := {
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"use": [KEY_SPACE, KEY_C], "interact": [KEY_E, KEY_X], "inventory": [KEY_TAB, KEY_I],
		"pause": [KEY_ESCAPE],
	}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
	var l := InputEventMouseButton.new()
	l.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("use", l)
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("interact", r)
	for i in 10:
		var a := "slot_%d" % i
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		var ev := InputEventKey.new()
		ev.physical_keycode = (KEY_1 + i) if i < 9 else KEY_0
		InputMap.action_add_event(a, ev)
