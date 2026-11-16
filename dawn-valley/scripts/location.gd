extends Node2D
## Локация: отрисовка земли и воды, объекты, растения, постройки, столкновения и действия игрока.

const Maps = preload("res://scripts/maps.gd")
const NpcScene = preload("res://scenes/npc.tscn")

const T := 16
const SOLID_OBJECTS := ["tree", "btree", "stump", "weed", "stone", "twig", "rock", "rock2", "copper", "iron", "gold",
	"fence", "sprinkler", "chest", "bush", "treasure"]
const FLAT_OBJECTS := ["ladder", "ladder_up", "path_stone"]
const OBJ_FRAME := {"stone": 4, "twig": 5, "stump": 6, "rock": 7, "rock2": 8, "copper": 9, "iron": 10, "gold": 11,
	"ladder": 12, "ladder_up": 12, "fence": 13, "sprinkler": 14, "path_stone": 15}
const OBJ_NAMES := {"tree": "Дерево", "btree": "Дерево", "stump": "Пень", "weed": "Сорняк", "stone": "Камень",
	"twig": "Ветка", "rock": "Камень", "rock2": "Камень", "copper": "Медная жила", "iron": "Железная жила",
	"gold": "Золотая жила", "bush": "Куст"}
const PLACEABLE := ["chest", "sprinkler", "fence", "path_stone"]

var loc_name := ""
var state: Dictionary
var w := 0
var h := 0
var structs := []
var door_map := {}        # Vector2i -> structure
var struct_solid := {}    # Vector2i -> true
var obj_nodes := {}
var crop_nodes := {}
var npcs := {}
var rocks_broken := 0

var ground: Node2D
var water: Node2D
var water_edges: Node2D
var flat: Node2D
var entities: Node2D
var solid_layer: TileMapLayer
var tint: CanvasModulate

static var _solid_tileset: TileSet


# ================================================================== построение
func build(name: String) -> void:
	loc_name = name
	state = Game.get_loc(name)
	w = state["w"]
	h = state["h"]
	ground = _DrawNode.new()
	ground.draw_fn = _draw_ground
	add_child(ground)
	water = _DrawNode.new()
	water.draw_fn = _draw_water
	water.material = ShaderMaterial.new()
	water.material.shader = preload("res://shaders/water.gdshader")
	add_child(water)
	water_edges = _DrawNode.new()
	water_edges.draw_fn = _draw_water_edges
	add_child(water_edges)
	flat = Node2D.new()
	add_child(flat)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	solid_layer = TileMapLayer.new()
	solid_layer.tile_set = _get_solid_tileset()
	solid_layer.self_modulate = Color(1, 1, 1, 0)
	add_child(solid_layer)
	tint = CanvasModulate.new()
	add_child(tint)
	structs = Maps.structures(name)
	for s in structs:
		_add_structure(s)
	for k in state["objects"]:
		_add_obj_node(Maps.unkey(k))
	for k in state["crops"]:
		_add_crop_node(Maps.unkey(k))
	_rebuild_solid()
	refresh_npcs()
	update_tint()
	GameClock.minute_passed.connect(_on_minute)


func _on_minute(_h: int, m: int) -> void:
	update_tint()
	if m == 0:
		refresh_npcs()


func update_tint() -> void:
	if loc_name.begins_with("mine"):
		tint.color = Color(0.62, 0.58, 0.7)
		return
	if loc_name == "house":
		tint.color = Color(1, 0.96, 0.9)
		return
	var mins := float(GameClock.minutes)
	var c := Color.WHITE
	if mins < 7 * 60:
		c = Color(1.0, 0.92, 0.85).lerp(Color.WHITE, (mins - 360.0) / 60.0)
	elif mins > 18 * 60:
		c = Color.WHITE.lerp(Color(0.42, 0.42, 0.68), clampf((mins - 1080.0) / 240.0, 0.0, 1.0))
	tint.color = c


