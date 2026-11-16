extends RefCounted
## Описание и генерация карт локаций. Хабовая структура: ферма → деревня, лес, озеро, шахта.

const GRASS := 0
const GRASS2 := 1
const FLOWERS := 2
const PATH := 3
const SOIL := 4
const WET := 5
const SAND := 6
const FLOOR := 7
const WALL := 8
const CAVE := 9
const CAVE2 := 10
const CAVEWALL := 11
const DOCK := 12
const FOREST := 13
const PLAZA := 14
const VOID := 15
const BORDER := 16   # рисуется как лесная подстилка, но непроходим
const WATER := 20

const SOLID_TILES := [WALL, CAVEWALL, VOID, BORDER, WATER]
const OUTDOOR := ["farm", "village", "forest", "lake"]

const NAMES := {"farm": "Ферма", "village": "Деревня", "forest": "Лес", "lake": "Озеро", "house": "Дом", "mine": "Шахта"}

const SIZES := {"farm": Vector2i(40, 30), "village": Vector2i(40, 30), "forest": Vector2i(40, 32),
	"lake": Vector2i(40, 28), "house": Vector2i(12, 9), "mine": Vector2i(16, 12), "mine_level": Vector2i(26, 18)}


static func key(t: Vector2i) -> String:
	return "%d,%d" % [t.x, t.y]


static func unkey(k: String) -> Vector2i:
	var p := k.split(",")
	return Vector2i(int(p[0]), int(p[1]))


static func base_name(loc: String) -> String:
	return "mine" if loc.begins_with("mine") else loc


static func size_of(loc: String) -> Vector2i:
	if loc.begins_with("mine_"):
		return SIZES["mine_level"]
	return SIZES[base_name(loc)]


static func display_name(loc: String) -> String:
	if loc.begins_with("mine_"):
		return "Шахта, уровень %s" % loc.substr(5)
	return NAMES.get(loc, loc)


static func is_outdoor(loc: String) -> bool:
	return loc in OUTDOOR


# ------------------------------------------------------------------ постройки и мебель
## tex — имя спрайта, x,y,w,h — в тайлах, solid_from — с какого ряда постройка непроходима,
## doors — клетки взаимодействия с действием action.
static func structures(loc: String) -> Array:
	match loc:
		"farm":
			return [
				{"tex": "farmhouse", "x": 5, "y": 2, "w": 5, "h": 5, "solid_from": 2, "doors": [Vector2i(7, 6)], "action": "enter_house"},
				{"tex": "shipping_bin", "x": 11, "y": 5, "w": 2, "h": 2, "solid_from": 0, "doors": [Vector2i(11, 5), Vector2i(12, 5), Vector2i(11, 6), Vector2i(12, 6)], "action": "ship"},
				{"tex": "mine_entrance", "x": 30, "y": 0, "w": 4, "h": 4, "solid_from": 0, "doors": [Vector2i(31, 3), Vector2i(32, 3)], "action": "enter_mine"},
			]
		"village":
			return [
				{"tex": "shop", "x": 4, "y": 4, "w": 6, "h": 5, "solid_from": 2, "doors": [Vector2i(7, 8)], "action": "shop"},
				{"tex": "mill", "x": 28, "y": 2, "w": 5, "h": 7, "solid_from": 3, "doors": [Vector2i(30, 8)], "action": "mill"},
				{"tex": "school", "x": 4, "y": 18, "w": 6, "h": 6, "solid_from": 3, "doors": [Vector2i(7, 23)], "action": "school"},
				{"tex": "house_a", "x": 13, "y": 20, "w": 5, "h": 5, "solid_from": 2, "doors": [Vector2i(15, 24)], "action": "house_timofey"},
				{"tex": "house_b", "x": 23, "y": 20, "w": 5, "h": 5, "solid_from": 2, "doors": [Vector2i(25, 24)], "action": "house_ilya"},
				{"tex": "well", "x": 19, "y": 12, "w": 2, "h": 3, "solid_from": 2, "doors": [Vector2i(19, 14), Vector2i(20, 14)], "action": "well"},
				{"tex": "lamp", "x": 12, "y": 10, "w": 1, "h": 2, "solid_from": 1},
				{"tex": "lamp", "x": 27, "y": 10, "w": 1, "h": 2, "solid_from": 1},
				{"tex": "lamp", "x": 12, "y": 18, "w": 1, "h": 2, "solid_from": 1},
				{"tex": "lamp", "x": 27, "y": 18, "w": 1, "h": 2, "solid_from": 1},
				{"tex": "bench", "x": 15, "y": 17, "w": 2, "h": 1, "solid_from": 0},
				{"tex": "bench", "x": 23, "y": 17, "w": 2, "h": 1, "solid_from": 0},
				{"tex": "flowerbed", "x": 10, "y": 8, "w": 2, "h": 1, "solid_from": 0, "seasonal": true},
				{"tex": "flowerbed", "x": 2, "y": 8, "w": 2, "h": 1, "solid_from": 0, "seasonal": true},
				{"tex": "flowerbed", "x": 34, "y": 8, "w": 2, "h": 1, "solid_from": 0, "seasonal": true},
			]
		"house":
			return [
				{"tex": "bed", "x": 8, "y": 2, "w": 2, "h": 2, "solid_from": 0, "doors": [Vector2i(8, 2), Vector2i(9, 2), Vector2i(8, 3), Vector2i(9, 3)], "action": "sleep"},
				{"tex": "table", "x": 2, "y": 4, "w": 2, "h": 2, "solid_from": 0},
				{"tex": "stove", "x": 4, "y": 1, "w": 1, "h": 2, "solid_from": 1, "doors": [Vector2i(4, 2)], "action": "stove"},
			]
		"mine":
			return [{"tex": "lift", "x": 3, "y": 2, "w": 1, "h": 2, "solid_from": 1, "doors": [Vector2i(3, 3)], "action": "lift"}]
	return []


