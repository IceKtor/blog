extends Node
## Game — состояние мира: локации, растения, энергия, отношения с жителями, мельница, шахта.

const Maps = preload("res://scripts/maps.gd")

signal energy_changed(value: float)
signal water_changed(value: int)
signal notify(icon: Texture2D, text: String)
signal relationship_changed(npc: String)
signal bundles_changed

const MAX_ENERGY := 100.0
const CAN_SIZE := 40
const FORAGE := [["wild_onion", "daffodil"], ["blackberry", "chamomile"], ["mushroom", "hazelnut"], ["winter_root", "holly"]]
const SCHEDULES := {
	"timofey": [[9, 17, "village", Rect2i(4, 9, 8, 3)]],
	"marfa": [[8, 20, "village", Rect2i(25, 9, 9, 3)]],
	"anna": [[8, 12, "village", Rect2i(3, 25, 10, 2)], [12, 19, "village", Rect2i(14, 12, 12, 6)]],
	"ilya": [[6, 18, "lake", Rect2i(21, 5, 10, 3)], [18, 22, "village", Rect2i(14, 12, 12, 6)]],
}

var locations := {}
var current_loc := "house"
var energy := MAX_ENERGY
var can_water := CAN_SIZE
var relationships := {}
var bundle_progress := {}
var mill_fixed := false
var mine_max := 0
var flags := {}
var scene: Node = null      # текущая игровая сцена (game.gd)
var _pause := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_paused() -> bool:
	return _pause > 0 or scene == null


func push_pause() -> void:
	_pause += 1


func pop_pause() -> void:
	_pause = maxi(0, _pause - 1)


func reset_pause() -> void:
	_pause = 0


# ------------------------------------------------------------------ новая игра
func new_game() -> void:
	locations.clear()
	current_loc = "house"
	energy = MAX_ENERGY
	can_water = CAN_SIZE
	mill_fixed = false
	mine_max = 0
	flags = {}
	relationships.clear()
	for n in Db.NPC_IDS:
		relationships[n] = {"points": 0, "talk_day": -1, "gift_day": -1}
	bundle_progress.clear()
	for b in Db.bundles:
		bundle_progress[b["id"]] = {}
	GameClock.reset()
	Inventory.clear()
	for id in ["hoe", "can", "axe", "pickaxe", "rod"]:
		Inventory.add(id, 1)
	Inventory.add("seed_radish", 15)
	Economy.money = 500
	Economy.shipping.clear()
	_spawn_forage()


func get_loc(name: String) -> Dictionary:
	if not locations.has(name):
		locations[name] = Maps.generate(name)
	return locations[name]


# ------------------------------------------------------------------ энергия и лейка
func spend(e: float) -> bool:
	if energy <= 0.0:
		notify.emit(null, "Нет сил… Поешь или ложись спать.")
		Audio.sfx("error")
		return false
	energy = maxf(0.0, energy - e)
	energy_changed.emit(energy)
	if energy <= 15.0 and energy + e > 15.0:
		notify.emit(null, "Ты устаёшь. Пора отдохнуть.")
	return true


func restore(e: float) -> void:
	energy = minf(MAX_ENERGY, energy + e)
	energy_changed.emit(energy)


func refill_can() -> void:
	can_water = CAN_SIZE
	water_changed.emit(can_water)


func use_water() -> bool:
	if can_water <= 0:
		notify.emit(null, "Лейка пуста. Наполни её у воды.")
		Audio.sfx("error")
		return false
	can_water -= 1
	water_changed.emit(can_water)
	return true


func give(id: String, n: int = 1) -> bool:
	var left := Inventory.add(id, n)
	if left < n:
		notify.emit(Db.icon(id), "+%d %s" % [n - left, Db.item_name(id)])
		Audio.sfx("pickup")
	if left > 0:
		notify.emit(null, "Рюкзак полон!")
		return false
	return true


# ------------------------------------------------------------------ жители
func npc_slot(npc: String):
	var h := GameClock.hour()
	for s in SCHEDULES.get(npc, []):
		if h >= s[0] and h < s[1]:
			return s
	return null


func points(npc: String) -> int:
	return int(relationships.get(npc, {}).get("points", 0))


func hearts(npc: String) -> int:
	return points(npc) / 100