static func _get_solid_tileset() -> TileSet:
	if _solid_tileset:
		return _solid_tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(T, T)
	src.create_tile(Vector2i.ZERO)
	ts.add_source(src, 0)
	var td := src.get_tile_data(Vector2i.ZERO, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	_solid_tileset = ts
	return ts


# ================================================================== запросы
func inside(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < w and t.y < h

func tile(t: Vector2i) -> int:
	return state["tiles"][t.y * w + t.x] if inside(t) else Maps.VOID

func set_tile(t: Vector2i, v: int) -> void:
	state["tiles"][t.y * w + t.x] = v
	ground.queue_redraw()
	_update_solid(t)

func tile_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))

func obj(t: Vector2i):
	return state["objects"].get(Maps.key(t))

func crop(t: Vector2i):
	return state["crops"].get(Maps.key(t))

func is_water(t: Vector2i) -> bool:
	return tile(t) == Maps.WATER

func _water_like(t: Vector2i) -> bool:
	var v := tile(t)
	return v == Maps.WATER or v == Maps.DOCK or not inside(t)

func is_solid(t: Vector2i) -> bool:
	if tile(t) in Maps.SOLID_TILES or struct_solid.has(t):
		return true
	var o = obj(t)
	return o != null and o["t"] in SOLID_OBJECTS

func is_soil(t: Vector2i) -> bool:
	var v := tile(t)
	return v == Maps.SOIL or v == Maps.WET

func world_pos(t: Vector2i) -> Vector2:
	return Vector2(t.x * T + 8, t.y * T + 8)

func exit_at(t: Vector2i):
	for e in Maps.exits(loc_name):
		if e["rect"].has_point(t):
			return e
	return null

func door_at(t: Vector2i):
	return door_map.get(t)

func is_ripe(t: Vector2i) -> bool:
	var c = crop(t)
	return c != null and not c.get("dead", false) and int(c["age"]) >= int(Db.crops[c["type"]]["days"])

func describe(t: Vector2i) -> String:
	var o = obj(t)
	if o != null:
		if o["t"] == "forage":
			return Db.item_name(o["item"])
		return OBJ_NAMES.get(o["t"], "")
	var c = crop(t)
	if c != null:
		return Db.item_name(c["type"])
	return ""


# ================================================================== отрисовка
class _DrawNode extends Node2D:
	var draw_fn: Callable
	func _draw() -> void:
		draw_fn.call(self)


func _draw_ground(n: Node2D) -> void:
	var tex := Db.tex("tiles_" + GameClock.season_key())
	for y in h:
		for x in w:
			var v: int = state["tiles"][y * w + x]
			if v == Maps.WATER:
				continue
			var col := Maps.FOREST if v == Maps.BORDER else v
			var dst := Rect2(x * T, y * T, T, T)
			n.draw_texture_rect_region(tex, dst, Rect2(col * T, 0, T, T))
			if v == Maps.SOIL or v == Maps.WET:
				var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
				for i in 4:
					if not is_soil(Vector2i(x, y) + dirs[i]):
						n.draw_texture_rect_region(tex, dst, Rect2((8 + i) * T, T, T, T))
			elif v == Maps.PATH:
				var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
				for i in 4:
					var nv := tile(Vector2i(x, y) + dirs[i])
					if nv in [Maps.GRASS, Maps.GRASS2, Maps.FLOWERS, Maps.FOREST, Maps.BORDER]:
						n.draw_texture_rect_region(tex, dst, Rect2((12 + i) * T, T, T, T))


func _draw_water(n: Node2D) -> void:
	for y in h:
		for x in w:
			if tile(Vector2i(x, y)) == Maps.WATER:
				n.draw_rect(Rect2(x * T, y * T, T, T), Color.WHITE)


