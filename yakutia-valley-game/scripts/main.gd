extends Node2D
## Yakutia Valley — маленькая ферма на аласе. Мир, интерфейс и логика строятся из кода.

const Data = preload("res://scripts/data.gd")

const T := 16
const W := 50
const H := 36
# id тайлов = номер кадра в assets/tiles.png
const G0 := 0
const GF := 1
const PATH := 2
const SOIL := 3
const WET := 4
const WATER := 5
const SHORE := 6
const TAIGA := 7
const G2 := 11
const MAX_E := 100.0
const DAY_START := 360.0   # 6:00
const DAY_END := 1560.0    # 2:00 ночи
const SEC_PER_MIN := 0.7
const SAVE_PATH := "user://yakutia_save.json"
const DIRS := [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]

var tex := {}
var icons := {}
var tiles := PackedInt32Array()
var solid := PackedByteArray()
var objects := {}      # Vector2i -> {"kind": ..., "node": Sprite2D, ...}
var crops := {}        # Vector2i -> {"type": ..., "age": int, "node": Sprite2D}
var removed_rocks := []

var mode := "play"     # play | dialog | menu | fish | sleep
var day := 1
var minutes := DAY_START
var money := 300
var energy := MAX_E
var inv := []
var sel := 0
var npc_f := 0         # дружба с олонхосутом (0..30, сердечко = 3)
var horse_f := 0
var npc_talked := false
var npc_gifted := false
var horse_pet := false
var water_frame := 0
var clock := 0.0
var fishing := {}

var ground: Ground
var world: Node2D
var player: Node2D
var psprite: Sprite2D
var tool_icon: Sprite2D
var bang: Label
var pdir := 0
var pwalk := 0.0
var tool_t := 0.0
var night: CanvasModulate
var npc: Wanderer
var horse: Wanderer
var kamelyok: Sprite2D

# интерфейс
var ui: Control
var hud: Label
var ebar: ProgressBar
var slots := []
var item_label: Label
var toast: Label
var toast_t := 0.0
var help: Label
var dlg: Panel
var dlg_port: TextureRect
var dlg_name: Label
var dlg_text: Label
var dlg_lines := []
var dlg_done := Callable()
var menu: PanelContainer
var menu_title: Label
var menu_box: VBoxContainer
var fade: ColorRect
var st_slot: StyleBoxFlat
var st_sel: StyleBoxFlat


# ------------------------------------------------------------------ рисование земли
class Ground extends Node2D:
	var m
	func _draw() -> void:
		var tt: Texture2D = m.tex["tiles"]
		for y in 36:
			for x in 50:
				var id: int = m.tiles[y * 50 + x]
				if id == 5 and m.water_frame == 1:
					id = 9
				draw_texture_rect_region(tt, Rect2(x * 16, y * 16, 16, 16), Rect2(id * 16, 0, 16, 16))
		if m.mode == "fish":
			var b: Vector2 = m.fishing["pos"] + Vector2(0, sin(m.clock * 5.0) + (2.0 if m.fishing["bite"] else 0.0))
			draw_line(m.player.position + Vector2(0, -22), b, Color(1, 1, 1, 0.5), 1.0)
			draw_circle(b, 2.5, Color("eef3f8"))
			draw_circle(b + Vector2(0, -1), 1.5, Color("c42c34"))


# ------------------------------------------------------------------ бродящие существа
class Wanderer extends Node2D:
	var m
	var spr: Sprite2D
	var area := Rect2()
	var speed := 18.0
	var target := Vector2.ZERO
	var wait := 1.0
	var is_horse := false
	var dir := 0
	var t := 0.0
	var busy := 0.0

	func tick(delta: float) -> void:
		if busy > 0.0:
			busy -= delta
			_frame(false)
			return
		if wait > 0.0:
			wait -= delta
			_frame(false)
			return
		var to := target - position
		if to.length() < 2.0:
			wait = randf_range(1.5, 4.5)
			_new_target()
			return
		var np := position + to.normalized() * speed * delta
		if m.is_solid(m.tile_at(np + Vector2(0, -2))) or np.distance_to(m.player.position) < 10.0:
			wait = 0.8
			_new_target()
			return
		position = np
		if absf(to.x) > absf(to.y) or is_horse:
			dir = 2 if to.x > 0 else 1
		else:
			dir = 0 if to.y > 0 else 3
		t += delta
		_frame(true)

	func _new_target() -> void:
		target = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))

	func face(p: Vector2) -> void:
		var d := p - position
		if is_horse or absf(d.x) > absf(d.y):
			dir = 2 if d.x > 0 else 1
		else:
			dir = 0 if d.y > 0 else 3
		busy = 3.0
		_frame(false)

	func _frame(moving: bool) -> void:
		if is_horse:
			var row := 1 if dir == 1 else 0
			spr.frame = row * 3 + ((1 + int(t * 6.0) % 2) if moving else 0)
		else:
			spr.frame = dir * 4 + ((int(t * 7.0) % 4) if moving else 0)