func _add_points(npc: String, v: int) -> void:
	var r: Dictionary = relationships[npc]
	r["points"] = clampi(int(r["points"]) + v, 0, 1000)
	relationship_changed.emit(npc)


func talk(npc: String) -> String:
	var d: Dictionary = Db.npcs[npc]
	var r: Dictionary = relationships[npc]
	if int(r["talk_day"]) != GameClock.abs_day():
		r["talk_day"] = GameClock.abs_day()
		_add_points(npc, 10)
	var lines: Dictionary = d["lines"]
	var pool: Array = lines["default"].duplicate()
	pool += lines.get(GameClock.season_key(), [])
	pool += lines.get(GameClock.season_key(), [])
	if hearts(npc) >= 4:
		pool += lines.get("hearts_4", [])
	if hearts(npc) >= 8:
		pool += lines.get("hearts_8", [])
	return pool[randi() % pool.size()]


func gifted_today(npc: String) -> bool:
	return int(relationships[npc]["gift_day"]) == GameClock.abs_day()


## Подарок: любимый +45, нейтральный +20, нелюбимый −20. Один раз в день.
func gift(npc: String, id: String) -> String:
	var d: Dictionary = Db.npcs[npc]
	if gifted_today(npc):
		return ""
	relationships[npc]["gift_day"] = GameClock.abs_day()
	var kind := "neutral"
	if id in d.get("loves", []):
		kind = "love"
		_add_points(npc, 45)
	elif id in d.get("hates", []):
		kind = "hate"
		_add_points(npc, -20)
	else:
		_add_points(npc, 20)
	return kind


# ------------------------------------------------------------------ мельница
func bundle_have(bid: String, item: String) -> int:
	return int(bundle_progress.get(bid, {}).get(item, 0))


func bundle_done(b: Dictionary) -> bool:
	for item in b["need"]:
		if bundle_have(b["id"], item) < int(b["need"][item]):
			return false
	return true


## Отдаёт всё подходящее из инвентаря в набор. Возвращает true, если набор завершён этим действием.
func donate(b: Dictionary) -> bool:
	if bundle_done(b):
		return false
	var given := false
	for item in b["need"]:
		var need: int = int(b["need"][item]) - bundle_have(b["id"], item)
		var k := mini(need, Inventory.count(item))
		if k > 0:
			Inventory.remove(item, k)
			bundle_progress[b["id"]][item] = bundle_have(b["id"], item) + k
			given = true
	if given:
		Audio.sfx("pickup")
	bundles_changed.emit()
	if bundle_done(b):
		Economy.add_money(int(b.get("reward_money", 0)))
		for id in b.get("reward", {}):
			give(id, int(b["reward"][id]))
		Audio.sfx("catch")
		var all_done := true
		for bb in Db.bundles:
			if not bundle_done(bb):
				all_done = false
		if all_done and not mill_fixed:
			mill_fixed = true
			_add_points("marfa", 250)
		return true
	return false


# ------------------------------------------------------------------ ночная смена дня
## Вызывается при сне: продажа отгрузки, смена дня, рост растений. Возвращает отчёт.
func end_day(passed_out: bool) -> Dictionary:
	var report := Economy.process_shipping()
	GameClock.next_day()
	_night_update()
	energy = MAX_ENERGY * (0.5 if passed_out else 1.0)
	energy_changed.emit(energy)
	refill_can()
	report["passed_out"] = passed_out
	return report


func _night_update() -> void:
	for k in locations.keys():
		if String(k).begins_with("mine_"):
			locations.erase(k)
	var season := GameClock.season
	for name in locations:
		var st: Dictionary = locations[name]
		var w: int = st["w"]
		var tiles: Array = st["tiles"]
		var crops: Dictionary = st["crops"]
		for ck in crops:
			var c: Dictionary = crops[ck]
			var t := Maps.unkey(ck)
			if not c.get("dead", false):
				if tiles[t.y * w + t.x] == Maps.WET:
					c["age"] = int(c["age"]) + 1
				if int(Db.crops[c["type"]]["season"]) != season:
					c["dead"] = true
		for i in tiles.size():
			if tiles[i] == Maps.WET:
				tiles[i] = Maps.SOIL
			elif tiles[i] == Maps.SOIL:
				var t := Vector2i(i % w, i / w)
				if not crops.has(Maps.key(t)) and not st["objects"].has(Maps.key(t)) and randf() < 0.08:
					tiles[i] = Maps.GRASS
		for ok in st["objects"]:
			var o: Dictionary = st["objects"][ok]
			if o["t"] == "sprinkler":
				var t := Maps.unkey(ok)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = t + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < int(st["h"]) and tiles[n.y * w + n.x] == Maps.SOIL:
						tiles[n.y * w + n.x] = Maps.WET
			elif o["t"] == "stump" and name == "forest":
				o["age"] = int(o.get("age", 0)) + 1
				if o["age"] >= 6:
					st["objects"][ok] = {"t": "tree", "kind": "oak", "hp": 3}
	if locations.has("farm") and season != 3:
		_spawn_random("farm", "weed", 3, Rect2i(3, 10, 33, 18))
	_spawn_forage()