## Переходы: rect — зона в тайлах, при входе в которую игрок попадает в локацию to.
static func exits(loc: String) -> Array:
	match loc:
		"farm":
			return [
				{"rect": Rect2i(38, 13, 2, 3), "to": "village", "spawn": Vector2i(2, 14), "face": 2},
				{"rect": Rect2i(0, 18, 2, 3), "to": "forest", "spawn": Vector2i(37, 19), "face": 1},
				{"rect": Rect2i(18, 28, 3, 2), "to": "lake", "spawn": Vector2i(19, 2), "face": 0},
			]
		"village":
			return [{"rect": Rect2i(0, 13, 2, 3), "to": "farm", "spawn": Vector2i(37, 14), "face": 1}]
		"forest":
			return [{"rect": Rect2i(38, 18, 2, 3), "to": "farm", "spawn": Vector2i(2, 19), "face": 2}]
		"lake":
			return [{"rect": Rect2i(18, 0, 3, 2), "to": "farm", "spawn": Vector2i(19, 27), "face": 3}]
		"house":
			return [{"rect": Rect2i(5, 8, 2, 1), "to": "farm", "spawn": Vector2i(7, 7), "face": 0}]
		"mine":
			return [{"rect": Rect2i(7, 11, 2, 1), "to": "farm", "spawn": Vector2i(31, 4), "face": 0}]
	return []


static func music_for(loc: String) -> String:
	if loc.begins_with("mine"):
		return "music_mine"
	return "music_" + GameClock.season_key()


