extends Node2D
## Игровая сцена: загрузка локаций, переходы, взаимодействия, сон, меню и интерфейс.

const Maps = preload("res://scripts/maps.gd")
const LocationScript = preload("res://scripts/location.gd")
const PlayerScene = preload("res://scenes/player.tscn")
const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const DialogBox = preload("res://scripts/ui/dialog_box.gd")
const Tooltip = preload("res://scripts/ui/tooltip.gd")
const GameMenu = preload("res://scripts/ui/game_menu.gd")
const ShopUI = preload("res://scripts/ui/shop_ui.gd")
const TransferUI = preload("res://scripts/ui/transfer_ui.gd")
const BundleUI = preload("res://scripts/ui/bundle_ui.gd")
const FishingUI = preload("res://scripts/ui/fishing_ui.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const DaySummary = preload("res://scripts/ui/day_summary.gd")

var world: Node2D
var loc
var player
var ui_root: Control
var hud
var dialog
var tooltip
var fade: ColorRect
var cursor: Node2D
var modal = null
var locked := false
var sleeping := false


func _ready() -> void:
	Game.scene = self
	Game.reset_pause()
	world = Node2D.new()
	add_child(world)
	cursor = _Cursor.new()
	cursor.game = self
	cursor.z_index = 20
	player = PlayerScene.instantiate()
	player.game = self
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UiKit.theme()
	layer.add_child(ui_root)
	hud = Hud.new()
	hud.game = self
	ui_root.add_child(hud)
	dialog = DialogBox.new()
	dialog.game = self
	ui_root.add_child(dialog)
	tooltip = Tooltip.new()
	ui_root.add_child(tooltip)
	fade = ColorRect.new()
	fade.color = Color(0.05, 0.03, 0.08, 1.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade)
	GameClock.time_up.connect(_on_time_up)
	_load_location("house", Vector2i(8, 4), 0)
	GameClock.running = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	if not Game.flags.get("intro", false):
		Game.flags["intro"] = true
		tw.tween_callback(_intro)
	else:
		tw.tween_callback(func(): hud.show_banner("%s, день %d" % [Db.SEASONS[GameClock.season], GameClock.day]))


func _exit_tree() -> void:
	if Game.scene == self:
		Game.scene = null


func _intro() -> void:
	dialog.say("Письмо от дяди", null, [
		"«Дорогой мой! Если ты читаешь это письмо, значит, ферма в Рассветной долине теперь твоя.»",
		"«Земля заросла, но она добрая: вспаши её мотыгой, посади семена и поливай каждый день.»",
		"«Урожай клади в ящик отгрузки у дома — утром за него заплатят. Семена продаёт Тимофей в деревне, на востоке.»",
		"«Старая мельница в деревне совсем развалилась. Помоги Марфе её восстановить — это сердце долины.»",
		"«Управление: WASD — ходить, ЛКМ/Пробел — инструмент, ПКМ/E — действие, Tab — рюкзак и крафт. Удачи!»"])


# ================================================================== локации
func _load_location(name: String, spawn: Vector2i, face: int) -> void:
	if loc:
		if player.get_parent():
			player.get_parent().remove_child(player)
		if cursor.get_parent():
			cursor.get_parent().remove_child(cursor)
		world.remove_child(loc)
		loc.queue_free()
	loc = LocationScript.new()
	world.add_child(loc)
	loc.build(name)
	loc.entities.add_child(player)
	loc.add_child(cursor)
	player.loc = loc
	player.position = Vector2(spawn.x * 16 + 8, spawn.y * 16 + 14)
	player.set_dir(face)
	player.velocity = Vector2.ZERO
	_set_camera_limits()
	player.camera.reset_smoothing()
	Game.current_loc = name
	if name.begins_with("mine_"):
		Game.mine_max = maxi(Game.mine_max, int(name.substr(5)))
	Audio.play_music(Maps.music_for(name))
	hud.show_banner(Maps.display_name(name))


func _set_camera_limits() -> void:
	var cam: Camera2D = player.camera
	var vp := Vector2(480, 270)
	var sz := Vector2(loc.w * 16, loc.h * 16)
	var ox := maxf(0.0, (vp.x - sz.x) / 2.0)
	var oy := maxf(0.0, (vp.y - sz.y) / 2.0)
	cam.limit_left = int(-ox)
	cam.limit_right = int(sz.x + ox)
	cam.limit_top = int(-oy)
	cam.limit_bottom = int(sz.y + oy)


func change_location(name: String, spawn: Vector2i, face: int) -> void:
	if locked:
		return
	locked = true
	fade.move_to_front()
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_load_location.bind(name, spawn, face))
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func(): locked = false)