func _spawn_random(loc: String, t: String, n: int, area: Rect2i, extra := {}) -> void:
	var st := get_loc(loc)
	var w: int = st["w"]
	for i in n * 8:
		if n <= 0:
			break
		var p := Vector2i(randi_range(area.position.x, area.end.x - 1), randi_range(area.position.y, area.end.y - 1))
		var k := Maps.key(p)
		var tile: int = st["tiles"][p.y * w + p.x]
		if st["objects"].has(k) or st["crops"].has(k) or not tile in [Maps.GRASS, Maps.GRASS2, Maps.FLOWERS, Maps.FOREST]:
			continue
		var o := {"t": t}
		o.merge(extra)
		st["objects"][k] = o
		n -= 1


func _spawn_forage() -> void:
	var st := get_loc("forest")
	for k in st["objects"].keys():
		if st["objects"][k]["t"] == "forage":
			st["objects"].erase(k)
	var pool: Array = FORAGE[GameClock.season]
	for i in 9:
		_spawn_random("forest", "forage", 1, Rect2i(2, 2, 36, 28), {"item": pool[randi() % pool.size()]})


# ------------------------------------------------------------------ сохранение
func to_save() -> Dictionary:
	var locs := {}
	for k in locations:
		if not String(k).begins_with("mine_"):
			locs[k] = locations[k]
	return {"locations": locs, "energy": energy, "can": can_water, "relationships": relationships,
		"bundles": bundle_progress, "mill_fixed": mill_fixed, "mine_max": mine_max, "flags": flags}


func from_save(d: Dictionary) -> void:
	new_game_state_only()
	var locs: Dictionary = d.get("locations", {})
	for k in locs:
		var st: Dictionary = locs[k]
		var tiles := []
		for v in st["tiles"]:
			tiles.append(int(v))
		var crops := {}
		for ck in st.get("crops", {}):
			var c: Dictionary = st["crops"][ck]
			crops[ck] = {"type": str(c["type"]), "age": int(c["age"]), "dead": bool(c.get("dead", false))}
		var objs := {}
		for ok in st.get("objects", {}):
			objs[ok] = _fix_numbers(st["objects"][ok])
		locations[k] = {"w": int(st["w"]), "h": int(st["h"]), "tiles": tiles, "objects": objs, "crops": crops}
	energy = float(d.get("energy", MAX_ENERGY))
	can_water = int(d.get("can", CAN_SIZE))
	for n in Db.NPC_IDS:
		var r: Dictionary = d.get("relationships", {}).get(n, {})
		relationships[n] = {"points": int(r.get("points", 0)), "talk_day": int(r.get("talk_day", -1)), "gift_day": int(r.get("gift_day", -1))}
	for b in Db.bundles:
		var bp: Dictionary = d.get("bundles", {}).get(b["id"], {})
		bundle_progress[b["id"]] = {}
		for item in bp:
			bundle_progress[b["id"]][item] = int(bp[item])
	mill_fixed = bool(d.get("mill_fixed", false))
	mine_max = int(d.get("mine_max", 0))
	flags = d.get("flags", {})
	current_loc = "house"


func new_game_state_only() -> void:
	locations.clear()
	relationships.clear()
	bundle_progress.clear()


func _fix_numbers(v):
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _fix_numbers(v[k])
		return o
	if v is Array:
		var a := []
		for x in v:
			a.append(_fix_numbers(x))
		return a
	if v is float and v == floorf(v):
		return int(v)
	return v