# ------------------------------------------------------------------ генерация
class Builder:
	var w: int
	var h: int
	var tiles := []
	var objects := {}
	var rng := RandomNumberGenerator.new()

	func _init(sz: Vector2i, seed_: int) -> void:
		w = sz.x
		h = sz.y
		rng.seed = seed_
		tiles.resize(w * h)
		tiles.fill(0)

	func inside(t: Vector2i) -> bool:
		return t.x >= 0 and t.y >= 0 and t.x < w and t.y < h

	func get_t(x: int, y: int) -> int:
		return tiles[y * w + x] if inside(Vector2i(x, y)) else 15

	func set_t(x: int, y: int, v: int) -> void:
		if inside(Vector2i(x, y)):
			tiles[y * w + x] = v

	func fill(r: Rect2i, v: int) -> void:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				set_t(x, y, v)

	func grass(r: Rect2i, flowers := 0.05) -> void:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var v := rng.randf()
				set_t(x, y, 2 if v < flowers else (1 if v < 0.3 else 0))

	func border(gaps: Array) -> void:
		for y in h:
			for x in w:
				if x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
					var open := false
					for g in gaps:
						if g.has_point(Vector2i(x, y)):
							open = true
					if open:
						set_t(x, y, 3)
					else:
						set_t(x, y, 16)
						if (x + y * 3) % 2 == 0 or x == 1 or y == 1 or x == w - 2 or y == h - 2:
							if rng.randf() < 0.75:
								objects[Vector2i(x, y)] = {"t": "btree", "kind": "pine" if rng.randf() < 0.6 else "oak"}

	func path_line(a: Vector2i, b: Vector2i) -> void:
		var p := a
		while p != b:
			set_t(p.x, p.y, 3)
			if p.x != b.x:
				p.x += signi(b.x - p.x)
			else:
				p.y += signi(b.y - p.y)
		set_t(b.x, b.y, 3)

	func ellipse(c: Vector2, r: Vector2, v: int) -> void:
		for y in h:
			for x in w:
				if pow((x - c.x) / r.x, 2) + pow((y - c.y) / r.y, 2) <= 1.0:
					set_t(x, y, v)

	func is_free(t: Vector2i, blocked: Dictionary) -> bool:
		if not inside(t) or objects.has(t) or blocked.has(t):
			return false
		var v := get_t(t.x, t.y)
		return v in [0, 1, 2, 13]

	func scatter(n: int, area: Rect2i, obj: Dictionary, blocked: Dictionary, spacing := 0) -> void:
		var tries := 0
		while n > 0 and tries < n * 40 + 200:
			tries += 1
			var t := Vector2i(rng.randi_range(area.position.x, area.end.x - 1), rng.randi_range(area.position.y, area.end.y - 1))
			if not is_free(t, blocked):
				continue
			var ok := true
			if spacing > 0:
				for dy in range(-spacing, spacing + 1):
					for dx in range(-spacing, spacing + 1):
						var o = objects.get(t + Vector2i(dx, dy))
						if o != null and o["t"] in ["tree", "btree"]:
							ok = false
			if not ok:
				continue
			objects[t] = obj.duplicate(true)
			n -= 1

	func state() -> Dictionary:
		var objs := {}
		for t in objects:
			objs["%d,%d" % [t.x, t.y]] = objects[t]
		return {"w": w, "h": h, "tiles": tiles, "objects": objs, "crops": {}}


static func _block_structures(b: Builder, loc: String) -> Dictionary:
	var blocked := {}
	for s in structures(loc):
		for y in range(s["y"] - 1, s["y"] + s["h"] + 1):
			for x in range(s["x"] - 1, s["x"] + s["w"] + 1):
				blocked[Vector2i(x, y)] = true
	return blocked


static func generate(loc: String) -> Dictionary:
	match loc:
		"farm": return _farm()
		"village": return _village()
		"forest": return _forest()
		"lake": return _lake()
		"house": return _house()
		"mine": return _mine_entrance()
	if loc.begins_with("mine_"):
		return _mine_level(int(loc.substr(5)))
	return _house()


static func _farm() -> Dictionary:
	var b := Builder.new(SIZES["farm"], 101)
	b.grass(Rect2i(0, 0, b.w, b.h), 0.04)
	b.border([Rect2i(38, 13, 2, 3), Rect2i(0, 18, 2, 3), Rect2i(18, 28, 3, 2), Rect2i(30, 0, 4, 4)])
	for x in range(30, 34):
		for y in range(0, 2):
			b.set_t(x, y, 16)
	b.path_line(Vector2i(7, 7), Vector2i(7, 9))
	b.path_line(Vector2i(7, 9), Vector2i(35, 9))
	b.path_line(Vector2i(35, 9), Vector2i(35, 14))
	b.path_line(Vector2i(35, 14), Vector2i(39, 14))
	b.path_line(Vector2i(31, 4), Vector2i(31, 9))
	b.path_line(Vector2i(19, 9), Vector2i(19, 29))
	b.path_line(Vector2i(0, 19), Vector2i(3, 19))
	b.path_line(Vector2i(11, 7), Vector2i(11, 8))
	b.ellipse(Vector2(32, 23), Vector2(3.4, 2.6), WATER)
	var blocked := _block_structures(b, "farm")
	for x in range(2, 17):
		for y in range(9, 16):
			blocked[Vector2i(x, y)] = true
	for y in range(19, 25):
		for x in range(27, 38):
			blocked[Vector2i(x, y)] = true
	var field := Rect2i(3, 10, 33, 18)
	b.scatter(12, field, {"t": "tree", "kind": "oak", "hp": 3}, blocked, 1)
	b.scatter(5, field, {"t": "stump", "hp": 2}, blocked)
	b.scatter(70, field, {"t": "weed"}, blocked)
	b.scatter(30, field, {"t": "stone"}, blocked)
	b.scatter(25, field, {"t": "twig"}, blocked)
	b.scatter(4, Rect2i(13, 2, 16, 6), {"t": "tree", "kind": "oak", "hp": 3}, blocked, 1)
	return b.state()