func check_exit() -> void:
	var e = loc.exit_at(player.feet_tile())
	if e != null:
		change_location(e["to"], e["spawn"], e["face"])


# ================================================================== действия
func handle_action(action: String, t: Vector2i) -> void:
	match action:
		"enter_house":
			Audio.sfx("door")
			change_location("house", Vector2i(5, 7), 3)
		"enter_mine":
			Audio.sfx("door")
			change_location("mine", Vector2i(7, 10), 3)
		"ship":
			var m := TransferUI.new()
			m.mode = "ship"
			open_modal(m)
		"chest":
			var o = loc.obj(t)
			if o != null:
				var m := TransferUI.new()
				m.mode = "chest"
				m.chest = o
				open_modal(m)
		"shop":
			var h := GameClock.hour()
			if h >= 9 and h < 17:
				open_modal(ShopUI.new())
			else:
				dialog.say("", null, ["На двери табличка: «Лавка открыта с 9:00 до 17:00»."])
		"mill":
			if Game.mill_fixed:
				dialog.say("Марфа", Db.tex("portrait_marfa"), ["Слышишь, как поскрипывают жернова? Это всё благодаря тебе!"])
			else:
				open_modal(BundleUI.new())
		"school":
			dialog.say("", null, ["Школа. Сквозь окно видны парты и доска с надписью «Растения долины»."])
		"house_timofey", "house_ilya":
			dialog.say("", null, ["Дверь заперта. Хозяев нет дома."])
		"well":
			Game.refill_can()
			Audio.sfx("water")
			dialog.say("", null, ["Колодец. Ты наполнил лейку свежей водой."])
		"sleep":
			dialog.ask("", null, "Лечь спать? Игра будет сохранена.", ["Лечь спать", "Не сейчас"], func(i: int):
				if i == 0:
					start_sleep(false))
		"stove":
			dialog.say("", null, ["Старая плита. Готовить еду можно во вкладке «Крафт» (клавиша Tab)."])
		"lift":
			_lift_menu()
		"ladder_down":
			var lvl := 1 if Game.current_loc == "mine" else int(Game.current_loc.substr(5)) + 1
			Audio.sfx("door")
			change_location("mine_%d" % lvl, Vector2i(3, 4), 0)
		"ladder_up":
			change_location("mine", Vector2i(8, 7), 0)


func _lift_menu() -> void:
	if Game.mine_max <= 0:
		dialog.say("", null, ["Подъёмник. Он отвезёт тебя на уровни, до которых ты уже добрался."])
		return
	var levels := [1]
	for l in [5, Game.mine_max]:
		if l <= Game.mine_max and not l in levels:
			levels.append(l)
	var opts := []
	for l in levels:
		opts.append("Уровень %d" % l)
	opts.append("Отмена")
	dialog.ask("", null, "Подъёмник. Куда спуститься?", opts, func(i: int):
		if i < levels.size():
			change_location("mine_%d" % levels[i], Vector2i(3, 4), 0))


func talk_to(npc) -> void:
	npc.face(player.global_position)
	var id := Inventory.current_id()
	var d: Dictionary = Db.npcs[npc.id]
	var portrait := Db.tex("portrait_" + npc.id)
	if id != "" and not Db.is_tool(id) and not Game.gifted_today(npc.id):
		dialog.ask(d["name"], portrait, "Подарить «%s»?" % Db.item_name(id), ["Подарить", "Просто поговорить"], func(i: int):
			if i == 0:
				_give_gift(npc.id, id)
			else:
				_talk(npc.id))
	else:
		_talk(npc.id)


func _talk(id: String) -> void:
	var d: Dictionary = Db.npcs[id]
	dialog.say(d["name"], Db.tex("portrait_" + id), [Game.talk(id)])


func _give_gift(npc: String, id: String) -> void:
	var d: Dictionary = Db.npcs[npc]
	if not Inventory.remove(id, 1):
		return
	var kind := Game.gift(npc, id)
	dialog.say(d["name"], Db.tex("portrait_" + npc), [d["gift"][kind]])
	var txt := {"love": "Это любимый подарок! +45", "neutral": "Подарок принят. +20", "hate": "Не понравилось… −20"}
	Game.notify.emit(UiKit.heart(kind != "hate"), "%s: %s" % [d["name"], txt[kind]])


func ask_eat(id: String) -> void:
	var e: int = int(Db.item(id).get("energy", 0))
	dialog.ask("", null, "Съесть «%s»? (+%d энергии)" % [Db.item_name(id), e], ["Съесть", "Нет"], func(i: int):
		if i == 0 and Inventory.remove(id, 1):
			Game.restore(e)
			Audio.sfx("eat")
			Game.notify.emit(UiKit.bolt(), "+%d энергии" % e))