func _draw_water_edges(n: Node2D) -> void:
	var tex := Db.tex("tiles_" + GameClock.season_key())
	for y in h:
		for x in w:
			var t := Vector2i(x, y)
			if tile(t) != Maps.WATER:
				continue
			var dst := Rect2(x * T, y * T, T, T)
			var nN := _water_like(t + Vector2i(0, -1))
			var nE := _water_like(t + Vector2i(1, 0))
			var nS := _water_like(t + Vector2i(0, 1))
			var nW := _water_like(t + Vector2i(-1, 0))
			var sides := [nN, nE, nS, nW]
			for i in 4:
				if not sides[i]:
					n.draw_texture_rect_region(tex, dst, Rect2(i * T, T, T, T))
			if nN and nE and not _water_like(t + Vector2i(1, -1)):
				n.draw_texture_rect_region(tex, dst, Rect2(4 * T, T, T, T))
			if nN and nW and not _water_like(t + Vector2i(-1, -1)):
				n.draw_texture_rect_region(tex, dst, Rect2(5 * T, T, T, T))
			if nS and nE and not _water_like(t + Vector2i(1, 1)):
				n.draw_texture_rect_region(tex, dst, Rect2(6 * T, T, T, T))
			if nS and nW and not _water_like(t + Vector2i(-1, 1)):
				n.draw_texture_rect_region(tex, dst, Rect2(7 * T, T, T, T))


func redraw_all() -> void:
	ground.queue_redraw()
	water.queue_redraw()
	water_edges.queue_redraw()


# ================================================================== узлы объектов
func _add_structure(s: Dictionary) -> void:
	var tname: String = s["tex"]
	if tname == "mill":
		tname = "mill_fixed" if Game.mill_fixed else "mill_broken"
	var spr := Sprite2D.new()
	spr.texture = Db.tex(tname)
	spr.centered = false
	if s.get("seasonal", false):
		spr.hframes = 4
		spr.frame = GameClock.season
	var th := spr.texture.get_height()
	spr.position = Vector2(s["x"] * T, (s["y"] + s["h"]) * T)
	spr.offset = Vector2(0, -th)
	entities.add_child(spr)
	s["node"] = spr
	for y in range(s["y"] + s["solid_from"], s["y"] + s["h"]):
		for x in range(s["x"], s["x"] + s["w"]):
			struct_solid[Vector2i(x, y)] = true
	for d in s.get("doors", []):
		door_map[d] = s


func refresh_structure(tex_key: String) -> void:
	for s in structs:
		if s["tex"] == tex_key and s.has("node"):
			if tex_key == "mill":
				s["node"].texture = Db.tex("mill_fixed" if Game.mill_fixed else "mill_broken")


func _add_obj_node(t: Vector2i) -> void:
	var o = obj(t)
	if o == null:
		return
	var spr := Sprite2D.new()
	spr.centered = false
	var kind: String = o["t"]
	match kind:
		"tree", "btree":
			spr.texture = Db.tex("trees_" + GameClock.season_key())
			spr.region_enabled = true
			spr.region_rect = Rect2(0 if o.get("kind", "oak") == "oak" else 32, 0, 32, 48)
			spr.position = Vector2(t.x * T + 8, t.y * T + 16)
			spr.offset = Vector2(-16, -47)
		"chest", "treasure":
			spr.texture = Db.tex("chest")
			spr.position = Vector2(t.x * T, t.y * T + 16)
			spr.offset = Vector2(0, -31)
			if kind == "treasure":
				spr.modulate = Color(1.2, 1.1, 0.6)
		"forage":
			spr.texture = Db.icon(o["item"])
			spr.position = Vector2(t.x * T, t.y * T + 16)
			spr.offset = Vector2(0, -15)
		_:
			spr.texture = Db.tex("objects")
			spr.hframes = 8
			spr.vframes = 3
			if kind == "weed":
				spr.frame = GameClock.season
			elif kind == "bush":
				spr.frame = 16 + GameClock.season
			else:
				spr.frame = OBJ_FRAME.get(kind, 4)
			spr.position = Vector2(t.x * T, t.y * T + 16)
			spr.offset = Vector2(0, -16)
	if kind in FLAT_OBJECTS:
		spr.position.y -= 0
		flat.add_child(spr)
	else:
		entities.add_child(spr)
	obj_nodes[t] = spr


