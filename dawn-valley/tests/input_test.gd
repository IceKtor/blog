extends Node
## Проверка через имитацию ввода: ходьба, инструменты, дверь, разговор, сон.

const Maps = preload("res://scripts/maps.gd")
var g
var fails := 0

var log_f: FileAccess

func step(n: String) -> void:
	if log_f == null:
		log_f = FileAccess.open("/tmp/claude-0/input_test.log", FileAccess.WRITE)
	log_f.store_line(n)
	log_f.flush()

func ok(c: bool, n: String) -> void:
	step(("  OK   " if c else "  FAIL ") + n)
	print(("  OK   " if c else "  FAIL ") + n)
	if not c: fails += 1

func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame

func act(a: String) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	var r := InputEventAction.new()
	r.action = a
	r.pressed = false
	Input.parse_input_event(r)
	await frames(2)

func hold(a: String, n: int) -> void:
	Input.action_press(a)
	await frames(n)
	Input.action_release(a)
	await frames(2)

func _ready() -> void:
	SaveManager.delete_save()
	Game.new_game()
	g = load("res://scenes/game.tscn").instantiate()
	add_child(g)
	await frames(60)
	step("start")
	for i in 12:
		await act("use")
		step("use %d dlg=%s" % [i, g.dialog.is_open()])
	ok(not g.dialog.is_open(), "вступительное письмо пролистывается")
	# из дома на ферму
	var p0: Vector2 = g.player.position
	await hold("move_left", 20)
	ok(g.player.position.x < p0.x, "ходьба влево")
	g.player.position = Vector2(5 * 16 + 8, 7 * 16 + 10)
	await hold("move_down", 30)
	await frames(40)
	ok(g.loc.loc_name == "farm", "выход из дома на ферму")
	# мотыга
	g.player.position = Vector2(9 * 16 + 8, 12 * 16 + 12)
	g.player.set_dir(0)
	await act("slot_0")
	ok(Inventory.current_id() == "hoe", "выбрана мотыга")
	await act("use")
	await frames(30)
	var t: Vector2i = g.player.feet_tile() + Vector2i(0, 1)
	ok(g.loc.tile(t) == Maps.SOIL, "мотыга по нажатию")
	await act("slot_5")
	await act("use")
	ok(g.loc.crop(t) != null, "посадка семян")
	await act("slot_1")
	await act("use")
	await frames(30)
	ok(g.loc.tile(t) == Maps.WET, "полив лейкой")
	# инвентарь
	await act("inventory")
	ok(g.modal != null, "Tab открывает меню")
	await act("pause")
	ok(g.modal == null, "Esc закрывает меню")
	await act("pause")
	ok(g.modal != null, "Esc открывает паузу")
	await act("pause")
	# дверь дома
	g.player.position = Vector2(7 * 16 + 8, 7 * 16 + 12)
	await hold("move_up", 20)
	await frames(40)
	ok(g.loc.loc_name == "house", "вход в дом через дверь")
	# сон
	g.player.position = Vector2(7 * 16 + 8, 3 * 16 + 12)
	g.player.set_dir(2)
	await act("interact")
	ok(g.dialog.is_open(), "кровать спрашивает про сон")
	var e := InputEventKey.new()
	e.physical_keycode = KEY_1
	e.pressed = true
	Input.parse_input_event(e)
	await frames(120)
	ok(g.modal != null and g.modal.get_script() == g.DaySummary, "итоги дня показаны")
	if g.modal == null:
		get_tree().quit()
		return
	g.modal.close()
	await frames(80)
	ok(GameClock.day == 2 and SaveManager.has_save(), "наступил день 2, игра сохранена")
	var st: Dictionary = Game.get_loc("farm")
	ok(int(st["crops"][Maps.key(t)]["age"]) == 1, "политая грядка подросла")
	# в деревню и разговор
	g._load_location("village", Vector2i(20, 15), 0)
	GameClock.minutes = 12 * 60
	g.loc.refresh_npcs()
	await frames(5)
	var n = g.loc.npcs.values()[0]
	g.player.position = n.position + Vector2(0, 14)
	g.player.set_dir(3)
	n.stop_t = 5.0
	await act("slot_9")
	await act("interact")
	ok(g.dialog.is_open(), "разговор с жителем (" + n.id + ")")
	print("ИТОГО ошибок: ", fails)
	SaveManager.delete_save()
	get_tree().quit()