static func _village() -> Dictionary:
	var b := Builder.new(SIZES["village"], 202)
	b.grass(Rect2i(0, 0, b.w, b.h), 0.08)
	b.border([Rect2i(0, 13, 2, 3)])
	b.fill(Rect2i(13, 11, 15, 8), PLAZA)
	b.path_line(Vector2i(0, 14), Vector2i(13, 14))
	b.path_line(Vector2i(7, 9), Vector2i(7, 14))
	b.path_line(Vector2i(27, 11), Vector2i(30, 11))
	b.path_line(Vector2i(30, 9), Vector2i(30, 11))
	b.path_line(Vector2i(7, 24), Vector2i(7, 25))
	b.path_line(Vector2i(7, 25), Vector2i(27, 25))
	b.path_line(Vector2i(20, 18), Vector2i(20, 25))
	var blocked := _block_structures(b, "village")
	for y in range(9, 27):
		for x in range(2, 38):
			if b.get_t(x, y) in [PATH, PLAZA]:
				for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					blocked[Vector2i(x, y) + d] = true
	for t in [Vector2i(35, 4), Vector2i(36, 13), Vector2i(35, 24), Vector2i(2, 4), Vector2i(10, 27), Vector2i(31, 27), Vector2i(24, 4), Vector2i(17, 5)]:
		if b.is_free(t, {}):
			b.objects[t] = {"t": "btree", "kind": "oak"}
	b.scatter(10, Rect2i(2, 2, 36, 26), {"t": "bush"}, blocked)
	return b.state()


static func _forest() -> Dictionary:
	var b := Builder.new(SIZES["forest"], 303)
	for y in b.h:
		for x in b.w:
			b.set_t(x, y, FOREST if b.rng.randf() < 0.55 else (2 if b.rng.randf() < 0.05 else 0))
	b.border([Rect2i(38, 18, 2, 3)])
	b.path_line(Vector2i(39, 19), Vector2i(30, 19))
	b.path_line(Vector2i(30, 19), Vector2i(30, 15))
	b.path_line(Vector2i(30, 15), Vector2i(18, 15))
	var blocked := {}
	for x in range(16, 40):
		for y in range(13, 22):
			if b.get_t(x, y) == PATH or (x > 33 and y >= 17):
				for d in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, -1)]:
					blocked[Vector2i(x, y) + d] = true
	b.ellipse(Vector2(10, 9), Vector2(3.5, 2.5), WATER)
	b.scatter(60, Rect2i(2, 2, 36, 28), {"t": "tree", "kind": "oak", "hp": 3}, blocked, 1)
	b.scatter(25, Rect2i(2, 2, 36, 28), {"t": "tree", "kind": "pine", "hp": 3}, blocked, 1)
	b.scatter(14, Rect2i(2, 2, 36, 28), {"t": "bush"}, blocked)
	b.scatter(8, Rect2i(2, 2, 36, 28), {"t": "stump", "hp": 2}, blocked)
	b.scatter(14, Rect2i(2, 2, 36, 28), {"t": "twig"}, blocked)
	b.scatter(14, Rect2i(2, 2, 36, 28), {"t": "weed"}, blocked)
	return b.state()