func _remove_obj(t: Vector2i) -> void:
	state["objects"].erase(Maps.key(t))
	if obj_nodes.has(t):
		obj_nodes[t].queue_free()
		obj_nodes.erase(t)
	_update_solid(t)


func set_obj(t: Vector2i, o: Dictionary) -> void:
	if obj_nodes.has(t):
		obj_nodes[t].queue_free()
		obj_nodes.erase(t)
	state["objects"][Maps.key(t)] = o
	_add_obj_node(t)
	_update_solid(t)


func _add_crop_node(t: Vector2i) -> void:
	var spr := Sprite2D.new()
	spr.texture = Db.tex("crops")
	spr.centered = false
	spr.hframes = 6
	spr.vframes = 9
	spr.position = Vector2(t.x * T, t.y * T + 16)
	spr.offset = Vector2(0, -30)
	entities.add_child(spr)
	crop_nodes[t] = spr
	_crop_frame(t)


func _crop_frame(t: Vector2i) -> void:
	var c = crop(t)
	var info: Dictionary = Db.crops[c["type"]]
	var st := 0
	var days: int = info["days"]
	if c.get("dead", false):
		st = 5
	elif int(c["age"]) >= days:
		st = 4
	elif int(c["age"]) > 0:
		st = clampi(1 + int(c["age"]) * 3 / days, 1, 3)
	crop_nodes[t].frame = int(info["row"]) * 6 + st


func _remove_crop(t: Vector2i) -> void:
	state["crops"].erase(Maps.key(t))
	if crop_nodes.has(t):
		crop_nodes[t].queue_free()
		crop_nodes.erase(t)


func _rebuild_solid() -> void:
	solid_layer.clear()
	for y in h:
		for x in w:
			_update_solid(Vector2i(x, y))
	# граница карты
	for x in range(-1, w + 1):
		solid_layer.set_cell(Vector2i(x, -1), 0, Vector2i.ZERO)
		solid_layer.set_cell(Vector2i(x, h), 0, Vector2i.ZERO)
	for y in range(-1, h + 1):
		solid_layer.set_cell(Vector2i(-1, y), 0, Vector2i.ZERO)
		solid_layer.set_cell(Vector2i(w, y), 0, Vector2i.ZERO)


func _update_solid(t: Vector2i) -> void:
	if is_solid(t):
		solid_layer.set_cell(t, 0, Vector2i.ZERO)
	else:
		solid_layer.erase_cell(t)


func _shake(t: Vector2i) -> void:
	if not obj_nodes.has(t):
		return
	var n: Node2D = obj_nodes[t]
	var p := n.position
	var tw := create_tween()
	tw.tween_property(n, "position", p + Vector2(1.5, 0), 0.04)
	tw.tween_property(n, "position", p - Vector2(1.5, 0), 0.06)
	tw.tween_property(n, "position", p, 0.04)