# ================================================================== запуск
func _ready() -> void:
	randomize()
	_setup_input()
	for n in ["tiles", "items", "crops", "player", "olonkhosut", "portrait_olonkhosut", "horse",
			"trees", "bush", "balagan", "urasa", "serge", "kamelyok", "ampaar"]:
		tex[n] = load("res://assets/%s.png" % n)
	ground = Ground.new()
	ground.m = self
	add_child(ground)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	night = CanvasModulate.new()
	add_child(night)
	_gen_map()
	_make_player()
	_make_creatures()
	_make_ui()
	for i in 12:
		inv.append(null)
	if not _load():
		add_item("hoe", 1); add_item("can", 1); add_item("rod", 1)
		add_item("seed_turnip", 6); add_item("seed_potato", 4)
		say("", null, [
			"Ты вернулся на алас своих предков: балаган, сэргэ у порога и старый камелёк.",
			"Рыхли землю мотыгой, сажай и поливай семена, лови карася в озере.",
			"Урожай продавай через амбар, а готовь у камелька.",
			"Олонхосут Бэргэн живёт в урасе на востоке. Загляни к нему!",
			"Нажми H, чтобы увидеть управление."])
	ground.queue_redraw()
	_refresh_ui()


func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"use": [KEY_SPACE, KEY_C], "interact": [KEY_E, KEY_X], "eat": [KEY_F], "help": [KEY_H],
	}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)
	var lmb := InputEventMouseButton.new()
	lmb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("use", lmb)
	var rmb := InputEventMouseButton.new()
	rmb.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("interact", rmb)


# ================================================================== карта
func idx(t: Vector2i) -> int:
	return t.y * W + t.x

func tile_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))

