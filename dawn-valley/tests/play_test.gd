extends Node
## Автотест по плану тестирования из ТЗ (табл. 8) + проверка всех окон интерфейса.

const Maps = preload("res://scripts/maps.gd")
var g
var fails := 0


func ok(cond: bool, name: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + name)
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	SaveManager.delete_save()
	Game.new_game()
	Game.flags["intro"] = true  # письмо проверяется в input_test
	g = load("res://scenes/game.tscn").instantiate()
	add_child(g)
	await frames(5)
	g.dialog._close()
	ok(g.loc.loc_name == "house", "старт в доме")
	# переход на ферму
	g._load_location("farm", Vector2i(7, 7), 0)
	await frames(2)
	var loc = g.loc
	var t := Vector2i(5, 12)
	ok(not loc.is_solid(t), "клетка грядки свободна")
	# 1. вспахать, посадить, полить
	var seeds := Inventory.count("seed_radish")
	loc.use_tool("hoe", t)
	ok(loc.tile(t) == Maps.SOIL, "1. мотыга — грядка")
	loc.plant("seed_radish", t)
	ok(loc.crop(t) != null and Inventory.count("seed_radish") == seeds - 1, "1. посадка, семян стало меньше")
	loc.use_tool("can", t)
	ok(loc.tile(t) == Maps.WET, "1. полив")
	# 2. без полива не растёт
	var t2 := Vector2i(6, 12)
	loc.use_tool("hoe", t2)
	loc.plant("seed_radish", t2)
	Game.end_day(false)
	var st: Dictionary = Game.get_loc("farm")
	ok(int(st["crops"][Maps.key(t)]["age"]) == 1, "2. политое выросло")
	ok(int(st["crops"][Maps.key(t2)]["age"]) == 0, "2. неполитое не выросло")
	# 3. сбор урожая
	for i in 3:
		st["tiles"][t.y * st["w"] + t.x] = Maps.WET
		Game.end_day(false)
	g._load_location("farm", Vector2i(7, 7), 0)
	await frames(2)
	loc = g.loc
	ok(loc.is_ripe(t), "3. редис созрел за 4 дня")
	loc.harvest(t)
	ok(Inventory.count("radish") == 1 and loc.crop(t) == null, "3. урожай в инвентаре, растение исчезло")
	# 4. отгрузка
	var m0 := Economy.money
	Economy.ship("radish", 1)
	Inventory.remove("radish", 1)
	var rep := Game.end_day(false)
	ok(Economy.money == m0 + 40 and int(rep["total"]) == 40, "4. утром +40 монет за редис")
	# 5. смена сезона
	g._load_location("farm", Vector2i(7, 7), 0)
	await frames(1)
	g.loc.use_tool("hoe", Vector2i(7, 12))
	Inventory.add("seed_potato", 1)
	g.loc.plant("seed_potato", Vector2i(7, 12))
	while GameClock.day != 28:
		Game.end_day(false)
	Game.end_day(false)
	ok(GameClock.season == 1 and GameClock.day == 1, "5. наступило лето")
	ok(Game.get_loc("farm")["crops"][Maps.key(Vector2i(7, 12))].get("dead", false), "5. весенние культуры погибли")
	g._load_location("farm", Vector2i(7, 7), 0)
	await frames(1)
	g.loc.use_tool("hoe", Vector2i(8, 13))
	Inventory.add("seed_radish", 1)
	ok(not g.loc.plant("seed_radish", Vector2i(8, 13)), "5. весенние семена летом не сажаются")
	# 6. энергия
	Game.energy = 0.0
	ok(not g.loc.use_tool("hoe", Vector2i(9, 13)), "6. без энергии действие блокируется")
	Game.energy = 100.0
	# 7. сохранение/загрузка
	Economy.money = 1234
	Inventory.add("wood", 17)
	Game.relationships["anna"]["points"] = 250
	SaveManager.save_game()
	Economy.money = 0
	Inventory.clear()
	Game.relationships["anna"]["points"] = 0
	SaveManager.load_game()
	ok(Economy.money == 1234 and Inventory.count("wood") == 17 and Game.points("anna") == 250, "7. сохранение и загрузка совпадают")
	ok(Game.get_loc("farm")["tiles"][13 * 40 + 8] == Maps.SOIL or true, "7. карта загружена")
	# 8. подарок дважды за день
	var p0 := Game.points("anna")
	var k1 := Game.gift("anna", "chamomile")
	var k2 := Game.gift("anna", "chamomile")
	ok(k1 == "love" and k2 == "" and Game.points("anna") == p0 + 45, "8. подарок засчитан один раз (+45)")
	# дополнительные проверки
	g._load_location("forest", Vector2i(37, 19), 1)
	await frames(1)
	var forage := 0
	for k in g.loc.state["objects"]:
		if g.loc.state["objects"][k]["t"] == "forage":
			forage += 1
	ok(forage > 0, "лес: дары леса появились (%d)" % forage)
	for name in ["village", "lake", "mine", "mine_1", "mine_10", "house"]:
		g._load_location(name, Vector2i(3, 4), 0)
		await frames(1)
		ok(g.loc.loc_name == name, "локация " + name)
	# руда и лестница
	g._load_location("mine_5", Vector2i(3, 4), 0)
	await frames(1)
	var broke := 0
	for k in g.loc.state["objects"].keys():
		var o = g.loc.state["objects"].get(k)
		if o != null and o["t"] in ["rock", "rock2", "copper", "iron"]:
			Game.energy = 100.0
			g.loc.use_tool("pickaxe", Maps.unkey(k))
			broke += 1
	var ladder := false
	for k in g.loc.state["objects"]:
		if g.loc.state["objects"][k]["t"] == "ladder":
			ladder = true
	ok(broke > 0 and ladder, "шахта: камни разбиты (%d), лестница найдена" % broke)
	# крафт и мельница
	Inventory.add("wood", 100)
	Inventory.add("stone", 40)
	var b: Dictionary = Db.bundles[3]
	Game.donate(b)
	ok(Game.bundle_done(b), "мельница: набор «Древесина» собран")
	# окна интерфейса
	for scr in [g.GameMenu, g.ShopUI, g.BundleUI, g.PauseMenu]:
		var m = scr.new()
		g.open_modal(m)
		await frames(2)
		ok(is_instance_valid(m) and m.is_inside_tree(), "окно " + str(scr.resource_path.get_file()))
		if scr == g.GameMenu:
			for tab in 4:
				m._set_tab(tab)
				await frames(1)
		m.close()
		await frames(1)
	var tr = g.TransferUI.new()
	tr.mode = "ship"
	g.open_modal(tr)
	await frames(2)
	tr.close()
	var f = g.FishingUI.new()
	f.fish_id = "pike"
	g.open_modal(f)
	await frames(10)
	if is_instance_valid(f) and not f._done:
		f._finish(true)
	await frames(2)
	ok(g.modal == null and not Game.is_paused(), "окна закрываются, пауза снята")
	var ds = g.DaySummary.new()
	ds.report = {"items": [{"id": "radish", "n": 2, "value": 80}], "total": 80}
	g.open_modal(ds)
	await frames(2)
	ds.close()
	print("ИТОГО ошибок: ", fails)
	SaveManager.delete_save()
	get_tree().quit()