static func _lake() -> Dictionary:
	var b := Builder.new(SIZES["lake"], 404)
	b.grass(Rect2i(0, 0, b.w, b.h), 0.06)
	b.border([Rect2i(18, 0, 3, 2)])
	var c := Vector2(20, 17)
	for y in b.h:
		for x in b.w:
			var d := pow((x - c.x) / 14.0, 2) + pow((y - c.y) / 7.0, 2)
			if d <= 1.0:
				b.set_t(x, y, WATER)
			elif d <= 1.45 and b.get_t(x, y) != 16:
				b.set_t(x, y, SAND)
	b.path_line(Vector2i(19, 0), Vector2i(19, 7))
	for y in range(8, 15):
		b.set_t(26, y, DOCK)
		b.set_t(27, y, DOCK)
	var blocked := {}
	for y in range(0, 10):
		for x in range(15, 31):
			blocked[Vector2i(x, y)] = true
	b.scatter(12, Rect2i(2, 2, 36, 24), {"t": "tree", "kind": "oak", "hp": 3}, blocked, 1)
	b.scatter(8, Rect2i(2, 2, 36, 24), {"t": "tree", "kind": "pine", "hp": 3}, blocked, 1)
	b.scatter(8, Rect2i(2, 2, 36, 24), {"t": "bush"}, blocked)
	return b.state()


static func _house() -> Dictionary:
	var b := Builder.new(SIZES["house"], 505)
	b.fill(Rect2i(0, 0, b.w, b.h), VOID)
	b.fill(Rect2i(1, 0, 10, 2), WALL)
	b.fill(Rect2i(1, 2, 10, 6), FLOOR)
	b.fill(Rect2i(5, 8, 2, 1), FLOOR)
	return b.state()


static func _mine_entrance() -> Dictionary:
	var b := Builder.new(SIZES["mine"], 606)
	b.fill(Rect2i(0, 0, b.w, b.h), CAVEWALL)
	for y in range(2, b.h - 1):
		for x in range(1, b.w - 1):
			b.set_t(x, y, CAVE if b.rng.randf() < 0.7 else CAVE2)
	b.fill(Rect2i(7, b.h - 1, 2, 1), CAVE)
	b.objects[Vector2i(8, 5)] = {"t": "ladder"}
	return b.state()


static func _mine_level(level: int) -> Dictionary:
	var b := Builder.new(SIZES["mine_level"], 7000 + level * 31 + GameClock.abs_day() * 7)
	b.fill(Rect2i(0, 0, b.w, b.h), CAVEWALL)
	for y in range(2, b.h - 1):
		for x in range(1, b.w - 1):
			b.set_t(x, y, CAVE if b.rng.randf() < 0.7 else CAVE2)
	for i in 5:  # каменные глыбы-стены
		var c := Vector2i(b.rng.randi_range(6, b.w - 4), b.rng.randi_range(5, b.h - 4))
		for dy in range(-1, 2):
			for dx in range(-2, 2):
				if b.rng.randf() < 0.75:
					b.set_t(c.x + dx, c.y + dy, CAVEWALL)
	b.objects[Vector2i(3, 2)] = {"t": "ladder_up"}
	var blocked := {}
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			blocked[Vector2i(3, 4) + Vector2i(dx, dy)] = true
	var kinds := [["rock", 60], ["rock2", 25], ["copper", 14]]
	if level >= 4:
		kinds.append(["iron", 10])
	if level >= 8:
		kinds.append(["gold", 6])
	var total := 0
	for k in kinds:
		total += k[1]
	for y in range(2, b.h - 1):
		for x in range(1, b.w - 1):
			var t := Vector2i(x, y)
			if blocked.has(t) or b.get_t(x, y) == CAVEWALL or b.rng.randf() > 0.38:
				continue
			var r := b.rng.randi_range(0, total - 1)
			for k in kinds:
				r -= k[1]
				if r < 0:
					b.objects[t] = {"t": k[0]}
					break
	if level == 10:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				b.objects.erase(Vector2i(13 + dx, 9 + dy))
				b.set_t(13 + dx, 9 + dy, CAVE)
		b.objects[Vector2i(13, 9)] = {"t": "treasure"}
	return b.state()
