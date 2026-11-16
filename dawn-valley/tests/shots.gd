extends Node
## Скриншоты основных экранов (запуск под Xvfb).

var g
var out := "/tmp/claude-0/shots/"


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
	print("shot ", name)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var mm = load("res://scenes/main_menu.tscn").instantiate()
	add_child(mm)
	await shot("00_menu")
	mm.queue_free()
	SaveManager.delete_save()
	Game.new_game()
	g = load("res://scenes/game.tscn").instantiate()
	add_child(g)
	await frames(60)
	await shot("01_intro")
	g.dialog._close()
	g._load_location("farm", Vector2i(9, 12), 0)
	var loc = g.loc
	for x in range(4, 10):
		for y in range(12, 15):
			loc.use_tool("hoe", Vector2i(x, y))
			if x < 8:
				loc.plant("seed_radish", Vector2i(x, y))
			if y < 14:
				loc.use_tool("can", Vector2i(x, y))
	var k := 0
	for ck in loc.state["crops"]:
		loc.state["crops"][ck]["age"] = k % 5
		k += 1
	for x in range(11, 15):
		loc.use_tool("hoe", Vector2i(x, 13))
		loc.state["crops"]["%d,13" % x] = {"type": ["strawberry", "potato", "radish", "strawberry"][x - 11], "age": 9, "dead": false}
	g._load_location("farm", Vector2i(9, 12), 0)
	loc = g.loc
	Game.energy = 70
	GameClock.minutes = 10 * 60 + 30
	g.player.position = Vector2(10 * 16 + 8, 11 * 16 + 14)
	await frames(30)
	await shot("02_farm")
	g.player.position = Vector2(30 * 16 + 8, 20 * 16 + 14)
	await frames(30)
	await shot("03_farm_pond")
	g._load_location("village", Vector2i(20, 15), 0)
	GameClock.minutes = 12 * 60
	g.loc.refresh_npcs()
	await frames(30)
	await shot("04_village")
	g._load_location("lake", Vector2i(26, 10), 0)
	await frames(30)
	await shot("05_lake")
	g._load_location("forest", Vector2i(30, 16), 0)
	await frames(30)
	await shot("06_forest")
	g._load_location("mine_6", Vector2i(3, 4), 0)
	await frames(30)
	await shot("07_mine")
	g._load_location("house", Vector2i(8, 4), 0)
	await frames(30)
	await shot("08_house")
	g._load_location("farm", Vector2i(9, 12), 0)
	Inventory.add("wood", 60)
	Inventory.add("carp", 3)
	Inventory.add("blackberry", 4)
	var m = g.GameMenu.new()
	g.open_modal(m)
	await frames(5)
	await shot("09_inventory")
	m._set_tab(1)
	await shot("10_craft")
	m._set_tab(2)
	await shot("11_people")
	m._set_tab(3)
	await shot("12_mill_tab")
	m.close()
	g.open_modal(g.ShopUI.new())
	await shot("13_shop")
	g.modal.close()
	g._load_location("village", Vector2i(20, 15), 0)
	g.talk_to(g.loc.npcs.values()[0])
	await frames(5)
	g.dialog._close()
	g._talk("anna")
	await frames(90)
	await shot("14_dialog")
	g.dialog._close()
	var f = g.FishingUI.new()
	f.fish_id = "perch"
	g._load_location("lake", Vector2i(26, 13), 0)
	g.open_modal(f)
	await frames(40)
	await shot("15_fishing")
	f._finish(true)
	GameClock.minutes = 21 * 60
	g._load_location("farm", Vector2i(9, 12), 0)
	await frames(10)
	await shot("16_night")
	GameClock.season = 3
	g._load_location("farm", Vector2i(9, 12), 0)
	GameClock.minutes = 12 * 60
	g.loc.update_tint()
	await frames(10)
	await shot("17_winter")
	GameClock.season = 2
	g._load_location("forest", Vector2i(30, 16), 0)
	await frames(10)
	await shot("18_fall")
	SaveManager.delete_save()
	get_tree().quit()