func _particles(t: Vector2i, col: Color, n := 6) -> void:
	for i in n:
		var r := ColorRect.new()
		r.color = col
		r.size = Vector2(2, 2)
		r.position = world_pos(t) + Vector2(randf_range(-4, 4), randf_range(-6, 2))
		r.z_index = 5
		add_child(r)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(r, "position", r.position + Vector2(randf_range(-10, 10), randf_range(-14, -2)), 0.35)
		tw.tween_property(r, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(r.queue_free)


# ================================================================== жители
func refresh_npcs() -> void:
	for id in Db.NPC_IDS:
		var slot = Game.npc_slot(id)
		var here: bool = slot != null and slot[2] == loc_name
		if here and not npcs.has(id):
			var n = NpcScene.instantiate()
			n.setup(id, self, slot[3])
			entities.add_child(n)
			npcs[id] = n
		elif here:
			npcs[id].area = slot[3]
		elif not here and npcs.has(id):
			npcs[id].queue_free()
			npcs.erase(id)


func random_free_tile(area: Rect2i) -> Vector2i:
	for i in 60:
		var t := Vector2i(randi_range(area.position.x, area.end.x - 1), randi_range(area.position.y, area.end.y - 1))
		if not is_solid(t) and not is_water(t):
			return t
	return area.get_center()


# ================================================================== действия игрока
func notify(text: String, id := "") -> void:
	Game.notify.emit(Db.icon(id) if id != "" else null, text)


## Инструмент по клетке. Возвращает true, если действие что-то сделало.
func use_tool(tool: String, t: Vector2i) -> bool:
	var o = obj(t)
	var kind: String = "" if o == null else o["t"]
	if kind == "weed" and tool in ["hoe", "axe", "pickaxe"]:
		if not Game.spend(1):
			return false
		Audio.sfx("chop")
		_particles(t, Color("64aa40"))
		_remove_obj(t)
		Game.give("fiber", 1)
		if randf() < 0.05 and Game.current_loc == "farm":
			Game.give(["seed_radish", "seed_corn", "seed_cabbage", "seed_potato"][GameClock.season % 4] if GameClock.season < 3 else "fiber", 1)
		return true
	match tool:
		"hoe":
			var c = crop(t)
			if c != null and c.get("dead", false):
				_remove_crop(t)
				return true
			if o != null or c != null or struct_solid.has(t):
				return false
			if loc_name != "farm":
				notify("Копать можно только на ферме.")
				return false
			if tile(t) in [Maps.GRASS, Maps.GRASS2, Maps.FLOWERS, Maps.FOREST, Maps.PATH] and Game.spend(2):
				Audio.sfx("hoe")
				_particles(t, Color("84583a"), 4)
				set_tile(t, Maps.SOIL)
				return true
		"can":
			if is_water(t):
				Game.refill_can()
				Audio.sfx("water")
				notify("Лейка наполнена.")
				return true
			if is_soil(t):
				if tile(t) == Maps.WET:
					return false
				if Game.use_water() and Game.spend(1):
					Audio.sfx("water")
					_particles(t, Color("8cc4e8"), 5)
					set_tile(t, Maps.WET)
					return true
		"axe":
			match kind:
				"twig":
					if Game.spend(2):
						Audio.sfx("chop")
						_particles(t, Color("995a30"))
						_remove_obj(t)
						Game.give("wood", 1)
						return true
				"tree":
					if Game.spend(3):
						Audio.sfx("chop")
						_particles(t, Color("38803c"))
						o["hp"] = int(o.get("hp", 3)) - 1
						_shake(t)
						if o["hp"] <= 0:
							Audio.sfx("tree_fall")
							set_obj(t, {"t": "stump", "hp": 2, "age": 0})
							Game.give("wood", randi_range(5, 8))
						return true
				"stump":
					if Game.spend(3):
						Audio.sfx("chop")
						_particles(t, Color("673722"))
						o["hp"] = int(o.get("hp", 2)) - 1
						_shake(t)
						if o["hp"] <= 0:
							_remove_obj(t)
							Game.give("wood", randi_range(2, 3))
						return true
				"btree":
					notify("Этот могучий лес не срубить.")
				_:
					return _pickup(t, kind)
		"pickaxe":
			match kind:
				"stone":
					if Game.spend(3):
						Audio.sfx("rock_break")
						_particles(t, Color("9c9ab0"))
						_remove_obj(t)
						Game.give("stone", 1)
						return true
				"rock", "rock2", "copper", "iron", "gold":
					if Game.spend(3):
						Audio.sfx("pick")
						_particles(t, Color("74708a"), 8)
						_remove_obj(t)
						match kind:
							"copper": Game.give("copper_ore", randi_range(1, 3))
							"iron": Game.give("iron_ore", randi_range(1, 2))
							"gold": Game.give("gold_ore", randi_range(1, 2))
							_: Game.give("stone", randi_range(1, 2))
						_maybe_ladder(t)
						return true
				_:
					if _pickup(t, kind):
						return true
					if is_soil(t) and crop(t) == null:
						if Game.spend(2):
							Audio.sfx("hoe")
							set_tile(t, Maps.GRASS)
							return true
	return false


func _pickup(t: Vector2i, kind: String) -> bool:
	if not kind in PLACEABLE:
		return false
	var o = obj(t)
	if kind == "chest":
		for s in o.get("slots", []):
			if s != null:
				notify("Сначала опустоши сундук.")
				return false
	if not Inventory.can_add(kind):
		return false
	Audio.sfx("pickup")
	_remove_obj(t)
	Game.give(kind, 1)
	return true


func _maybe_ladder(t: Vector2i) -> void:
	if not loc_name.begins_with("mine_") or int(loc_name.substr(5)) >= 10:
		return
	rocks_broken += 1
	var left := 0
	for k in state["objects"]:
		if state["objects"][k]["t"] in ["rock", "rock2", "copper", "iron", "gold"]:
			left += 1
		if state["objects"][k]["t"] == "ladder":
			return
	var chance := maxf(0.08, 1.0 / maxf(1.0, float(left)))
	if rocks_broken >= 3 and randf() < chance or left == 0:
		set_obj(t, {"t": "ladder"})
		notify("Найдена лестница вниз!")
		Audio.sfx("bite")


func plant(seed_id: String, t: Vector2i) -> bool:
	var ctype: String = Db.item(seed_id).get("crop", "")
	if ctype == "" or not is_soil(t) or crop(t) != null or obj(t) != null:
		return false
	if loc_name != "farm":
		return false
	var info: Dictionary = Db.crops[ctype]
	if int(info["season"]) != GameClock.season:
		notify("Сейчас не сезон: %s растёт %s." % [Db.item_name(ctype), ["весной", "летом", "осенью"][int(info["season"])]])
		Audio.sfx("error")
		return false
	state["crops"][Maps.key(t)] = {"type": ctype, "age": 0, "dead": false}
	_add_crop_node(t)
	Inventory.remove(seed_id, 1)
	Audio.sfx("hoe", 0.2)
	return true


func place(id: String, t: Vector2i) -> bool:
	if loc_name != "farm" or is_solid(t) or obj(t) != null or crop(t) != null or is_soil(t) or is_water(t):
		return false
	var o := {"t": id}
	if id == "chest":
		var slots := []
		slots.resize(20)
		o["slots"] = slots
	set_obj(t, o)
	Inventory.remove(id, 1)
	Audio.sfx("hoe", 0.2)
	return true


func harvest(t: Vector2i) -> bool:
	var c = crop(t)
	if c == null:
		return false
	if c.get("dead", false):
		_remove_crop(t)
		return true
	if not is_ripe(t):
		return false
	var item: String = Db.crops[c["type"]]["item"]
	if not Inventory.can_add(item):
		notify("Рюкзак полон!")
		return false
	Audio.sfx("harvest")
	_particles(t, Color("a8d45a"), 5)
	_remove_crop(t)
	Game.give(item, 1)
	return true


## Взаимодействие (E / ПКМ). Возвращает строку-действие для игровой сцены или "" если обработано тут.
func interact(t: Vector2i) -> String:
	if crop(t) != null:
		if harvest(t):
			return "done"
		var c = crop(t)
		notify("%s: %d из %d дней%s" % [Db.item_name(c["type"]), int(c["age"]), int(Db.crops[c["type"]]["days"]),
			"" if tile(t) == Maps.WET else " — нужно полить"])
		return "done"
	var o = obj(t)
	if o != null:
		match o["t"]:
			"forage":
				if Game.give(o["item"], 1):
					Audio.sfx("harvest")
					_remove_obj(t)
				return "done"
			"chest":
				return "chest"
			"ladder":
				return "ladder_down"
			"ladder_up":
				return "ladder_up"
			"treasure":
				_remove_obj(t)
				Game.flags["treasure"] = true
				Game.give("ancient_coin", 1)
				Economy.add_money(500)
				notify("Сокровище! +500 монет")
				Audio.sfx("catch")
				return "done"
	var s = door_at(t)
	if s != null:
		return s.get("action", "")
	return ""