func in_map(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < W and t.y < H

func get_tile(t: Vector2i) -> int:
	return tiles[idx(t)] if in_map(t) else TAIGA

func is_water(t: Vector2i) -> bool:
	var id := get_tile(t)
	return id == WATER or id == SHORE

func is_solid(t: Vector2i) -> bool:
	if not in_map(t):
		return true
	return solid[idx(t)] == 1 or is_water(t)

func is_grass(t: Vector2i) -> bool:
	var id := get_tile(t)
	return id == G0 or id == GF or id == G2


func _gen_map() -> void:
	tiles.resize(W * H)
	solid.resize(W * H)
	solid.fill(0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261115
	for y in H:
		for x in W:
			var r := rng.randf()
			var id := G0
			if r < 0.07:
				id = GF
			elif r < 0.3:
				id = G2
			if x < 3 or x >= W - 3 or y < 3 or y >= H - 3:
				id = TAIGA
			if pow((x - 38) / 7.0, 2) + pow((y - 25) / 4.5, 2) <= 1.0:
				id = WATER
			tiles[y * W + x] = id
	for y in range(1, H):
		for x in W:
			if tiles[y * W + x] == WATER and tiles[(y - 1) * W + x] != WATER:
				tiles[y * W + x] = SHORE
	# тропинки
	var path := []
	for y in range(10, 14): path.append(Vector2i(12, y))
	for x in range(12, 37): path.append(Vector2i(x, 13))
	for y in range(11, 13): path.append(Vector2i(36, y))
	for y in range(14, 20): path.append(Vector2i(30, y))
	for p in path:
		tiles[idx(p)] = PATH
	var reserved := {}
	for p in path:
		reserved[p] = true
	# постройки
	_building("balagan", "balagan", Vector2i(10, 6), 4, 4, 1, reserved)
	objects[Vector2i(12, 9)] = {"kind": "door"}
	_building("kamelyok", "kamelyok", Vector2i(15, 8), 1, 2, 1, reserved, 3)
	kamelyok = objects[Vector2i(15, 9)]["node"]
	_building("ampaar", "ampaar", Vector2i(17, 8), 2, 2, 0, reserved)
	_building("serge", "serge", Vector2i(20, 11), 1, 2, 1, reserved)
	_building("urasa", "urasa", Vector2i(35, 7), 3, 4, 1, reserved)
	# деревья тайги
	for y in H:
		for x in W:
			var t := Vector2i(x, y)
			if tiles[idx(t)] == TAIGA and rng.randf() < (0.25 if (y == 2 or y == H - 3 or x == 2 or x == W - 3) else 0.5):
				_tree(t, 0 if rng.randf() < 0.65 else 1)
	for p in [Vector2i(7, 8), Vector2i(25, 17), Vector2i(26, 31), Vector2i(44, 12), Vector2i(5, 22), Vector2i(23, 5)]:
		_tree(p, 1)
	for p in [Vector2i(42, 5), Vector2i(46, 17), Vector2i(19, 31), Vector2i(4, 12)]:
		_tree(p, 0)
	# кусты брусники у кромки тайги
	var cand := []
	for x in range(4, W - 4):
		cand.append(Vector2i(x, 3))
		cand.append(Vector2i(x, H - 4))
	for y in range(5, H - 5):
		cand.append(Vector2i(3, y))
	# детерминированное «перемешивание», чтобы кусты всегда стояли на тех же местах
	cand.sort_custom(func(a, b): return (a.x * 7919 + a.y * 104729) % 997 < (b.x * 7919 + b.y * 104729) % 997)
	var n := 0
	for c in cand:
		if n >= 12:
			break
		if not objects.has(c) and not reserved.has(c) and is_grass(c):
			_bush(c)
			n += 1
	# камни на поле
	n = 0
	while n < 16:
		var c := Vector2i(rng.randi_range(5, 29), rng.randi_range(15, 32))
		if not objects.has(c) and not reserved.has(c) and is_grass(c):
			_rock(c)
			n += 1


func _sprite(tname: String, pos: Vector2, offset: Vector2, hf := 1, vf := 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex[tname]
	s.centered = false
	s.hframes = hf
	s.vframes = vf
	s.offset = offset
	s.position = pos
	world.add_child(s)
	return s

func _building(kind: String, tname: String, tl: Vector2i, wt: int, ht: int, solid_from: int, reserved: Dictionary, hf := 1) -> void:
	var s := _sprite(tname, Vector2(tl.x * T, (tl.y + ht) * T), Vector2(0, -ht * T), hf)
	var o := {"kind": kind, "node": s}
	for y in range(tl.y, tl.y + ht):
		for x in range(tl.x, tl.x + wt):
			var t := Vector2i(x, y)
			reserved[t] = true
			if tiles[idx(t)] == PATH:
				continue
			tiles[idx(t)] = G0
			if y - tl.y >= solid_from:
				solid[idx(t)] = 1
				objects[t] = o

func _tree(t: Vector2i, kind: int) -> void:
	if objects.has(t) or is_water(t) or get_tile(t) == PATH:
		return
	var s := _sprite("trees", Vector2(t.x * T + 8, t.y * T + 15), Vector2(-16, -47), 2)
	s.frame = kind
	objects[t] = {"kind": "tree", "node": s, "birch": kind == 1}
	solid[idx(t)] = 1

func _bush(t: Vector2i) -> void:
	var s := _sprite("bush", Vector2(t.x * T, t.y * T + 16), Vector2(0, -16), 3)
	objects[t] = {"kind": "bush", "node": s, "ripe": true, "days": 0}
	solid[idx(t)] = 1

func _rock(t: Vector2i) -> void:
	var s := _sprite("bush", Vector2(t.x * T, t.y * T + 16), Vector2(0, -16), 3)
	s.frame = 2
	objects[t] = {"kind": "rock", "node": s}
	solid[idx(t)] = 1

func _remove_object(t: Vector2i) -> void:
	var o = objects[t]
	o["node"].queue_free()
	objects.erase(t)
	solid[idx(t)] = 0


# ================================================================== игрок и существа
func _make_player() -> void:
	player = Node2D.new()
	player.position = Vector2(12 * T + 8, 10 * T + 12)
	world.add_child(player)
	psprite = Sprite2D.new()
	psprite.texture = tex["player"]
	psprite.hframes = 4
	psprite.vframes = 4
	psprite.centered = false
	psprite.offset = Vector2(-8, -31)
	player.add_child(psprite)
	tool_icon = Sprite2D.new()
	tool_icon.texture = tex["items"]
	tool_icon.hframes = 8
	tool_icon.vframes = 3
	tool_icon.position = Vector2(0, -40)
	tool_icon.visible = false
	player.add_child(tool_icon)
	bang = Label.new()
	bang.text = "!"
	bang.position = Vector2(-3, -50)
	bang.add_theme_font_size_override("font_size", 11)
	bang.add_theme_color_override("font_color", Color("ffc43a"))
	bang.add_theme_color_override("font_outline_color", Color("5a1408"))
	bang.add_theme_constant_override("outline_size", 3)
	bang.visible = false
	player.add_child(bang)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * T
	cam.limit_bottom = H * T
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)

func _make_creatures() -> void:
	npc = Wanderer.new()
	npc.m = self
	npc.position = Vector2(33 * T, 12 * T + 8)
	npc.area = Rect2(30 * T, 11 * T + 8, 11 * T, 5 * T)
	npc.target = npc.position
	npc.spr = Sprite2D.new()
	npc.spr.texture = tex["olonkhosut"]
	npc.spr.hframes = 4
	npc.spr.vframes = 4
	npc.spr.centered = false
	npc.spr.offset = Vector2(-8, -31)
	npc.add_child(npc.spr)
	world.add_child(npc)
	horse = Wanderer.new()
	horse.m = self
	horse.is_horse = true
	horse.speed = 14.0
	horse.position = Vector2(24 * T, 9 * T)
	horse.area = Rect2(22 * T, 6 * T + 8, 9 * T, 5 * T)
	horse.target = horse.position
	horse.spr = Sprite2D.new()
	horse.spr.texture = tex["horse"]
	horse.spr.hframes = 3
	horse.spr.vframes = 2
	horse.spr.centered = false
	horse.spr.offset = Vector2(-16, -30)
	horse.add_child(horse.spr)
	world.add_child(horse)


# ================================================================== цикл
func _process(delta: float) -> void:
	clock += delta
	var wf := int(clock * 1.6) % 2
	if wf != water_frame:
		water_frame = wf
		ground.queue_redraw()
	kamelyok.frame = int(clock * 7.0) % 3
	if tool_t > 0.0:
		tool_t -= delta
		tool_icon.visible = tool_t > 0.0
	if toast_t > 0.0:
		toast_t -= delta
		toast.modulate.a = clampf(toast_t, 0.0, 1.0)
	match mode:
		"play":
			_move(delta)
			_tick_time(delta)
			npc.tick(delta)
			horse.tick(delta)
		"fish":
			_fish_tick(delta)
			_tick_time(delta)
			horse.tick(delta)
			ground.queue_redraw()
		"menu", "dialog":
			horse.tick(delta)
	_refresh_hud()


func _move(delta: float) -> void:
	var v := Input.get_vector("left", "right", "up", "down")
	if v == Vector2.ZERO:
		psprite.frame = pdir * 4
		pwalk = 0.0
		return
	if absf(v.x) > absf(v.y):
		pdir = 2 if v.x > 0 else 1
	else:
		pdir = 0 if v.y > 0 else 3
	var sp := 74.0 * delta
	var nx := player.position + Vector2(v.x * sp, 0)
	if _free(nx):
		player.position = nx
	var ny := player.position + Vector2(0, v.y * sp)
	if _free(ny):
		player.position = ny
	pwalk += delta
	psprite.frame = pdir * 4 + int(pwalk * 8.0) % 4

func _free(p: Vector2) -> bool:
	for c in [Vector2(-5, -5), Vector2(4, -5), Vector2(-5, 0), Vector2(4, 0)]:
		if is_solid(tile_at(p + c)):
			return false
	for e in [npc, horse]:
		var r := 12.0 if e == horse else 8.0
		if p.distance_to(e.position) < r and p.distance_to(e.position) < player.position.distance_to(e.position):
			return false
	return true

func _tick_time(delta: float) -> void:
	minutes += delta / SEC_PER_MIN
	var c := Color.WHITE
	if minutes > 1080.0:
		c = Color.WHITE.lerp(Color(0.42, 0.45, 0.75), clampf((minutes - 1080.0) / 240.0, 0.0, 1.0))
	night.color = c
	if minutes >= DAY_END:
		toast_msg("Ты уснул прямо на аласе...")
		_sleep(true)


# ================================================================== ввод
func _unhandled_input(e) -> void:
	if e.is_action_pressed("help"):
		help.visible = not help.visible
	match mode:
		"dialog":
			if e.is_action_pressed("use") or e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
				_dialog_next()
				get_viewport().set_input_as_handled()
		"menu":
			if e.is_action_pressed("ui_cancel") or e.is_action_pressed("interact"):
				_close_menu()
		"fish":
			if e.is_action_pressed("use") or e.is_action_pressed("interact"):
				_fish_reel()
		"play":
			if e.is_action_pressed("use"):
				_use()
			elif e.is_action_pressed("interact"):
				_interact()
			elif e.is_action_pressed("eat"):
				_eat()
			elif e is InputEventKey and e.pressed and not e.echo:
				var k: int = e.physical_keycode
				if k >= KEY_1 and k <= KEY_9:
					sel = k - KEY_1
				elif k == KEY_0:
					sel = 9
				elif k == KEY_MINUS:
					sel = 10
				elif k == KEY_EQUAL:
					sel = 11
				_refresh_ui()
			elif e is InputEventMouseButton and e.pressed:
				if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					sel = (sel + 1) % 12
					_refresh_ui()
				elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
					sel = (sel + 11) % 12
					_refresh_ui()


func feet_tile() -> Vector2i:
	return tile_at(player.position + Vector2(0, -2))

func facing_tile() -> Vector2i:
	return feet_tile() + DIRS[pdir]

func _near(e: Node2D, r: float) -> bool:
	var front := player.position + Vector2(DIRS[pdir]) * 12.0
	return front.distance_to(e.position) < r


func _use() -> void:
	var it = inv[sel]
	var ft := facing_tile()
	if crops.has(ft) and _ripe(ft):
		_harvest(ft)
		return
	if it == null:
		return
	var info: Dictionary = Data.ITEMS[it["id"]]
	match info["type"]:
		"tool":
			_use_tool(it["id"], ft)
		"seed":
			_plant(info["crop"], ft)
		_:
			if info.has("energy"):
				_eat()

func _show_tool(id: String) -> void:
	tool_icon.frame = Data.ITEMS[id]["frame"]
	tool_t = 0.3
	tool_icon.visible = true

func _spend(e: float) -> bool:
	if energy < e:
		toast_msg("Нет сил. Поешь или ляг спать.")
		return false
	energy -= e
	return true

func _use_tool(id: String, ft: Vector2i) -> void:
	match id:
		"hoe":
			if objects.has(ft) and objects[ft]["kind"] == "rock":
				if _spend(4):
					_show_tool(id)
					_remove_object(ft)
					removed_rocks.append([ft.x, ft.y])
					toast_msg("Камень разбит.")
			elif is_grass(ft) and not objects.has(ft) and not crops.has(ft) and _spend(2):
				_show_tool(id)
				tiles[idx(ft)] = SOIL
				ground.queue_redraw()
				if randf() < 0.03:
					add_item("mammoth", 1)
					toast_msg("Из мерзлоты показался бивень мамонта!")
		"can":
			if get_tile(ft) == SOIL and _spend(1):
				_show_tool(id)
				tiles[idx(ft)] = WET
				ground.queue_redraw()
			elif is_water(ft):
				_show_tool(id)
				toast_msg("Лейка полна.")
		"rod":
			if is_water(ft):
				if _spend(3):
					mode = "fish"
					fishing = {"pos": Vector2(ft * T) + Vector2(8, 10), "wait": randf_range(1.5, 5.0), "bite": false, "bite_t": 0.0}
			else:
				toast_msg("Встань лицом к воде.")

func _plant(crop: String, ft: Vector2i) -> void:
	var tl := get_tile(ft)
	if (tl == SOIL or tl == WET) and not crops.has(ft):
		_add_crop(ft, crop, 0)
		take_slot(sel, 1)

func _add_crop(t: Vector2i, type: String, age: int) -> void:
	var s := _sprite("crops", Vector2(t.x * T, t.y * T + 16), Vector2(0, -31), 5, 3)
	crops[t] = {"type": type, "age": age, "node": s}
	_crop_frame(t)

func _crop_frame(t: Vector2i) -> void:
	var c = crops[t]
	var info: Dictionary = Data.CROPS[c["type"]]
	var st := 0
	if c["age"] >= info["days"]:
		st = 4
	elif c["age"] > 0:
		st = clampi(1 + c["age"] * 3 / info["days"], 1, 3)
	c["node"].frame = info["row"] * 5 + st

func _ripe(t: Vector2i) -> bool:
	return crops[t]["age"] >= Data.CROPS[crops[t]["type"]]["days"]

func _harvest(t: Vector2i) -> void:
	var info: Dictionary = Data.CROPS[crops[t]["type"]]
	if add_item(info["item"], info["yield"]):
		crops[t]["node"].queue_free()
		crops.erase(t)
		toast_msg("Собрано: %s ×%d" % [Data.ITEMS[info["item"]]["name"], info["yield"]])

func _eat() -> void:
	var it = inv[sel]
	if it == null or not Data.ITEMS[it["id"]].has("energy"):
		return
	var info: Dictionary = Data.ITEMS[it["id"]]
	if energy >= MAX_E:
		toast_msg("Ты сыт.")
		return
	energy = minf(MAX_E, energy + info["energy"])
	take_slot(sel, 1)
	toast_msg("%s: +%d энергии" % [info["name"], info["energy"]])


func _interact() -> void:
	if _near(npc, 14.0):
		_talk()
		return
	if _near(horse, 18.0):
		_pet_horse()
		return
	var ft := facing_tile()
	if crops.has(ft):
		if _ripe(ft):
			_harvest(ft)
		else:
			var c = crops[ft]
			toast_msg("%s: %d из %d дней%s" % [Data.ITEMS[Data.CROPS[c["type"]]["item"]]["name"], c["age"],
				Data.CROPS[c["type"]]["days"], "" if get_tile(ft) == WET else " · нужно полить"])
		return
	if not objects.has(ft):
		return
	var o = objects[ft]
	match o["kind"]:
		"door":
			show_menu("Лечь спать? (сохранение)", [["Да, до утра", _sleep.bind(false)], ["Нет", null]])
		"balagan":
			say("", null, ["Балаган: дерновая крыша, стены из жердей, обмазанные глиной. Окна — из льдин. Дверь посередине."])
		"kamelyok":
			_open_cooking()
		"ampaar":
			_open_ampaar()
		"serge":
			say("", null, ["Сэргэ — резная коновязь. Говорят, у кого крепко стоит сэргэ, у того крепок и род."])
		"urasa":
			say("", null, ["Ураса олонхосута. Берестяной конус с орнаментными поясами, вход прикрыт меховым пологом."])
		"tree":
			say("", null, ["Берёза. Её береста идёт на урасу и туеса." if o["birch"] else "Лиственница — главное дерево якутской тайги."])
		"rock":
			toast_msg("Камень. Разбей его мотыгой.")
		"bush":
			if o["ripe"]:
				var n := randi_range(1, 3)
				if add_item("brusnika", n):
					o["ripe"] = false
					o["days"] = 0
					o["node"].frame = 1
					toast_msg("Брусника ×%d" % n)
			else:
				toast_msg("Ягоды ещё не поспели.")


# ================================================================== люди и кони
func hearts() -> int:
	return npc_f / 3

func _talk() -> void:
	npc.face(player.position)
	var tier := 0 if hearts() < 3 else (1 if hearts() < 7 else 2)
	var pool: Array = Data.NPC_LINES[tier]
	var line: String = pool[randi() % pool.size()]
	if not npc_talked:
		npc_talked = true
		npc_f += 1
	say("Бэргэн, олонхосут · дружба %d/10" % hearts(), tex["portrait_olonkhosut"], [line], _npc_menu)

func _npc_menu() -> void:
	var opts := [["Купить товары", _open_shop]]
	var it = inv[sel]
	if it != null and Data.ITEMS[it["id"]]["type"] != "tool":
		opts.append(["Подарить: " + Data.ITEMS[it["id"]]["name"], _gift, not npc_gifted])
	opts.append(["Попрощаться", null])
	show_menu("Бэргэн", opts)

func _gift() -> void:
	var it = inv[sel]
	if it == null:
		return
	var id: String = it["id"]
	var v: int = Data.GIFTS.get(id, 0)
	take_slot(sel, 1)
	npc_gifted = true
	npc_f = clampi(npc_f + v * 2, 0, 30)
	var line := "Спасибо, добрый человек."
	if v >= 3:
		line = "Вот это подарок! Сердце сказителя поёт!"
	elif v >= 1:
		line = "Благодарю. Это мне по душе."
	elif v < 0:
		line = "Льдина?.. Ну... спасибо, наверное."
	say("Бэргэн, олонхосут", tex["portrait_olonkhosut"], [line])

func _open_shop() -> void:
	var opts := []
	for s in Data.SHOP:
		var id: String = s[0]
		var price: int = s[1]
		opts.append(["%s — %d" % [Data.ITEMS[id]["name"], price], _buy.bind(id, price), money >= price])
	opts.append(["Уйти", null])
	show_menu("Товары Бэргэна (деньги: %d)" % money, opts)

func _buy(id: String, price: int) -> void:
	if money >= price and add_item(id, 1):
		money -= price
		toast_msg("Куплено: " + Data.ITEMS[id]["name"])
	_open_shop()

func _pet_horse() -> void:
	horse.face(player.position)
	if horse_pet:
		toast_msg("Конь довольно фыркает.")
		return
	horse_pet = true
	horse_f = mini(horse_f + 1, 10)
	if add_item("kumys", 1):
		toast_msg("Ты погладил коня. Кобыла дала кумыс!")


# ================================================================== амбар и камелёк
func _open_ampaar() -> void:
	var it = inv[sel]
	if it == null or Data.ITEMS[it["id"]]["price"] <= 0:
		say("", null, ["Амбар для продажи. Выбери в панели предмет, который хочешь продать, и подойди снова."])
		return
	var info: Dictionary = Data.ITEMS[it["id"]]
	var n: int = it["n"]
	show_menu("Амбар", [
		["Продать 1 шт. — %d" % info["price"], _sell.bind(1)],
		["Продать всё (%d) — %d" % [n, info["price"] * n], _sell.bind(n)],
		["Отмена", null]])

func _sell(n: int) -> void:
	var it = inv[sel]
	if it == null:
		return
	n = mini(n, it["n"])
	var gain: int = Data.ITEMS[it["id"]]["price"] * n
	money += gain
	toast_msg("Продано %s ×%d: +%d" % [Data.ITEMS[it["id"]]["name"], n, gain])
	take_slot(sel, n)

func _open_cooking() -> void:
	var opts := []
	for r in Data.RECIPES:
		var parts := PackedStringArray()
		var ok := true
		for k in r["need"]:
			parts.append("%s %d/%d" % [Data.ITEMS[k]["name"], count(k), r["need"][k]])
			if count(k) < r["need"][k]:
				ok = false
		opts.append(["%s  (%s)" % [Data.ITEMS[r["out"]]["name"], ", ".join(parts)], _cook.bind(r), ok])
	opts.append(["Отойти от огня", null])
	show_menu("Камелёк — что приготовить?", opts)

func _cook(r: Dictionary) -> void:
	for k in r["need"]:
		take_id(k, r["need"][k])
	add_item(r["out"], 1)
	toast_msg("Приготовлено: " + Data.ITEMS[r["out"]]["name"])
	_open_cooking()


# ================================================================== рыбалка
func _fish_tick(delta: float) -> void:
	psprite.frame = pdir * 4
	if not fishing["bite"]:
		fishing["wait"] -= delta
		if fishing["wait"] <= 0.0:
			fishing["bite"] = true
			fishing["bite_t"] = 0.9
			bang.visible = true
	else:
		fishing["bite_t"] -= delta
		if fishing["bite_t"] <= 0.0:
			bang.visible = false
			mode = "play"
			ground.queue_redraw()
			toast_msg("Рыба сорвалась...")

func _fish_reel() -> void:
	bang.visible = false
	mode = "play"
	ground.queue_redraw()
	if not fishing["bite"]:
		toast_msg("Пустой крючок. Жди поклёвку — «!»")
		return
	var r := randf()
	var id := "karas" if r < 0.6 else ("chir" if r < 0.92 else "ice")
	if add_item(id, 1):
		toast_msg("Поймано: " + Data.ITEMS[id]["name"] + "!")


# ================================================================== сон и новый день
func _sleep(passed_out := false) -> void:
	mode = "sleep"
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.8)
	tw.tween_callback(_new_day.bind(passed_out))
	tw.tween_interval(0.4)
	tw.tween_property(fade, "color:a", 0.0, 0.8)
	tw.tween_callback(_wake)

func _wake() -> void:
	mode = "play"
	toast_msg("День %d. Доброе утро!" % day)

func _new_day(passed_out: bool) -> void:
	day += 1
	minutes = DAY_START
	night.color = Color.WHITE
	energy = MAX_E * (0.5 if passed_out else 1.0)
	if passed_out:
		money = int(money * 0.9)
	for t in crops:
		if get_tile(t) == WET:
			crops[t]["age"] += 1
			_crop_frame(t)
	for i in tiles.size():
		if tiles[i] == WET:
			tiles[i] = SOIL
	for t in objects:
		var o = objects[t]
		if o["kind"] == "bush" and not o["ripe"]:
			o["days"] += 1
			if o["days"] >= 3:
				o["ripe"] = true
				o["node"].frame = 0
	npc_talked = false
	npc_gifted = false
	horse_pet = false
	player.position = Vector2(12 * T + 8, 10 * T + 12)
	pdir = 0
	ground.queue_redraw()
	_save()
	_refresh_ui()


# ================================================================== инвентарь
func add_item(id: String, n: int) -> bool:
	for i in 12:
		if inv[i] != null and inv[i]["id"] == id and Data.ITEMS[id]["type"] != "tool":
			inv[i]["n"] += n
			_refresh_ui()
			return true
	for i in 12:
		if inv[i] == null:
			inv[i] = {"id": id, "n": n}
			_refresh_ui()
			return true
	toast_msg("Нет места в сумке!")
	return false

func take_slot(i: int, n: int) -> void:
	if inv[i] == null:
		return
	inv[i]["n"] -= n
	if inv[i]["n"] <= 0:
		inv[i] = null
	_refresh_ui()

func count(id: String) -> int:
	var c := 0
	for s in inv:
		if s != null and s["id"] == id:
			c += s["n"]
	return c

func take_id(id: String, n: int) -> void:
	for i in 12:
		if n <= 0:
			break
		if inv[i] != null and inv[i]["id"] == id:
			var k := mini(n, inv[i]["n"])
			take_slot(i, k)
			n -= k


# ================================================================== сохранение
func _save() -> void:
	var cr := {}
	for t in crops:
		cr["%d,%d" % [t.x, t.y]] = [crops[t]["type"], crops[t]["age"]]
	var bushes := {}
	for t in objects:
		if objects[t]["kind"] == "bush":
			bushes["%d,%d" % [t.x, t.y]] = [objects[t]["ripe"], objects[t]["days"]]
	var data := {"day": day, "money": money, "inv": inv, "tiles": Array(tiles), "crops": cr,
		"bushes": bushes, "rocks": removed_rocks, "npc_f": npc_f, "horse_f": horse_f}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	day = int(d["day"])
	money = int(d["money"])
	npc_f = int(d.get("npc_f", 0))
	horse_f = int(d.get("horse_f", 0))
	for i in 12:
		var s = d["inv"][i]
		inv[i] = null if s == null else {"id": s["id"], "n": int(s["n"])}
	var tl: Array = d["tiles"]
	for i in tl.size():
		tiles[i] = int(tl[i])
	for r in d["rocks"]:
		var t := Vector2i(int(r[0]), int(r[1]))
		removed_rocks.append([t.x, t.y])
		if objects.has(t):
			_remove_object(t)
	for k in d["crops"]:
		var p: PackedStringArray = k.split(",")
		_add_crop(Vector2i(int(p[0]), int(p[1])), d["crops"][k][0], int(d["crops"][k][1]))
	for k in d["bushes"]:
		var p: PackedStringArray = k.split(",")
		var t := Vector2i(int(p[0]), int(p[1]))
		if objects.has(t):
			objects[t]["ripe"] = bool(d["bushes"][k][0])
			objects[t]["days"] = int(d["bushes"][k][1])
			objects[t]["node"].frame = 0 if objects[t]["ripe"] else 1
	toast_msg("Загружено сохранение: день %d" % day)
	return true


# ================================================================== интерфейс
func _style(bg: Color, border: Color, bw := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb

func _label(parent: Node, size := 8) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func icon(id: String) -> AtlasTexture:
	if not icons.has(id):
		var a := AtlasTexture.new()
		a.atlas = tex["items"]
		var f: int = Data.ITEMS[id]["frame"]
		a.region = Rect2((f % 8) * 16, (f / 8) * 16, 16, 16)
		icons[id] = a
	return icons[id]

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = 8
	th.set_color("font_color", "Label", Color("f6f0e4"))
	th.set_color("font_shadow_color", "Label", Color(0.15, 0.07, 0.06, 0.8))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 1)
	th.set_stylebox("normal", "Button", _style(Color("995a30"), Color("3b1d1a")))
	th.set_stylebox("hover", "Button", _style(Color("bf7e45"), Color("3b1d1a")))
	th.set_stylebox("pressed", "Button", _style(Color("6b3824"), Color("3b1d1a")))
	th.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), Color("fae694")))
	th.set_stylebox("disabled", "Button", _style(Color("6e5c62"), Color("3b1d1a")))
	th.set_color("font_color", "Button", Color("fff4e0"))
	th.set_color("font_disabled_color", "Button", Color("b9a99c"))
	th.set_font_size("font_size", "Button", 8)
	ui.theme = th
	layer.add_child(ui)
	st_slot = _style(Color("e0a964"), Color("6b3824"))
	st_sel = _style(Color("fae694"), Color("c42c34"), 2)

	# часы, деньги
	var hp := PanelContainer.new()
	hp.add_theme_stylebox_override("panel", _style(Color(0.24, 0.12, 0.1, 0.85), Color("e0a964")))
	hp.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hp.offset_top = 4
	hp.offset_left = -96
	hp.offset_right = -4
	ui.add_child(hp)
	hud = _label(hp)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# энергия
	ebar = ProgressBar.new()
	ebar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	ebar.show_percentage = false
	ebar.max_value = MAX_E
	ebar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ebar.offset_left = -14
	ebar.offset_right = -6
	ebar.offset_top = -70
	ebar.offset_bottom = -6
	ebar.add_theme_stylebox_override("background", _style(Color("3b1d1a"), Color("e0a964")))
	var fill := _style(Color("64aa40"), Color("1f5638"))
	fill.content_margin_left = 0
	ebar.add_theme_stylebox_override("fill", fill)
	ui.add_child(ebar)
	var el := _label(ui, 7)
	el.text = "Э"
	el.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	el.offset_left = -13
	el.offset_top = -82

	# панель предметов
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 1)
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -3
	ui.add_child(bar)
	for i in 12:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(18, 18)
		p.gui_input.connect(_slot_click.bind(i))
		var tr := TextureRect.new()
		tr.position = Vector2(1, 1)
		tr.size = Vector2(16, 16)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tr)
		var cl := _label(p, 6)
		cl.position = Vector2(8, 8)
		cl.size = Vector2(9, 9)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bar.add_child(p)
		slots.append([p, tr, cl])
	item_label = _label(ui)
	item_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	item_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	item_label.offset_top = -34
	item_label.offset_bottom = -23
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	toast = _label(ui)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.offset_top = 6
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", Color("fae694"))

	help = _label(ui, 7)
	help.position = Vector2(6, 6)
	help.text = "WASD / стрелки — ходить\nПробел, C, ЛКМ — инструмент\nE, X, ПКМ — говорить, собрать, открыть\nF — съесть предмет из руки\n1–0, -, = или колесо — слот\nДверь балагана — сон и сохранение\nH — скрыть подсказку"
	help.visible = false

	# диалог
	dlg = Panel.new()
	dlg.add_theme_stylebox_override("panel", _style(Color("f6f0e4"), Color("6b3824"), 2))
	dlg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg.offset_left = 20
	dlg.offset_right = -20
	dlg.offset_top = -96
	dlg.offset_bottom = -26
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.visible = false
	ui.add_child(dlg)
	dlg_port = TextureRect.new()
	dlg_port.position = Vector2(4, 3)
	dlg_port.size = Vector2(64, 64)
	dlg_port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dlg_port.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dlg.add_child(dlg_port)
	dlg_name = _label(dlg)
	dlg_name.add_theme_color_override("font_color", Color("c42c34"))
	dlg_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	dlg_text = _label(dlg)
	dlg_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg_text.offset_right = -8
	dlg_text.offset_bottom = -12
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.add_theme_color_override("font_color", Color("3b1d1a"))
	dlg_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	var nx := _label(dlg, 6)
	nx.text = ">> E / Пробел"
	nx.add_theme_color_override("font_color", Color("995a30"))
	nx.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	nx.offset_left = -50
	nx.offset_top = -11

	# меню
	menu = PanelContainer.new()
	menu.add_theme_stylebox_override("panel", _style(Color("6b3824"), Color("e0a964"), 2))
	menu.visible = false
	ui.add_child(menu)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	menu.add_child(vb)
	menu_title = _label(vb)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_color_override("font_color", Color("fae694"))
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 2)
	vb.add_child(menu_box)

	fade = ColorRect.new()
	fade.color = Color(0.05, 0.03, 0.08, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)