func pick_fish() -> String:
	var where := "lake" if Game.current_loc == "lake" else "pond"
	var pool := []
	var total := 0
	for f in Db.fish:
		var d: Dictionary = Db.fish[f]
		if where in d["where"] and GameClock.season in d["seasons"].map(func(x): return int(x)):
			pool.append(f)
			total += int(d["weight"])
	if pool.is_empty():
		return "carp"
	var r := randi() % total
	for f in pool:
		r -= int(Db.fish[f]["weight"])
		if r < 0:
			return f
	return pool[0]


func start_fishing(fish_id: String) -> void:
	var m := FishingUI.new()
	m.fish_id = fish_id
	m.finished.connect(func(ok: bool):
		if ok:
			Audio.sfx("catch")
			Game.give(fish_id, 1)
		else:
			Audio.sfx("fail")
			Game.notify.emit(null, "Рыба ушла…"))
	open_modal(m)
	Audio.sfx("splash")


func celebrate_mill() -> void:
	if Game.current_loc == "village":
		loc.refresh_structure("mill")
	Audio.sfx("catch")
	dialog.say("Марфа", Db.tex("portrait_marfa"), [
		"Ты сделал это! Крылья мельницы снова крутятся!",
		"Вся деревня благодарит тебя. Мельница восстановлена — цель года выполнена.",
		"Но долина на этом не заканчивается: продолжай растить урожай и дружить с соседями!"])


# ================================================================== модальные окна
func open_modal(m: Control) -> void:
	if modal != null:
		return
	m.game = self
	ui_root.add_child(m)
	ui_root.move_child(m, fade.get_index())
	tooltip.move_to_front()
	modal = m
	Game.push_pause()
	m.closed.connect(_on_modal_closed)
	Audio.sfx("open")


func _on_modal_closed() -> void:
	modal = null
	Game.pop_pause()
	Audio.sfx("close")


func show_tooltip(title: String, body: String) -> void:
	tooltip.move_to_front()
	tooltip.show_text(title, body)


func hide_tooltip() -> void:
	tooltip.visible = false


func _unhandled_input(e: InputEvent) -> void:
	if locked or dialog.is_open():
		return
	if e.is_action_pressed("pause"):
		if modal != null:
			if modal.closable:
				modal.close()
		else:
			open_modal(PauseMenu.new())
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("inventory"):
		if modal != null and modal.get_script() == GameMenu:
			modal.close()
		elif modal == null:
			open_modal(GameMenu.new())
		get_viewport().set_input_as_handled()
	elif modal == null:
		for i in 10:
			if e.is_action_pressed("slot_%d" % i):
				Inventory.select(i)
				return
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				Inventory.select(Inventory.selected + 1)
			elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
				Inventory.select(Inventory.selected - 1)


# ================================================================== сон
func _on_time_up() -> void:
	if sleeping:
		return
	Game.notify.emit(null, "Полночь… Ты валишься с ног от усталости.")
	start_sleep(true)


func start_sleep(passed_out: bool) -> void:
	if sleeping:
		return
	sleeping = true
	locked = true
	GameClock.running = false
	Audio.sfx("sleep")
	fade.move_to_front()
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 1.0)
	tw.tween_callback(func():
		var report := Game.end_day(passed_out)
		SaveManager.save_game()
		_load_location("house", Vector2i(8, 4), 0)
		var ds := DaySummary.new()
		ds.report = report
		ds.closed.connect(_wake)
		open_modal(ds)
		ds.move_to_front())


func _wake() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.8)
	tw.tween_callback(func():
		locked = false
		sleeping = false
		GameClock.running = true
		hud.show_banner("%s, день %d" % [Db.SEASONS[GameClock.season], GameClock.day]))


func go_to_menu() -> void:
	GameClock.running = false
	Game.scene = null
	Game.reset_pause()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ================================================================== курсор-рамка
class _Cursor extends Node2D:
	var game
	func _process(_d: float) -> void:
		var p = game.player
		visible = p != null and p.loc != null and p.can_act()
		if visible:
			var t: Vector2i = p.target_tile()
			position = Vector2(t.x * 16, t.y * 16)
		queue_redraw()
	func _draw() -> void:
		var c := Color(1, 1, 1, 0.75)
		for corner in [Vector2(0, 0), Vector2(12, 0), Vector2(0, 12), Vector2(12, 12)]:
			var hx := 1.0 if corner.x == 0 else -1.0
			var hy := 1.0 if corner.y == 0 else -1.0
			var base: Vector2 = corner + Vector2(0 if hx > 0 else 3, 0 if hy > 0 else 3)
			draw_line(base, base + Vector2(4 * hx, 0), c, 1.0)
			draw_line(base, base + Vector2(0, 4 * hy), c, 1.0)