func _slot_click(e, i: int) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		sel = i
		_refresh_ui()

func _refresh_hud() -> void:
	var m := int(minutes)
	hud.text = "День %d · лето\n%02d:%02d\nДеньги: %d" % [day, (m / 60) % 24, (m % 60) / 10 * 10, money]
	ebar.value = energy

func _refresh_ui() -> void:
	if slots.is_empty():
		return
	for i in 12:
		var s: Array = slots[i]
		s[0].add_theme_stylebox_override("panel", st_sel if i == sel else st_slot)
		var it = inv[i]
		s[1].texture = null if it == null else icon(it["id"])
		s[2].text = "" if it == null or it["n"] <= 1 else str(it["n"])
	var cur = inv[sel]
	item_label.text = "" if cur == null else Data.ITEMS[cur["id"]]["name"] + " — " + Data.ITEMS[cur["id"]]["desc"]

func toast_msg(s: String) -> void:
	toast.text = s
	toast_t = 2.5
	toast.modulate.a = 1.0


func say(who: String, portrait: Texture2D, lines: Array, done := Callable()) -> void:
	mode = "dialog"
	dlg_lines = lines.duplicate()
	dlg_done = done
	dlg_name.text = who
	dlg_port.texture = portrait
	dlg_port.visible = portrait != null
	var x := 74 if portrait != null else 8
	dlg_name.position = Vector2(x, 3)
	dlg_text.offset_left = x
	dlg_text.offset_top = 14 if who != "" else 6
	dlg.visible = true
	_dialog_next()

func _dialog_next() -> void:
	if dlg_lines.is_empty():
		dlg.visible = false
		mode = "play"
		if dlg_done.is_valid():
			var c := dlg_done
			dlg_done = Callable()
			c.call()
		return
	dlg_text.text = dlg_lines.pop_front()


func show_menu(title: String, opts: Array) -> void:
	mode = "menu"
	menu_title.text = title
	for c in menu_box.get_children():
		menu_box.remove_child(c)
		c.queue_free()
	var first: Button = null
	for o in opts:
		var b := Button.new()
		b.text = o[0]
		b.disabled = o.size() > 2 and not o[2]
		b.pressed.connect(_menu_pick.bind(o[1]))
		menu_box.add_child(b)
		if first == null and not b.disabled:
			first = b
	menu.visible = true
	_center_menu()
	_center_menu.call_deferred()
	if first:
		first.grab_focus()

func _center_menu() -> void:
	menu.reset_size()
	menu.position = ((ui.size - menu.size) / 2.0).round()

func _menu_pick(cb) -> void:
	_close_menu()
	if cb is Callable:
		cb.call()

func _close_menu() -> void:
	menu.visible = false
	if mode == "menu":
		mode = "play"
